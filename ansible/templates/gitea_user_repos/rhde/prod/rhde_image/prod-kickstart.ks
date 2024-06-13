network --bootproto=dhcp --onboot=true
lang en_US.UTF-8
keyboard us
timezone Etc/UTC
text
zerombr
clearpart --all --initlabel
part /boot/efi --fstype=efi --size=200
part /boot --fstype=xfs --asprimary --size=800
part swap --fstype=swap --recommended
part pv.01 --grow
volgroup rhel pv.01
logvol / --vgname=rhel --fstype=xfs --percent=80 --name=root
reboot
graphical
user --name=ansible --groups=wheel --password='{{  gitea_user_password }}{{ user_number  }}'
rootpw --plaintext --lock '{{  gitea_user_password }}{{ user_number  }}'
services --enabled=ostree-remount
ostreesetup --nogpg --url=http://{{ image_builder_ip | default(ansible_host) }}/{{  gitea_user_name }}{{ user_number  }}/prod/repo --osname=rhel --ref=rhel/9/x86_64/edge

%post --log=/root/kickstart-post.log
set -x


if rpm -q libreswan &> /dev/null; then

conn_name=$(nmcli -t -f NAME con show | head -n 1)
device_name=$(nmcli -t -f GENERAL.DEVICES con show "$conn_name" | head -n 1 | cut -d: -f2)
IP_ADDRESS=$(nmcli -t -f IP4.ADDRESS con show "$conn_name" | head -n 1 | cut -d: -f2 | cut -d/ -f1)
MAC_ADDRESS=$(nmcli -g GENERAL.HWADDR device show "$device_name" | tr -d '\\')
MAC_ADDRESS_FORMAT=$(echo "$MAC_ADDRESS" | tr -d ':')
IP_AAP_PRIVATE={{ aap_ip_private }}
IP_AAP_PUBLIC={{ eda_ip | default(ansible_host) }}

cat > /etc/ipsec.conf <<EOF
config setup
    protostack=netkey

conn %default
    ikelifetime=28800s
    keylife=3600s
    rekeymargin=3m
    keyingtries=1
    keyexchange=ike
    ikev2=yes

conn $MAC_ADDRESS_FORMAT
    encapsulation=yes
    left=%defaultroute
    leftid=$MAC_ADDRESS_FORMAT
    right=${IP_AAP_PUBLIC}
    rightid=${IP_AAP_PRIVATE}
    authby=secret
    auto=start
    dpdaction=restart
    dpddelay=10
    dpdtimeout=30
    ike=3des-sha1,aes-sha1
    esp=aes-sha2_512+sha2_256
    leftsubnets={192.168.0.0/16 172.16.0.0/12}
    rightsubnet=${IP_AAP_PRIVATE}/32
EOF



cat > /etc/ipsec.secrets <<EOF
%any %any : PSK "R3dh4t1!"
EOF

systemctl enable ipsec
systemctl start ipsec 


# Add masquerade rule for the private IP
firewall-offline-cmd  --zone=public --add-masquerade

# Add forwarding rules using direct rules
firewall-offline-cmd   --direct --add-rule ipv4 nat POSTROUTING 0 -s ${IP_AAP_PRIVATE}/32 -d 192.168.0.0/16 -j MASQUERADE
firewall-offline-cmd   --direct --add-rule ipv4 nat POSTROUTING 0 -s ${IP_AAP_PRIVATE}/32 -d 172.16.0.0/12 -j MASQUERADE
firewall-offline-cmd   --direct --add-rule ipv4 filter FORWARD 0 -s ${IP_AAP_PRIVATE}/32 -d 192.168.0.0/16 -j ACCEPT
firewall-offline-cmd   --direct --add-rule ipv4 filter FORWARD 0 -s ${IP_AAP_PRIVATE}/32 -d 172.16.0.0/12 -j ACCEPT

firewall-offline-cmd --runtime-to-permanent

fi





cat > /var/tmp/aap-auto-registration.sh <<EOF
#!/bin/bash
sleep 5
conn_name=\$(nmcli -t -f NAME con show | head -n 1)
device_name=\$(nmcli -t -f GENERAL.DEVICES con show "\$conn_name" | head -n 1 | cut -d: -f2)
IP_ADDRESS=\$(nmcli -t -f IP4.ADDRESS con show "\$conn_name" | head -n 1 | cut -d: -f2 | cut -d/ -f1)
MAC_ADDRESS=\$(nmcli -g GENERAL.HWADDR device show "\$device_name" | tr -d '\\')
MAC_ADDRESS_FORMAT=\$(echo "\$MAC_ADDRESS" | tr -d ':')
USER='{{  gitea_user_name }}{{ user_number }}'


if [ -z "\$IP_ADDRESS" ] || [ -z "\$MAC_ADDRESS" ] || [ -z "\$USER" ]; then
    echo "One or more required variables are empty. Script failed."
    exit 1
fi

JSON="{\
\"ip_address\": \"\$IP_ADDRESS\", \
\"user\": \"\$USER\", \
\"nodename\": \"edge-\$MAC_ADDRESS_FORMAT\", \
\"env\": \"prod\" \
}"

/usr/bin/curl -H 'Content-Type: application/json' --data "\$JSON" http://{{ eda_ip | default(ansible_host) }}:{{ eda_webhook_port | default('5000') }}
EOF

chmod +x  /var/tmp/aap-auto-registration.sh


cat > /etc/systemd/system/aap-auto-registration.service <<EOF
[Unit]
Description=Register to Ansible Automation Platform
After=network.target
After=connect-wifi.service
ConditionPathExists=!/var/tmp/aap-registered

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do /var/tmp/aap-auto-registration.sh && /usr/bin/touch /var/tmp/aap-registered && break; done'

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable aap-auto-registration.service


# Stop config updates with inotify at the start:
touch /root/inotify-wait

%end
