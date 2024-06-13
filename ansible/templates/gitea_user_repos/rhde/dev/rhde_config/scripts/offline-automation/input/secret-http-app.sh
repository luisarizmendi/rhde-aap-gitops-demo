#!/bin/bash

script_dir="$(dirname "$0")"
kubeconfig_file=""

if [ -n "$HOST_IP" ]; then
    echo "Set microshift IP $HOST_IP in container /etc/hosts"
    echo "$HOST_IP microshift"  >> /etc/hosts
fi

# Find all kubeconfig files
kubeconfig_files=$(find /var/lib/microshift/resources/kubeadmin/ -type f -name "kubeconfig")

# Loop through each kubeconfig file
for file in $kubeconfig_files; do
    # Try using the kubeconfig file with "oc" command
    if oc --kubeconfig "$file" get namespace >/dev/null 2>&1; then
        # If successful, store the kubeconfig file path in the variable kubeconfig_file
        kubeconfig_file="$file"
        break
    fi
done

# Output the first kubeconfig file that didn't fail
echo "The kubeconfig file to use is: $kubeconfig_file"




oc --kubeconfig $kubeconfig_file create -f $script_dir/secrets/secret-http-user.yaml

if [ $? -eq 0 ]; then
    echo "secret-http app configuration successful"
else
    echo "secret-http app configuration failed"
    exit 1
fi

oc --kubeconfig $kubeconfig_file create -f $script_dir/secrets/secret-http-password.yaml

if [ $? -eq 0 ]; then
    echo "secret-http app configuration successful"
else
    echo "secret-http app configuration failed"
    exit 1
fi

oc  --kubeconfig $kubeconfig_file  -n secret-http rollout restart deployment secret-http
