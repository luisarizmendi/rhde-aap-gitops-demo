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
text
user --name=ansible --groups=wheel --password='{{  gitea_user_password }}{{ user_number  }}'
rootpw --plaintext --lock '{{  gitea_user_password }}{{ user_number  }}'
services --enabled=ostree-remount
ostreesetup --nogpg --osname=rhel --remote=edge --url=file:///run/install/repo/ostree/repo --ref=rhel/9/x86_64/edge

%post --log=/root/kickstart-post.log
set -x

echo "Waiting for NetworkManager to be ready..."
while ! systemctl is-active --quiet NetworkManager; do
    sleep 1
done

echo "NetworkManager is running."

device_name=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')
IP_ADDRESS=$(ip -4 addr show dev "$device_name" | awk '/inet / {print $2}' | cut -d/ -f1)
MAC_ADDRESS=$(ip link show dev "$device_name" | awk '/link\/ether/ {print $2}')
MAC_ADDRESS_FORMAT=$(echo "$MAC_ADDRESS" | tr -d ':')

hostnamectl set-hostname --static edge-${MAC_ADDRESS_FORMAT}



cat > /etc/environment <<EOF
git_user={{ gitea_user_name }}{{ user_number }}
env=dev
KIOSK_URL=http://localhost:8000
EOF


######### MICROSHIFT
if rpm -q microshift &> /dev/null; then
# Configure the firewall with the mandatory rules for MicroShift
firewall-offline-cmd  --zone=trusted --add-source=10.42.0.0/16
firewall-offline-cmd  --zone=trusted --add-source=169.254.169.1
firewall-offline-cmd  --zone=public --add-port=80/tcp
firewall-offline-cmd  --zone=public --add-port=443/tcp
firewall-offline-cmd  --zone=public --add-port=6443/tcp

cat > /etc/microshift/config.yaml <<EOF
dns:
  baseDomain: "${IP_ADDRESS}.nip.io"
network:
  clusterNetwork:
    - 10.42.0.0/16
  serviceNetwork:
    - 10.43.0.0/16
  serviceNodePortRange: 30000-32767
node:
  nodeIP: "${IP_ADDRESS}"
apiServer:
  subjectAltNames: 
    - microshift.lablocal
    - microshift.${IP_ADDRESS}.nip.io
    - ${IP_ADDRESS}
debugging:
  logLevel: "Normal"
EOF

fi
#########


%end
