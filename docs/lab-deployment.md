

# Preparation - Lab deployment

## Table of Contents
* [Overview of the preparation workflow](#overview-of-the-preparation-workflow)
* [Prepare your environment](#prepare-your-environment)
* [Clone demo repo ](#clone-demo-repo)
* [Terraform prerequisites](#terraform-prerequisites)
* [Edge Management Ansible Collection prerequisites](#edge-management-ansible-collection-prerequisites)
 
  - [Get your Ansible Controller Manifest](#get-your-ansible-controller-manifest)
  - [Get your Red Hat Customer Portal Offline Token](#get-your-red-hat-customer-portal-offline-token)
  - [Get your Pull Secret](#get-your-pull-secret)
  - [Create Vault Secret file](#create-vault-secret-file)
  - [Prepare Ansible inventory and variables](#prepare-ansible-inventory-and-variables)

* [Demo specific prerequisites](#demo-specific-prerequisites)
 
  - [Copy the container images to your Quay account](#copy-the-container-images-to-your-quay-account)

* [Deploy the lab](#deploy-the-lab)
* [Pre-flight checks](#pre-flight-checks)
* [BONUS - If there is not enough time for your demo...](#bonus---if-there-is-not-enough-time-for-your-demo)


## Overview of the preparation workflow

The lab setup is using the [Edge Management Ansible Collection](https://galaxy.ansible.com/ui/repo/published/luisarizmendi/rh_edge_mgmt/) to deploy and configure the environment, so before running the lab deployment you will need to:

1) Prepare your devices/VMs and Laptop
2) Prepare the [Edge Management Ansible Collection](https://galaxy.ansible.com/ui/repo/published/luisarizmendi/rh_edge_mgmt/) prerequisites
3) Prepare the demo specific prerequisites

After the deployment you will have the following running sevices at the Edge Management node that you will use in your demo:

* Ansible Automation Platform Controller: 8080 (HTTP) / 8443 (HTTPS)
* Ansible Automation Platform Event-Driven Ansible Controller:  8082 (HTTP) / 8445 (HTTPS)
* Cockpit: 9090
* Gitea: 3000



## Prepare your environment

In order to deploy/prepare the lab you will only the Edge Management node, the Edge Device won't be used/deployed until you run the demo steps. 

Remember that there are two devices/VMs involved in the demo:

* Edge Management node: I've been able to deploy everything on a VM with 4 vCores and 10GB of memory. Storage will depend on the number of RHDE images that you generate.
The Edge Management node will nee to have a RHEL 9.x installed (this lab has been tested with RHEL 9.3), "minimal install" is enough. You will need to either have a passwordless sudo user in that system or include the sudo password in the Ansible inventory.

  >**Note**
  >
  > Remember that, as part of this demo, a Terraform script is provided to create, install RHEL and perform the required config in that VM. This is not required to deploy the lab but it will simplify it in case you want to directly run this server in AWS.

* Edge Device: This will depend on what you install on top, but for the base deployment you can use 1.5 vCores, 3GB of memory and 50GB disk.


Your laptop will need Ansible installed to run the playbooks contained in the [Edge Management Ansible Collection](https://galaxy.ansible.com/ui/repo/published/luisarizmendi/rh_edge_mgmt/) (see next section). You will also need `git` to clone the repo in the next step and, if using VMs, a virtualization hypervisor (`libvirt` and  Virtual Machine Manager are recommended).




## Clone demo repo

Clone the this repo and move your CLI prompt to the `ansible` directory on the path where the actual demo is located. The demo directory should have a similar organization as the one shown below, you will need to move inside the `ansible` directory which will contain, among others, the inventory, playbooks and vars used for the demo. 

```bash
├── terraform
...
├── ansible
│   ├── files
...
│   ├── inventory
│   ├── playbooks
│   │   ├── main.yml
│   ├── templates
...
│   └── vars
│       └── secrets.yml
├── docs
...
└── README.md

```

When you find a reference to a path during this lab deploymend guide it will consider that you CLi is under the `ansible` directory, so `files` will be in fact `<your cloned demo directory/ansible/files>`.

  >**Note**
  >
  >  You might find that you don't have the vars/secrets.yaml file since that file is created as part of the prerequisites.

## (Optional) Terraform prerequisites

An optional Terraform script is provided to simplify the creation of the Edge Management server in AWS.

First, you will need to [install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) in your laptop.

It also has some prerequisites if you want to use it:

* You will need to Install Terraform in your laptop

* Prepare your AWS credentials in `~/.aws/credentials`

```
[default]
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_secret_access_key
```

  >**Note**
  >
  > If you are a Red Hatter you could order an AWS Blank environment in demo.redhat.com in order to get a valid AWS access key and secret

+ Prepare Terraform variables in file `../terraform/rhel_vm.tfvars`




## Edge Management Ansible Collection prerequisites

You need to install the [Ansible Collection](https://github.com/luisarizmendi/rh_edge_mgmt) on your laptop:

```shell
ansible-galaxy collection install luisarizmendi.rh_edge_mgmt --upgrade
```

  >**Note**
  >
  > Even if you have already installed the collection, it is a good idea to run the command above so the collection playbooks are updated if there has been any change since you downloaded it for the first time.

The Collection [setup_rh_edge_mgmt_node role](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/setup_rh_edge_mgmt_node) and [config_rh_edge_mgmt_node role](https://github.com/luisarizmendi/rh_edge_mgmt/tree/main/roles/config_rh_edge_mgmt_node) have some pre-requisites. This is the summary (all for installing the services):

* Ansible Automation Platform Manifest file
* Red Hat Customer Portal Offline Token
* Red Hat Pull Secret
* Red Hat User and Password



### Get your Ansible Automation Platform Manifest

In order to use Automation controller you need to have a valid subscription via a `manifest.zip` file. To retrieve your manifest.zip file you need to download it from access.redhat.com.

You have the steps in the [Ansible Platform Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4/html/red_hat_ansible_automation_platform_operations_guide/assembly-aap-obtain-manifest-files)

1. Go to [Subscription Allocation](https://access.redhat.com/management/subscription_allocations) and click "New Subscription Allocation"

2. Enter a name for the allocation and select `Satellite 6.8` as "Type".

3. Add the subscription entitlements needed (click the tab and click "Add Subscriptions") where Ansible Automation Platform is available.

4. Go back to "Details" tab and click "Export Manifest" 

Save apart your `manifest.zip` file in `files` directory (a different location can be configured with the `manifest_file` variable).

  >**Note**
  >
  > If you want to check the contents of the ZIP file you will see a `consumer_export.zip` file and a `signature` inside.


If you use the default path you should have the `manifest.zip` file in this path:

```bash
├── terraform
...
├── ansible
│   ├── files
│       └── manifest.zip
│   ├── inventory
│   ├── playbooks
...
│   ├── templates
...
│   └── vars
...
├── docs
...
└── README.md

```



### Get your Red Hat Customer Portal Offline Token

This token is used to authenticate to the customer portal and download software. It is needed to deploy the Ansible Automation Platform server and in order to download the standard RHEL ISO.

It can be generated [here](https://access.redhat.com/management/api).

  >**Note**
  >
  >  Remember that the Offline tokens will expire after 30 days of inactivity. If your offline Token is not valid, you won't be able to download the `aap.tar.gz`. 

Take note of the token, you will use it when creating the Vault Secrets file.


### Get your Red Hat Pull Secret

This Pull Secret will be needed to pull the container images used by `Microshift` from the Red Hat's container repository.  It is needed to deploy the Ansible Automation Platform server.

[Get your pull secret from the Red Hat Console](https://cloud.redhat.com/openshift/install/pull-secret)

Take note of the pull-secret, you will use it when creating the Vault Secrets file.


### Create Vault Secret file

Instead of passing your secrets in plain text, it's better that you create a vault secret file:

```bash
mkdir vars
ansible-vault create vars/secrets.yml
```

  >**Note**
  >
  >  Remember the password that you used to encrypt the file, since it will be needed to access the contents

You will need to include the information that you gather during the previous steps (Offline Token and Pull Secret) and also your Red Hat Account user name and password:

```yaml
pull_secret: '<your pull secret>'
offline_token: '<your offline token>'
red_hat_user: <your RHN user>
red_hat_password: <your RHN password>
```

If you use the default path you should have the `secrets.yml` file in this path:

```bash
├── terraform
...
├── ansible
│   ├── files
...
│   ├── inventory
│   ├── playbooks
...
│   ├── templates
...
│   └── vars
│       └── secrets.yml
├── docs
...
└── README.md

```



### Prepare Ansible inventory and variables

Prepare the Ansible inventory file  


```yaml
---
all:
  hosts:
    edge_management:
      ansible_host: <your edge manager server ip>
      ansible_port: 22
      ansible_user: <sudoer user - default is admin>

```



Also prepare the variables in the `playbooks/main.yml` playbook.


```yaml
---
- name: RHDE and AAP Demo
  hosts:
    - edge_management
  tasks:

    - name: Install management node
      ansible.builtin.include_role:
        name: luisarizmendi.rh_edge_mgmt.setup_rh_edge_mgmt_node
      vars:
        ### COLLECTION VARS
        microshift: true
        microshift_release: 4.15

    - name: Config management node
      ansible.builtin.include_role:
        name: luisarizmendi.rh_edge_mgmt.config_rh_edge_mgmt_node
      vars:
        ### COLLECTION VARS
        image_builder_admin_name: admin
        image_builder_admin_password: R3dh4t1!
        image_builder_custom_rpm_files:  ../templates/custom-rpms
        gitea_admin_repos_template: ../templates/gitea_admin_repos
        gitea_user_repos_template: ../templates/gitea_user_repos
        aap_config_template: ../templates/aap_config.j2
        aap_repo_name: aap
        ### DEMO SPECIFIC VARS
        apps_registry: quay.io/luisarizmendi
```


  >**Note**
  >
  > If you are using the directory tree of this example you could keep the variables that you find there (`gitea_admin_repos_template`, `aap_config_template`, ...), but probably you will need to configure the `image_builder_admin_name` and `image_builder_admin_password` with the user with `sudo` privileges in the RHEL server where you installed the Image Builder. You will also need to include your container repository (see next point).



## Demo specific prerequisites

So far you prepared the prerequisites of any demo/lab deployed with the [Edge Management Ansible Collection](https://galaxy.ansible.com/ui/repo/published/luisarizmendi/rh_edge_mgmt/), but this demo also has some specific requirements that are mentioned below.

### (Optional) Copy the container images to your Quay account

During the demo there are some optional steps where you will need to push or move tags in certain container images (take a look at [minute 25:25 in the video](https://www.youtube.com/watch?v=XCtfy7AqLLY&t=25m25s)), so you will need to have access to a container image repository (the one that you configured in the `apps_registry` variable in the `playbooks/main.yml` playbook).

  >**Note**
  >
  > If you don't want to show those demo steps, you can keep `apps_registry: quay.io/luisarizmendi` and the applications will be deployed, although you won't be able to alter the container tags in the registry...

Probably you want to use Quay.io so first, check that you can login:

```bash
podman login -u <your-quay-user> quay.io
```

Once you have access to the registry, copy the container images that we will be using (those are public in my Quay.io user `luisarizmendi`). You can pull them to your laptop and then push it to your registry, or you can just use `skopeo`:

```bash
skopeo copy docker://quay.io/luisarizmendi/2048:v1 docker://quay.io/<your-quay-user>/2048:v1
skopeo copy docker://quay.io/luisarizmendi/2048:v2 docker://quay.io/<your-quay-user>/2048:v2
skopeo copy docker://quay.io/luisarizmendi/2048:v3 docker://quay.io/<your-quay-user>/2048:v3
skopeo copy docker://quay.io/luisarizmendi/2048:prod docker://quay.io/<your-quay-user>/2048:prod
skopeo copy docker://quay.io/luisarizmendi/simple-http:v1 docker://quay.io/<your-quay-user>/simple-http:v1
skopeo copy docker://quay.io/luisarizmendi/simple-http:v2 docker://quay.io/<your-quay-user>/simple-http:v2
skopeo copy docker://quay.io/luisarizmendi/simple-http:prod docker://quay.io/<your-quay-user>/simple-http:prod
```

Remember to change visibility of both 2048 and simple-http images to "public" in each "Repository Settings" 


## Deploy the lab

  >**Note**
  >
  > The deployment will take long, expect something like 60-70 minutes depending on the number of configured users, VM/device resources and network connectivity


### If you want to use the optional Terraform script
If you want to use the provided terraform script to create the server in AWS, you will need to move one level up in the directory and run:

```shell
cd ..
./create.sh
```


### If you have your VM prepared manually

Once you have all the pre-requisites ready, including the Ansible Vault secret file, you need to run the main playbook including the Vault password by adding the `--ask-vault-pass` option:

```shell
ansible-playbook -vvi inventory --ask-vault-pass playbooks/main.yml 
``` 



## Pre-flight checks

These pre-flight checks should be performed just right after the deployment. You can also use them to double-check that everything is ok before your demo...

1) Check the access to following services:

* Ansible Automation Platform Controller: https://<edge-management-ip>:8443
* Ansible Automation Platform Event-Driven Ansible Controller:  https://<edge-management-ip>:8445 
* Cockpit: https://<edge-management-ip>:9090
* Gitea: http://<edge-management-ip>:3000


2) Check container images in your registry (Quay in our example):

Go to `quay.io` in the 2024 repository and check that the "prod" tag is pointing to "v1". If not just create a new Tag "prod" by pressing the gearwheel on the "v1" label (at the right).


![2048 tags](images/rhde_gitops_quay-2048.png)


You should also check that the image in the `device-edge-configs/APPs/microshift/manifest/2-deployment.yml` file on Gitea is `v1` and not `v3`.

If this environment was never used probably it will be correctly assigned but if you already ran the demo the "prod" tag will be probably pointing to "v3".





## BONUS - If there is not enough time for your demo...

Sometimes it could happen that you don't have the 120 minutes to run the demo. One way to reduce the time is by creating the OS images in advance instead of running the build during the demo.

The demo will need to create at least three OS images  (take a look at [minute 49:37 in the video](https://www.youtube.com/watch?v=XCtfy7AqLLY&t=49m37s)):
1. The first one used to show how to onboard the device
2. The upgraded image without some of the required packages by Greenboot
3. The upgraded image but including the required packages

By default, when you "publish" an image the last one that you created is the one that is used. That behaviour can be changed by changing the value `latest` to the version that you want to publish in the `device-edge-images/production-image-deploy.yml` file located Gitea, so you could change that to `0.0.1`, then create the first image with the provided blueprint (just create, you don't need to publish until you run the demo), then create the second and third images using the v2 and v3 blueprints.

Then, during the demo, you can just use the "Publish" task. After showing the onboarding, change the  `device-edge-images/production-image-deploy.yml` file to version 0.0.2 in order to publish the second image (that was already created in the pre-demo steps) and then do the same with the third image.



Enjoy the lab!
