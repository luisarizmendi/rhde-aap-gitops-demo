 #!/bin/bash

set -x 

### Add environment 
echo "" >> /etc/environment
echo "running_env=prod" >> /etc/environment


######### MICROSHIFT
# Configure the firewall with the mandatory rules for MicroShift
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=169.254.169.1
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=6443/tcp

# Reload firewall configuration to apply changes
firewall-cmd --reload



######### required for inotify-gitops
# TODO: I'm not sure why this is not included when installed inotify-pip as part of the requisites of the RPM package
pip install inotify



######### EXAMPLE APP DEPLOYMENT WITH SCRIPT

## Rootless Podman APPs, one Serverless, with podman autoupdate 

# create systemd user directories for rootless services, timers, and sockets
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/default.target.wants
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/sockets.target.wants
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/timers.target.wants
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/multi-user.target.wants

cat > /var/home/{{ rhde_user_name }}/.config/systemd/user/podman-auto-update.service <<EOF
[Unit]
Description=Podman auto-update service
Documentation=man:podman-auto-update(1)

[Service]
ExecStart=/usr/bin/podman auto-update

[Install]
WantedBy=multi-user.target default.target
EOF



# This timer ensures podman auto-update is run every minute
cat > /var/home/{{ rhde_user_name }}/.config/systemd/user/podman-auto-update.timer <<EOF
[Unit]
Description=Podman auto-update timer

[Timer]
# This example runs the podman auto-update daily within a two-hour
# randomized window to reduce system load
#OnCalendar=daily
#Persistent=true
#RandomizedDelaySec=7200

# activate every minute
OnBootSec=30
OnUnitActiveSec=30

[Install]
WantedBy=timers.target
EOF


# define listener
node_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')


##
## Create a service to launch the container workload and restart
## it on failure
##
cat > /var/home/{{ rhde_user_name }}/.config/systemd/user/app-2048.service <<EOF
# app-2048.service
# autogenerated by Podman 4.2.0
# Wed Feb  8 10:13:55 UTC 2023

[Unit]
Description=Podman app-2048.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
        --cidfile=%t/%n.ctr-id \
        --cgroups=no-conmon \
        --rm \
        --sdnotify=conmon \
        -d \
        --replace \
        --name app1 \
        --label io.containers.autoupdate=registry \
        -p ${node_ip}:8081:8081 {{ apps_registry }}/2048:prod
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all
RestartSec=10
StartLimitIntervalSec=120
StartLimitBurst=5

[Install]
WantedBy=default.target
EOF


# enable connection through the firewall
cat << EOF > /etc/systemd/system/expose-app-2048.service
[Unit]
Wants=firewalld.service
After=firewalld.service

[Service]
Type=oneshot
ExecStart=firewall-cmd --permanent --add-port=8081/tcp
ExecStartPost=firewall-cmd --reload

[Install]
WantedBy=multi-user.target default.target
EOF


# enable services
ln -s /var/home/{{ rhde_user_name }}/.config/systemd/user/podman-auto-update.timer /var/home/{{ rhde_user_name }}/.config/systemd/user/timers.target.wants/podman-auto-update.timer

ln -s /var/home/{{ rhde_user_name }}/.config/systemd/user/app-2048.service /var/home/{{ rhde_user_name }}/.config/systemd/user/default.target.wants/app-2048.service
ln -s /var/home/{{ rhde_user_name }}/.config/systemd/user/app-2048.service /var/home/{{ rhde_user_name }}/.config/systemd/user/multi-user.target.wants/app-2048.service

systemctl enable expose-app-2048.service



# fix ownership of user local files and SELinux contexts
chown -R {{ rhde_user_name }}: /var/home/{{ rhde_user_name }}
restorecon -vFr /var/home/{{ rhde_user_name }}


# enable linger so user services run whether user logged in or not
cat << EOF > /etc/systemd/system/enable-linger.service
[Service]
Type=oneshot
ExecStart=loginctl enable-linger {{ rhde_user_name }}

[Install]
WantedBy=multi-user.target default.target
EOF

systemctl enable enable-linger.service





########## PODMAN serverless rootless



##
## Create a scale from zero systemd service for a container web
## server using socket activation
##

# create systemd user directories for rootless services, timers,
# and sockets
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/default.target.wants
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/sockets.target.wants
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/timers.target.wants
mkdir -p /var/home/{{ rhde_user_name }}/.config/systemd/user/multi-user.target.wants



