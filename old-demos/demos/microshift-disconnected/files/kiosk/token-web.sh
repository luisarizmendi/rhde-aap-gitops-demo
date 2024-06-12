#!/bin/bash


directory="/var/lib/microshift/resources/kubeadmin"


# Loop until the directory is created
while [ ! -d "$directory" ]; do
    echo "Waiting for $directory to be created..."
    sleep 1  
done

echo "$directory has been created."

while [ -z "$HOST_IP" ]; do
  HOST_IP=$(ip addr show $(ip link | grep DEFAULT | grep -v 'ovn\|br\|cni\|ovs\|lo' | awk '{print $2}' | tr -d ':') | grep -oP 'inet \K[\d.]+')
  sleep 1 
done

export HOST_IP

echo "Detected Host IP: $HOST_IP"

/usr/bin/podman run --security-opt label:disable --env HOST_IP="$HOST_IP" --env PYTHONUNBUFFERED=1 -v /var/tmp/:/var/tmp/ -v /usr/share:/usr/share -v /var/lib/microshift/resources/kubeadmin:/var/lib/microshift/resources/kubeadmin -p 8080:8080 quay.io/luisarizmendi/kiosk-token:latest
