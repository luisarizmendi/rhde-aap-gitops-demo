#!/bin/bash

# variables
TF_SCRIPT="rhel_vm.tf"
TF_VARS="rhel_vm.tfvars"
TF_STATE="terraform.tfstate"
VM_STARTING=1

result=$(grep "rhde_user_name:" ansible/playbooks/main.yml)
if [ -n "$result" ]; then
    ADMIN_USER=$(echo "$result" | awk -F ' ' '{print $2}')
else
    ADMIN_USER="admin"
fi

result=$(grep "rhde_user_password" ansible/playbooks/main.yml)
if [ -n "$result" ]; then
    ADMIN_PASS=$(echo "$result" | awk -F ' ' '{print $2}')
else
    ADMIN_PASS="R3dh4t1!"
fi

# add Terrafor variables
sed -i "s/admin_user\s*=\s*\"[^\"]*\"/admin_user = \"$ADMIN_USER\"/" terraform/rhel_vm.tfvars
sed -i "s/admin_pass\s*=\s*\"[^\"]*\"/admin_pass = \"$ADMIN_PASS\"/" terraform/rhel_vm.tfvars




echo "Introduce your Ansible Vault Secret:"
read -s -p "Enter vault secret: " VAULT_SECRET
echo


############################
####### CREATE THE VM IN AWS
############################



# Run Terraform

cd terraform

terraform init -input=false -backend=false -reconfigure -lock=false -force-copy -var-file="${TF_VARS}"

terraform apply -input=false -auto-approve -var-file="${TF_VARS}"

# Retrieve public IP of the created VM
VM_IP=$(terraform output -state="${TF_STATE}" public_ip  | sed 's/"//g')

echo "Wait until the cloud-init script is done (it could take 5-8 minutes)"

while [ $VM_STARTING -ne 0 ] ; do
    ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${ADMIN_USER}@${VM_IP} 'exit' &>/dev/null
    VM_STARTING=$?
    echo "Waiting to SSH ${VM_IP} with user ${ADMIN_USER}..."
    sleep 60
done

echo "VM is ready."
cd ..

############################
####### INSTALL DEMO
############################


# Upgrade Collection
ansible-galaxy collection install luisarizmendi.rh_edge_mgmt --upgrade

echo "Ready to apply Ansible Collection"

cd ansible


echo "Adding IP to the inventory"
sed -i "s/ansible_host: .*/ansible_host: ${VM_IP}/" inventory

echo "Running Ansible playbooks"

ssh-keyscan -H ${VM_IP} >> ~/.ssh/known_hosts

ansible-playbook -vvi inventory --vault-password-file <(echo "$VAULT_SECRET") playbooks/main.yml


echo ""
echo "###############################################"
echo ""
echo "YOU CAN CONNECT TO THE FOLLOWING SERVICES:"
echo "     + AAP Controller: https://${VM_IP}:8443"
echo "     + AAP Hub: https://${VM_IP}:8444"
echo "     + EDA: https://${VM_IP}:8445"
echo "     + Gitea: http://${VM_IP}:3000"
echo "     + Cockpit: https://${VM_IP}:9090"
echo ""
echo "###############################################"
echo ""
echo ""