# define listener for socket activation
node_ip=$(ip a show dev $(ip route | grep default | awk '{print $5}') | grep "inet " | awk '{print $2}' | awk -F / '{print $1}')

cat << EOF > /var/home/{{ rhde_user_name }}/.config/systemd/user/container-httpd-proxy.socket
[Socket]
ListenStream=${node_ip}:8080
FreeBind=true

[Install]
WantedBy=sockets.target
EOF



# define proxy service that launches web container and forwards
# requests to it
cat << EOF > /var/home/{{ rhde_user_name }}/.config/systemd/user/container-httpd-proxy.service
[Unit]
Requires=container-httpd.service
After=container-httpd.service
Requires=container-httpd-proxy.socket
After=container-httpd-proxy.socket

[Service]
ExecStart=/usr/lib/systemd/systemd-socket-proxyd --exit-idle-time=10s 127.0.0.1:8080
EOF



##
## Create a service to launch the container workload and restart
## it on failure
##
cat > /var/home/{{ rhde_user_name }}/.config/systemd/user/container-httpd.service <<EOF
# container-httpd.service
# autogenerated by Podman 3.0.2-dev
# Thu May 20 10:16:40 EDT 2021

[Unit]
Description=Podman container-httpd.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers
StopWhenUnneeded=true

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile %t/%n.ctr-id --cgroups=no-conmon --sdnotify=conmon -d --replace --name httpd --label io.containers.autoupdate=registry -p 127.0.0.1:8080:8080 {{ apps_registry }}/simple-http:prod
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target
EOF





cat << EOF > /var/usrlocal/bin/pre-pull-container-image.sh
#!/bin/bash
while true; do
    if curl -s --head http://quay.io | grep "301" > /dev/null; then
        echo "Connectivity to http://quay.io established successfully."
        break
    else
        echo "Unable to connect to http://quay.io. Retrying in 10 seconds..."
        sleep 10
    fi
done
while true
do
  podman pull {{ apps_registry }}/simple-http:prod
  podman image list | grep simple-http
  if [ \$? -eq 0 ]
  then
    break
  fi
done
EOF

chmod +x /var/usrlocal/bin/pre-pull-container-image.sh

# pre-pull the container images at startup to avoid delay in http response
cat > /var/home/{{ rhde_user_name }}/.config/systemd/user/pre-pull-container-image.service <<EOF
[Unit]
Description=Pre-pull container image service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Restart=on-failure
RestartSec=10
TimeoutStartSec=30
ExecStart=/var/usrlocal/bin/pre-pull-container-image.sh

[Install]
WantedBy=multi-user.target default.target
EOF

# enable socket listener
ln -s /var/home/{{ rhde_user_name }}/.config/systemd/user/container-httpd-proxy.socket /var/home/{{ rhde_user_name }}/.config/systemd/user/sockets.target.wants/container-httpd-proxy.socket



# enable pre-pull container image
ln -s /var/home/{{ rhde_user_name }}/.config/systemd/user/pre-pull-container-image.service /var/home/{{ rhde_user_name }}/.config/systemd/user/default.target.wants/pre-pull-container-image.service
ln -s /var/home/{{ rhde_user_name }}/.config/systemd/user/pre-pull-container-image.service /var/home/{{ rhde_user_name }}/.config/systemd/user/multi-user.target.wants/pre-pull-container-image.service




# enable linger so user services run whether user logged in or not
cat << EOF > /etc/systemd/system/enable-linger.service
[Service]
Type=oneshot
ExecStart=loginctl enable-linger {{ rhde_user_name }}

[Install]
WantedBy=multi-user.target default.target
EOF

systemctl enable enable-linger.service

# enable 8080 port through the firewall to expose the application
cat << EOF > /etc/systemd/system/expose-app-serverless-http.service
[Unit]
Wants=firewalld.service
After=firewalld.service

[Service]
Type=oneshot
ExecStart=firewall-cmd --permanent --add-port=8080/tcp
ExecStartPost=firewall-cmd --reload

[Install]
WantedBy=multi-user.target default.target
EOF



systemctl enable expose-app-serverless-http.service


# fix ownership of user local files and SELinux contexts
chown -R {{ rhde_user_name }}: /var/home/{{ rhde_user_name }}
restorecon -vFr /var/home/{{ rhde_user_name }}



### MADE TO SPEED UP THE GREENBOOT AUTOMATIC ROLLBACK USE CASE DEMO

rm -rf /etc/greenboot/check/required.d/*microshift*






