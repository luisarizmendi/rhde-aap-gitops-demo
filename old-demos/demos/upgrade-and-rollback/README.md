# OSTree system and podman-managed APPs lifecycle demo

## Background 

When you deploy a system in an Edge location you need to be sure that the lifecycle management must be simplified as much as possible, for example, sometimes you cannot even rely on any specialized person who can troubleshoot the system on site in case of any error.

This implies that you need to be sure that you have an easy way to rollback your APPs or the Operating System without any manual step to a previously known state where the device was working.

You can build this kind of "rollback system" in many ways, but luckily, if you are using RHEL based on OSTree images and Podman to run your containerized APPs you won't need to use any additional tool, since they provide the tools to perform automatic rollback for both the Operating System and the applications when there are problems during an upgrade.


In this demo, we will explore:

* How OSTree RHEL can be easily upgraded and, in case that the upgrade fails or it makes your applications not working as expected, how the Greenboot auto-healing feature, automatically rollbacks to the previous state.

* How Podman can update the containerized APP automatically when a new APP version is published in the registry, and how it automatically rollbacks to the previous version if the new one does not work

Additionally, there is an additional section that includes an "offtopic" use case that can be shown if you have time during the demo (no questions from audience?): Running Serverless services just with RHEL and Podman.


References:
- [Red Hat official documentation for RHEL OSTree](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/composing_installing_and_managing_rhel_for_edge_images/index)
- [Red Hat Device Edge introduction](https://cloud.redhat.com/blog/introducing-the-new-red-hat-device-edge)
- (Red Hat internal) [Red Hat Device Edge slide deck](https://docs.google.com/presentation/d/1FKQDHrleCPuE0e36UekzXdkw86wNDx16dSgllXj-swY/edit?usp=sharing)
- [OSTree based Operating Systems article](https://luis-javier-arizmendi-alonso.medium.com/a-git-like-linux-operating-system-d84211e97933)
- [Image Builder quickstart bash scripts](https://github.com/luisarizmendi/rhel-edge-quickstart)
- [Ansible Collection for OSTree image management](https://github.com/redhat-cop/infra.osbuild)
- [Article about Podman root-less containers](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics)
- [Article about implementing Serverless services with Podman](https://www.redhat.com/en/blog/painless-services-implementing-serverless-rootless-podman-and-systemd)


<br><br>
<hr style="border:2px solid gray">

## Pre-requisites

<hr style="border:2px solid gray">

You could use baremetal servers for this demo but you can run it too with just a couple of VMs running on your laptop  (Image Builder and edge device).

You need an active Red Hat Enterprise Linux subscription.

<br><br>
<hr style="border:2px solid gray">

## Demo preparation

<hr style="border:2px solid gray">


BEFORE delivering the demo, you have to complete these preparation steps.


<br><br>

###  ~ ~ ~ ~ Preparing the Image Builder ~ ~ ~ ~ 

You need a subscribed [Red Hat Enterprise Linux 9](https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.1/x86_64/product-software) system (minimal install is enough) with at least 2 vCPUs, 4 GB memory and 50 GB disk.

If you don't want to use `root`, be sure that the user has [passwordless sudo access](https://developers.redhat.com/blog/2018/08/15/how-to-enable-sudo-on-rhel).


<br>
<br>

###  ~ ~ ~ ~ Preparing your laptop ~ ~ ~ ~ 

Your will need to:

* Install Ansible

> laptop
```
dnf install -y ansible
```

* Download the `infra.osbuild` Ansible collection

> laptop
```
ansible-galaxy collection install -f git+https://github.com/redhat-cop/infra.osbuild --upgrade
```

* Modify the Ansible `inventory` file with your values

* Copy your public SSH key into the Image Builder system, so you can open passwordless SSH sessions with the user that you configured in your Ansible inventory. (double check .ssh and authorized_keys permissions in case you are still asked for password after copying the key).

> laptop
```
ssh-copy-id <user>@<image builder IP>
```

* If you are using your laptop as hypervisor, be sure that you have at least 2 vCPU, 1.5GB memory and 20 GB disk free to create the Edge device VM (in addition the Image Builder VM that you should have already up and running).


<br>
<br>

###  ~ ~ ~ ~ Preparing the APPs ~ ~ ~ ~ 

In this demo we will be using a couple of simple APPs but you can use your own applications (adapting them to your own use case).

You will need to have access to your own Container Image Repository since during the demo we will need to change published container image tags. In my example I use [Quay.io](https://quay.io). 

Once you have access to your Container Image Registry, create a couple of **public** namespaces/repositories, in my example I used `2048` and `simple-http`.

Then:

1. Update the `vars/main.yml` file with your Container Image Registry

2. Log in to your Registry (`podman login -u <registry_user> <registry>`) 

3. Run the playbook that will use `skopeo` to copy the images from quay.io/luisarizmendi to your own Registry (remember to include your user and password):

> laptop
```
ansible-playbook -vvi inventory  -e "registry_user=<your registry user>" -e "registry_password=<your registry password>"   playbooks/00-preparation-apps.yml
```

Check that you have images in your Registry and that **the `prod` image tags are pointing the APP `v1`**.

**_NOTE:_** *In case that you want to make any changes to the provided APP examples, you can [build your own images using the provided Containerfiles](APPs/README.md).*


<br>
<br>

###  ~ ~ ~ ~ Preparing the OSTree images ~ ~ ~ ~ 

Before jumping into the image preaparation, you could update the `vars/main.yml` file with the RHEL release that you want to use as base.

Run the following Ansible Playbook:

> laptop
```
ansible-playbook -vvi inventory playbooks/00-preparation-ostree.yml
```

It will:
* Install Image Builder
* Create the OSTree Image v1 and publish it using an HTTP server
* Create the OSTree Image v2
* Create the OSTree Image v3
* Create a RHEL custom ISO that will be used to deploy the RHEL OSTree edge system pointing to the OSTree repo published in the Image Builder (v1)

Once the Ansible Playbook is finished, you will see the URL where the **custom** ISO is published in the last Ansible `debug` message. Download it to the system where you will create the Edge device VM.

<br><br>
<hr style="border:2px solid gray">

## Demo steps

<hr style="border:2px solid gray">

This is the summarized list of the steps to demonstrate the RHEL OSTree and Podman auto-update capabilities (below you will find the detailed description):

0. Step 0 - Review the use cases and the environment
    1. Describe the use case: hands-off deployment + self-healing upgrades in the OS and APPs
    2. Log into the Image Builder and show the images
    3. Show the published OSTree repo and ISO in the HTTP server in `http://<image_builder_IP>/demo_upgrade`

1. Step 1 - OS lifecycle: Deploy the edge device using the ISO
    1. Boot the Edge Device from the ISO and watch auto-deployment
    2. Explain how the automation is performed (Kickstart in this case)
    3. SSH to the Edge Device using the admin user
    4. Test the application on `http://<edge_device_IP>:8081`

2. Step 2 - OS lifecycle: Upgrade to OSTree image v2 (with error)
    1. Show default upgrade policy in `/etc/rpm-ostreed.conf`
    2. Check current status with `sudo rpm-ostree status` 
    3. Publish OSTree image v2 with `ansible-playbook -vvi inventory playbooks/01-publish-image-v2.yml `
    4. Check the new update with `sudo rpm-ostree upgrade --check` and `sudo rpm-ostree upgrade --preview`
    5. Explain Greenboot and the script that check GIT in `/etc/greenboot/check/required.d/01_check_git.sh`
    6. Perform the upgrade with `sudo rpm-ostree upgrade`
    7. Review again the status with `sudo rpm-ostree status` and reboot
    8. Watch the three reboots and how in the last one the first version of the image is selected
    9. SSH to the Edge Device and check that there is a Rollback message
    10. Review the status with `sudo rpm-ostree status`

3. Step 3 - OS lifecycle: Upgrade to OSTree image v3 (OK)
    1. Publish the OSTree image version 3 with `ansible-playbook -vvi inventory playbooks/01-publish-image-v3.yml `
    2. Check that the new upgrade is available with `sudo rpm-ostree upgrade --check` and `sudo rpm-ostree upgrade --preview`
    3. Perform and upgrade with automatic reboot with `sudo rpm-ostree upgrade -r`
    4. Watch the reboot
    5. SSH to the Edge Device and check the status with `sudo rpm-ostree status`
    
4. Step 4 - APP lifecycle: Upgrade to  APP v2 (with error)
    1. Open the application in `http://<edge_device_IP>:8081`
    2. Watch the application update status with `watch "podman auto-update --dry-run; echo '';podman ps"`
    3. Move the `prod` tag from `v1` to `v2` in the registry
    4. Review the application update status and check again the application in `http://<edge_device_IP>:8081`

5. Step 5 - APP lifecycle: Upgrade to  APP v3 (OK)
    1. Move the `prod` tag to `v3` in the registry
    2. Review the application update status and check again the application in `http://<edge_device_IP>:8081`


If you have more time and want to explore more cool features that could be used in Edge Computing use cases, you can go through the "Bonus" demo steps:

6. BONUS - Serverless service with Podman
    1. Check how the configured systemd unit has pre-downloaded the container image 
    2. Watch the current running containers with `watch podman ps` (the `simple-http` app is not there)
    3. Reach out to the service in `http://<edge-device-ip>:8080`
    4. See how a new container is created and how it's serving the `simple-http` app in `http://<edge-device-ip>:8080`
    5. Wait 10 seconds and see how the service is scaled down to zero replicas


<br>
<br>

###  ~ ~ ~ ~ Step 0 - Review the use cases and the environment ~ ~ ~ ~ 

---
**Summary**

Give an overview of the overall demo steps and explain the setup.

---

We are a company that has a Central Data Center and multiple Edge locations where there are no technical specialized people and we want to cover the following use cases:

1. Deploy a new Edge Device with a simple application
2. Update our Edge Device by adding additional packages (ie. `zsh`)
3. Update the application

In order to demonstrate the "auto-healing" capabilities, we will be introducing an error in both steps 2 and 3, so we can see how the system auto-recovers from that issue, assuring the Edge Device keeps working as expected, then we will solve the issue and perform the update successfully.

The environment is composed of two systems, one is the "Image Builder", which is an already deployed RHEL 9, and an "Edge Device", that will be installed/deployed during the first step.

The Image Builder already has three OSTree images created. The first one is the one that we will use during the first deployment. The second one adds the `zsh` package but removes (by mistake) the `git` package which is needed by the system (let's imagine that one of the system services needs to clone or fetch new files using GIT). The Third image includes the `zsh` package but also keeps the `git` package. 

**_NOTE:_** *Every time that you run the `00-preparation-ostree.yml` ansible playbook three images are generated and the previous ones are not deleted, so if you run it multiple times you will see more than just three images in Cockpit.*

Follow these steps to review the Image Builder concepts:

1. Log into the Image Builder Cockpit (`https://<image_builder_IP>:9090`) using `root`
2. Go to Image Builder, open the "demo_upgrade" blueprint and explain the Blueprint concept
3. Show the three different images already created, explain the differences between them (installed packages)

As explained, there are three different images already created (to save time during the demo), but just the first one is being "published". The generated OSTree repo is shared using an HTTP service running on the Image Builder (in the future, Ansible Automation Hub will be the preferred way to host the generated OSTree repos). You can check the OSTree repository contents in `http://<image_builder_IP>/demo_upgrade/repo/`

The Image builder also created an installation ISO used to deploy the Edge Device that can be downloaded from `http://<image_builder_IP>/demo_upgrade/images/`. This ISO is already pre-downloaded ready to be used.

<br>
<br>

###  ~ ~ ~ ~ Step 1 - OS lifecycle: Deploy the edge device using the ISO ~ ~ ~ ~ 

---
**Summary**

Show how easy is to deploy the Edge Device with a fully automated (hands-off) installation and customization process for both the Operating System and the application.

---

In order to deploy the Edge Device, follow these steps:

1. Create a VM that will be the Edge Device (if you are not using a baremetal machine) with at least 1 vCPU, 1.5GB memory, 20GB disk and one NIC in a network from where it has access to the Image Builder.

2. Use the ISO downloaded from the Image Builder to install the system. Just be sure that the system is starting from the ISO, everything is automatic.

3. Wait until the system prompt.

Meanwhile the system is installing, you can comment that:

* Instead using the ISO directly system by system, you could also host the ISO in an HTTP server centrally and boot systems from network by using UEFI HTTP boot, so the person at the edge location will only need to boot the system (if HTTP Boot has been enable in the device).
* The ISO is a regular RHEL 9 boot ISO with just a change, we introduced in the Kernel Args that makes the system download a kickstart from the Image Builder and execute it (you can review the Kickstar in http://<image_builder_IP>/demo_upgrade/kickstart.ks). This kickstart could be also be injected directly into the ISO instead of downloading it from the Image Builder every time that we deploy a new system.
* We are using a kickstart to automate the OSTree image deployment (the OSTree repo is downloaded from the Image Builder in this case, but it could be also injected in the ISO) along with the different customizations. This is a simple way to customize the deployment but it could introduce risks if we need to include "secrets" such as passwords or certificates in the configuration. In order to perform a secure device deployment you could use FIDO Device Onboarding (FDO). This is not part of this demo but you can learn more about it by running this [FDO workshop](https://luisarizmendi.github.io/tutorial-secure-onboarding).
* All the deployed applications are root-less in order to have an improved security in our system.

Once the deployment finished you can get the system IP and:

**_NOTE:_** *Depending on your Internet connection, downloading the images could take some time.*

* Test the application at `http://<edge_device_IP>:8081`
* Connect to the system by SSH using the user configured in the Blueprint (`admin`). You shouldn't need password if you used the same laptop from where you ran the demo preparation since the SSH public key was injected into the OSTree image, otherwise you can use the password configured in the Blueprint (`R3dh4t1!`).
* Review the configured systemd service with the root-less contanerized application (`systemctl --user status container-app1.service`) and show the systemd unit file that runs the container (`cat /var/home/admin/.config/systemd/user/container-app1.service`).

<br>
<br>

###  ~ ~ ~ ~ Step 2 - OS lifecycle: Upgrade to OSTree image v2 (with error) ~ ~ ~ ~ 
---
**Summary**

Demonstrate the upgrade self-healing feature that automatically rollbacks to the previous known state in case that the upgrade breaks something in either the system or the running applications.

---

Explain that by default, the OSTree Automatic Update Policy is set to `none` which disables automatic updates, but you can change it to `check` option which automatically downloads upgrade metadata to display available updates or `stage` (experimental) option, which downloads and unpacks the update which will be finalized on a reboot.

You can open the configuration file to show that the default is configured:

> edge device
```
cat /etc/rpm-ostreed.conf


# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# For option meanings, see rpm-ostreed.conf(5).

[Daemon]
#AutomaticUpdatePolicy=none
#IdleExitTimeout=60
```

You can also check the running and the current available image versions:

> edge device
```
sudo rpm-ostree status


State: idle
Deployments:
● edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)
```

Also check that, at this moment, there are no available upgrades:

> edge device
```
sudo rpm-ostree upgrade --check


1 metadata, 0 content objects fetched; 196 B transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
No updates available.

```


Now it's time to "publish" the new image that was created in advance (to save time) in the Image Builder. Run this Ansible Playbook to do it:

> laptop
```
ansible-playbook -vvi inventory playbooks/01-publish-image-v2.yml 
```

Once the playbook finishes the new Image is ready and you can check that the Edge Device has a new available image upgrade: 

> edge device
```
sudo rpm-ostree upgrade --check


2 metadata, 0 content objects fetched; 15 KiB transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.2 (2023-02-09T09:09:19Z)
         Commit: 052229013afc1cb18789991a7d9bcab29272e06eefc6aa0442c352e85c9ad0cf
           Diff: 55 removed, 1 added
```

You can see how the difference between the running image and the new one is that 55 packages were removed and one additional package added. I you want more information about these changes you can check the "preview":

> edge device
```
sudo rpm-ostree upgrade --preview



1 metadata, 0 content objects fetched; 196 B transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.2 (2023-02-09T09:09:19Z)
         Commit: 052229013afc1cb18789991a7d9bcab29272e06eefc6aa0442c352e85c9ad0cf
        Removed: emacs-filesystem-1:27.2-6.el9.noarch
                 git-2.31.1-3.el9_1.x86_64
                 git-core-2.31.1-3.el9_1.x86_64
                 git-core-doc-2.31.1-3.el9_1.noarch
                 groff-base-1.22.4-10.el9.x86_64
                 ncurses-6.2-8.20210508.el9.x86_64
                 perl-Carp-1.50-460.el9.noarch
                 perl-Class-Struct-0.66-479.el9.noarch
                 perl-DynaLoader-1.47-479.el9.x86_64
                 perl-Encode-4:3.08-462.el9.x86_64
                 perl-Errno-1.30-479.el9.x86_64
                 perl-Error-1:0.17029-7.el9.noarch
                 perl-Exporter-5.74-461.el9.noarch
                 perl-Fcntl-1.13-479.el9.x86_64
                 perl-File-Basename-2.85-479.el9.noarch
                 perl-File-Find-1.37-479.el9.noarch
                 perl-File-Path-2.18-4.el9.noarch
                 perl-File-Temp-1:0.231.100-4.el9.noarch
                 perl-File-stat-1.09-479.el9.noarch
                 perl-Getopt-Long-1:2.52-4.el9.noarch
                 perl-Getopt-Std-1.12-479.el9.noarch
                 perl-Git-2.31.1-3.el9_1.noarch
                 perl-HTTP-Tiny-0.076-460.el9.noarch
                 perl-IO-1.43-479.el9.x86_64
                 perl-IPC-Open3-1.21-479.el9.noarch
                 perl-MIME-Base64-3.16-4.el9.x86_64
                 perl-POSIX-1.94-479.el9.x86_64
                 perl-PathTools-3.78-461.el9.x86_64
                 perl-Pod-Escapes-1:1.07-460.el9.noarch
                 perl-Pod-Perldoc-3.28.01-461.el9.noarch
                 perl-Pod-Simple-1:3.42-4.el9.noarch
                 perl-Pod-Usage-4:2.01-4.el9.noarch
                 perl-Scalar-List-Utils-4:1.56-461.el9.x86_64
                 perl-SelectSaver-1.02-479.el9.noarch
                 perl-Socket-4:2.031-4.el9.x86_64
                 perl-Storable-1:3.21-460.el9.x86_64
                 perl-Symbol-1.08-479.el9.noarch
                 perl-Term-ANSIColor-5.01-461.el9.noarch
                 perl-Term-Cap-1.17-460.el9.noarch
                 perl-TermReadKey-2.38-11.el9.x86_64
                 perl-Text-ParseWords-3.30-460.el9.noarch
                 perl-Text-Tabs+Wrap-2013.0523-460.el9.noarch
                 perl-Time-Local-2:1.300-7.el9.noarch
                 perl-constant-1.33-461.el9.noarch
                 perl-if-0.60.800-479.el9.noarch
                 perl-interpreter-4:5.32.1-479.el9.x86_64
                 perl-lib-0.65-479.el9.x86_64
                 perl-libs-4:5.32.1-479.el9.x86_64
                 perl-mro-1.23-479.el9.x86_64
                 perl-overload-1.31-479.el9.noarch
                 perl-overloading-0.02-479.el9.noarch
                 perl-parent-1:0.238-460.el9.noarch
                 perl-podlators-1:4.14-460.el9.noarch
                 perl-subs-1.03-479.el9.noarch
                 perl-vars-1.05-479.el9.noarch
          Added: zsh-5.8-9.el9.x86_64
```

So `zsh` will be added and `git` (and its dependencies) will be removed if we upgrade the image.


In our use case, we said that we have to imagine that the services running on this Edge Device rely on GIT to fetch files from different repositories, so if we remove GIT from our system, the services won't work as expected. 

We wouldn't like to be checking manually every single image change, so OSTree provides a useful tool that you can use to check your system or apps right after the upgrade: Greenboot.

With Greenboot you can write your own check scripts that can, for example, make requests to the running applications, check connectivity to external resources such as databases, or ensure that certain tools are available in the system.

You can write checks that will show a warning message after the upgrade in case of a failure (the ones located in `/etc/greenboot/check/wanted.d`), but you can also write scripts that, if failed, automatically rollback the upgrade (`/etc/greenboot/check/required.d`). In our case we created a super-simple script that just check that GIT binary is available:

> edge device
```
cat /etc/greenboot/check/required.d/01_check_git.sh 


#!/bin/bash
git --help
```

This script will fail if we upgrade to the image shown above.... let's upgrade the system and see what happens. 

Let's start by downloading the new image and configuring it to be used in the next reboot:

> edge device
```
sudo rpm-ostree upgrade 


⠒ Scanning metadata: 1782... 
Scanning metadata: 1782... done
Staging deployment... done
Removed:
  emacs-filesystem-1:27.2-6.el9.noarch
  git-2.31.1-3.el9_1.x86_64
  git-core-2.31.1-3.el9_1.x86_64
  git-core-doc-2.31.1-3.el9_1.noarch
  groff-base-1.22.4-10.el9.x86_64
  ncurses-6.2-8.20210508.el9.x86_64
  perl-Carp-1.50-460.el9.noarch
  perl-Class-Struct-0.66-479.el9.noarch
  perl-DynaLoader-1.47-479.el9.x86_64
  perl-Encode-4:3.08-462.el9.x86_64
  perl-Errno-1.30-479.el9.x86_64
  perl-Error-1:0.17029-7.el9.noarch
  perl-Exporter-5.74-461.el9.noarch
  perl-Fcntl-1.13-479.el9.x86_64
  perl-File-Basename-2.85-479.el9.noarch
  perl-File-Find-1.37-479.el9.noarch
  perl-File-Path-2.18-4.el9.noarch
  perl-File-Temp-1:0.231.100-4.el9.noarch
  perl-File-stat-1.09-479.el9.noarch
  perl-Getopt-Long-1:2.52-4.el9.noarch
  perl-Getopt-Std-1.12-479.el9.noarch
  perl-Git-2.31.1-3.el9_1.noarch
  perl-HTTP-Tiny-0.076-460.el9.noarch
  perl-IO-1.43-479.el9.x86_64
  perl-IPC-Open3-1.21-479.el9.noarch
  perl-MIME-Base64-3.16-4.el9.x86_64
  perl-POSIX-1.94-479.el9.x86_64
  perl-PathTools-3.78-461.el9.x86_64
  perl-Pod-Escapes-1:1.07-460.el9.noarch
  perl-Pod-Perldoc-3.28.01-461.el9.noarch
  perl-Pod-Simple-1:3.42-4.el9.noarch
  perl-Pod-Usage-4:2.01-4.el9.noarch
  perl-Scalar-List-Utils-4:1.56-461.el9.x86_64
  perl-SelectSaver-1.02-479.el9.noarch
  perl-Socket-4:2.031-4.el9.x86_64
  perl-Storable-1:3.21-460.el9.x86_64
  perl-Symbol-1.08-479.el9.noarch
  perl-Term-ANSIColor-5.01-461.el9.noarch
  perl-Term-Cap-1.17-460.el9.noarch
  perl-TermReadKey-2.38-11.el9.x86_64
  perl-Text-ParseWords-3.30-460.el9.noarch
  perl-Text-Tabs+Wrap-2013.0523-460.el9.noarch
  perl-Time-Local-2:1.300-7.el9.noarch
  perl-constant-1.33-461.el9.noarch
  perl-if-0.60.800-479.el9.noarch
  perl-interpreter-4:5.32.1-479.el9.x86_64
  perl-lib-0.65-479.el9.x86_64
  perl-libs-4:5.32.1-479.el9.x86_64
  perl-mro-1.23-479.el9.x86_64
  perl-overload-1.31-479.el9.noarch
  perl-overloading-0.02-479.el9.noarch
  perl-parent-1:0.238-460.el9.noarch
  perl-podlators-1:4.14-460.el9.noarch
  perl-subs-1.03-479.el9.noarch
  perl-vars-1.05-479.el9.noarch
Added:
  zsh-5.8-9.el9.x86_64
Run "systemctl reboot" to start a reboot
```

You can check that in the next reboot, the new image will be used by running again `rpm-ostree status`. Take a look that the current running version has a dot (`●`) and that the version that is placed in the first place (the one that will be selected by default in the next boot) is the new image:

> edge device
```
sudo rpm-ostree status


State: idle
Deployments:
  edge:rhel/9/x86_64/edge
                  Version: 0.0.2 (2023-02-09T09:09:19Z)
                     Diff: 55 removed, 1 added

● edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)
```

**_NOTE:_** *Due to [an issue](https://github.com/redhat-cop/infra.osbuild/issues/94) with `rpm-ostree upgrade --check` and `--preview` commands at this moment we cannot publish the new images creating a new `ostree` commit, we can [just copy files into the HTTP server](https://github.com/luisarizmendi/edge-demos/blob/main/common/playbooks/publish-image.yml), so the "version" number is lost during the upgrade. You will see `Version: 9.1` in the updated image until this issue is fixed.*

It's time to reboot, but before running the following command, be sure that you are showing the Edge Device console to being able so see what happens during the reboot process:

> edge device
```
sudo systemctl reboot
```

While rebooting you can explain that the system will try to boot three times, the first two starting from `ostree:0` (shown in the Grub menu) and the last one will turn back to `ostree:1` which is the second entry that we show in `rpm-ostree status`, so the previous image.

After the third reboot, you will get the command prompt. Try to SSH again to the Edge Device, you will see a message showing that there was a problem with the upgrade:

> laptop
```
ssh admin@<edge_device_IP>


Boot Status is GREEN - Health Check SUCCESS
FALLBACK BOOT DETECTED! Default rpm-ostree deployment has been rolled back.
Last login: Thu Feb  9 09:46:53 2023 from 192.168.122.1
```

If you check the available images you will see how the "running" image and the "next default image on reboot" are the same, the first image where we have GIT installed.

> edge device
```
sudo rpm-ostree status


State: idle
Deployments:
● edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)

  edge:rhel/9/x86_64/edge
                  Version: 0.0.2 (2023-02-09T09:09:19Z)
```

<br>
<br>

###  ~ ~ ~ ~ Step 3 - OS lifecycle: Upgrade to OSTree image v3 (OK) ~ ~ ~ ~ 
---
**Summary**

Show a successful Edge Device upgrade.

---

You need to publish a new image version (v39) that remove `zsh` but keep `git` installed:

> laptop
```
ansible-playbook -vvi inventory playbooks/01-publish-image-v3.yml 
```

After publishing it, you can check that you have a new upgrade available in the system:


> edge device
```
sudo rpm-ostree upgrade --check


note: automatic updates (stage) are enabled
2 metadata, 0 content objects fetched; 17 KiB transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.3 (2023-02-09T09:17:09Z)
         Commit: 007328e8dee132c4c16c68ff2874085f2415fcbff5b997b798980c8f4dc5b743
           Diff: 1 added

```


The only difference between the running image and the new image is that `zsh` has been added:

> edge device
```
sudo rpm-ostree upgrade --preview


note: automatic updates (stage) are enabled
1 metadata, 0 content objects fetched; 196 B transferred in 0 seconds; 0 bytes content written
Note: --check and --preview may be unreliable.  See https://github.com/coreos/rpm-ostree/issues/1579
AvailableUpdate:
        Version: 0.0.3 (2023-02-09T09:17:09Z)
         Commit: 007328e8dee132c4c16c68ff2874085f2415fcbff5b997b798980c8f4dc5b743
          Added: zsh-5.8-9.el9.x86_64
```

Download the image and reboot (with `-r`)

> edge device
```
sudo rpm-ostree upgrade -r


24 metadata, 3 content objects fetched; 11494 KiB transferred in 0 seconds; 40.1 MB content written
Staging deployment... done
Added:
  zsh-5.8-9.el9.x86_64
```

After the reboot SSH again into the Edge Device:

> laptop
```
ssh admin@<edge_device_IP>


Boot Status is GREEN - Health Check SUCCESS
Last login: Thu Feb  9 09:54:43 2023 from 192.168.122.1
```

And then check that you are running the most recent image version:

> edge device
```
sudo rpm-ostree status


State: idle
AutomaticUpdates: stage; rpm-ostreed-automatic.timer: inactive
Deployments:
● edge:rhel/9/x86_64/edge
                  Version: 0.0.3 (2023-02-09T09:17:09Z)

  edge:rhel/9/x86_64/edge
                  Version: 0.0.1 (2023-02-09T09:01:58Z)
```

<br>
<br>

###  ~ ~ ~ ~ Step 4 - APP lifecycle: Upgrade to  APP v2 (with error) ~ ~ ~ ~ 
---
**Summary**

Show how Podman auto-update not only simplifies the contenerized workloads lifecycle at edge but also how its self-healing feature could prevent a service disruption by automatically rollback to the previous container image version.

---

Go to `http://<edge_device_IP>:8081` and check your application. In the provided example it is a 2048 board game. 

In our use case we would like to update this application to a new version where we include a big image with the RHEL logo. 

We already created the new container image, which is tagged as `v2` and pushed it to the registry. 


**_NOTE:_** *Now it's a good time to open the registry and see the container image and its tags.*


If you check the registry you will see that you don't have just `v1` and `v2` tags, you also have the `prod` tag that is pointing to the "active" container image version, in this case it is pointing to `v1`, but you also have a `v3` image, why?

You find three tags/images because we want to demonstrate during this step not only how podman can autoupdate the image with just changing where the `prod` tag is pointing, but also how Podman can rollback if the updated image does not work.

In this case we simulated that, due to a mistake, the image v2 introduces an error that makes that the application is unable to start (you can check how we included the logo but also how we misspelled `nginx` in the used [Containerfile for the version 2](../../APPs/2048/Containerfile.v2-error)). That mistake is solved in image `v3`.


Let's update the image in the Edge Device by just changing the `prod` tag in the registry but before than, in order to see what's going on in the device run:

> edge device
```
watch "podman auto-update --dry-run; echo '';podman ps"

```

This command will permit you to see the changes in the Edge Device after "updating" the container image by moving the `prod` tag. The first lines show if Podman detects that there is a new version of the image, and in the second part of the output the running containers. Here is an example of the output before the update:

> edge device
```
UNIT                    CONTAINER            IMAGE                            POLICY      UPDATED
container-app1.service  dc3dead35d5b (app1)  quay.io/luisarizmendi/2048:prod  registry    false

CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS            PORTS                         NAMES
dc3dead35d5b  quay.io/luisarizmendi/2048:prod              9 minutes ago  Up 9 minutes ago  192.168.122.4:8081->8081/tcp  app1
```

It is a good idea to keep this output visible while you change the tag in the registry, so you see the effect on the Edge Device right away.

If you are using [Quay.io](quay.io) moving the tag is easy, you just need to follow the steps shown in the following GIF:

![Moving prod tag](DOCs/images/container_to_v2.gif)


If you are using any other registry, or if you want to do it using Podman (include your `registry/repository`):

> laptop
```
podman tag <registry>/2048:v2 <registry>/2048:prod

podman push <registry>/2048:prod
```

Right after changing the `prod` tag you will see how the command output changes into "UPDATED = pending":

> edge device
```
UNIT                    CONTAINER            IMAGE                            POLICY      UPDATED
container-app1.service  e252a5db31f8 (app1)  quay.io/luisarizmendi/2048:prod  registry    pending
```

And how the system tries to start the new version... but since it fails what Podman does is to re-start the old version. You can check that if you visit again `http://<edge_device_IP>:8081` and see how the new image does not appear.

This makes that, even with a wrong image, the service at the Edge Device keeps working.

<br>
<br>

###  ~ ~ ~ ~ Step 5 - APP lifecycle: Upgrade to  APP v3 (OK) ~ ~ ~ ~ 
---
**Summary**

Show a successful Edge Device upgrade.

---

Change the `prod` tag to point to `v3` while you have open the console which is running `watch "podman auto-update --dry-run; echo '';podman ps"`.

You will see similar changes to the previous step, but this time it stabilizes because the new version (`v3`) works.

Check again `http://<edge_device_IP>:8081` and see how the RHEL logo appears in the page (remember to clean the browser cache if it's necessary).


<br>
<br>

###  ~ ~ ~ ~ BONUS - Serverless service with Podman ~ ~ ~ ~ 
---
**Summary**

Demonstrate that people don't need complex systems to have advanced features such as Serverless services, you can implement them in Edge devices with low hardware footprint by using RHEL and Podman, consuming even less resources in your system since the applications won't be running unless they are used.

---

Before using the service is important to explain that the serverless services are not running if they are not being used, so by default the container image won't be pulled until the first request to the system... which will imply a delay because the service won't be ready until the image is downloaded. In order to remove that wait during the first request, an auto-pull image service has been created in the system, so the image is ready even before the first request.

You can double-check that the fresh system already have locally the application container image:

1. Find the edge device IP address and ssh to it (using the `admin` user if you used the blueprint example). 

2. Check the `pre-pull-container-image` systemd unit status with `systemctl --user status pre-pull-container-image.service` and show the systemd unit file with `cat /var/home/admin/.config/systemd/user/pre-pull-container-image.service`. Then if the script is finished the container image is ready with `podman image list` (remember that you will have two images, the one used during the previous steps of the demo, and the serverless application, which in my example is `simple-http`).

> edge device
```
[admin@localhost ~]$ podman image list
REPOSITORY                         TAG         IMAGE ID      CREATED       SIZE
quay.io/luisarizmendi/simple-http  prod        7af8b56b6d83  24 hours ago  296 MB
quay.io/luisarizmendi/2048         prod        21bbdd4e9419  25 hours ago  444 MB
```

3. Now let's prepare for the service request, run a continuous command that check which containers are running on the system with `watch podman ps` and check that you only have one single container running, the one with the service used in the lifecycle demo, but you don't have the one with the Serverless service (`simple-http` in the example). Remember to **let visible the output of the `watch` command** during the next step, so you can notice when the container starts running).

> edge device
```
CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS            PORTS                           NAMES
3dc739ae55d8  quay.io/luisarizmendi/2048:prod              5 minutes ago  Up 5 minutes ago  192.168.122.101:8081->8081/tcp  app1
```

4. Access the service published on port 8080 on the edge device (`http://<edge-device-ip>:8080`). The service will return a Text message. At this point you will see in the console running the `watch` command how a new container started as soon as the request was made (Serverless).

5. If you don't request the service again and you wait 60 second, you will be able to see in the console running the `watch` command  how the Serverless service scales down to zero replicas (no container with the service is running) again, saving resources until the system get a new request to the service.

If you want to test the scale-down , just stop the requests to the service and wait 60 seconds, the container should start the shutdown (stop time will depend on the service).

You can also test the Podman image auto-update feature with this service but bear in mind that Podman auto-update works if the container is running, so if your Serverless service scaled-down to zero the new version won't be pulled until the container is started again.











