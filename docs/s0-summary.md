# Summary and demo step guide

## Features and concepts

During this demo, the following features will be shown:

* Create and publish an OSTree repository using a GitOps approach

* Edge Device installation ISO generation:
  * Injecting kickstart in a base ISO (standard RHEL ISO)
  * Using Image Builder to create a Simplified installer

* Device Onboarding customization using the following different methods:
  * Kickstart
  * Custom RPMs
  * AAP post-automation
  * Ignition files
  * FDO process

* Application deployment using:
  * Podman
    * Using shell scripting
    * Using Quadlet descriptors (GitOps)
  * Microshift
    * Using Manifest (GitOps)
    * Using Help
  * Custom RPM

* Edge Device Self-Healing
  * Auto rollbacks in Operating System Upgrades
  * Edge Device configuration enforcing (GitOps)
  * Podman auto-update rollback

* Extras:
  * Serverless rootless container applications with just Podman

## Demo steps

This is the summary of the demo steps:

1. Section 1 - Creating RHEL Images the GitOps way
    1. Open Gitea and review the `device-edge-images` repository files
    2. Open Gitea webhook settings
    3. Open "Jobs" page in AAP and keep it visible
    4. Push `rhde/prod/rhde_image/production-image-definition.yml` and `rhde/prod/rhde_image/production-kickstart.ks` files
    5. Show the "New Edge Device Image" Workflow at the AAP
    6. Open the Image Builder Cockpit Web console and check that the image is being created
    7. Describe the `rhde/prod/rhde_image/production-image-definition.yml` and `rhde/prod/rhde_image/production-kickstart.ks` that you used to create the image
    8. Go to the "New Edge Device Image" workflow in AAP and Approve the Image Publishing
    9. Open the ostree-repo contents published, including `kickstarts` and the `repos` directories in `http://<edge-management-server-ip>/<user>/prod/`.

2. Section 2 - Automated device onboarding
    1. Open the "Jobs" page in the AAP and keep it visible while performing the following steps.
    2. Boot the edge server from Network and select the right Image in the PXE menu
    3. Wait until the server bootsand review the Workflow Jobs in AAP
    4. SSH into the edge device and explain how AAP auto-registration is done

3. Section 3 - Consistent edge device configuration at scale
    - Configuration consistency across all devices
        1. Show that sudo is not asking for a password by running `sudo cat /etc/hosts` on the edge device
        2. Open "Jobs" page in AAP and keep it visible while performing the next step
        3. Change the `rhde/prod/rhde_config/os/etc/sudoers` file in Gitea to force sudo to ask for a password
        4. Review Jobs running in AAP
        5. Check that `/etc/sudoers` in the edge device has the desired configuration
        6. Show how now `sudo cat /etc/hosts` command ask for a password

    - (Optional) Preventing manual configuration overwrite
        1. Open an SSH Terminal in the edge device as root user and keep the "Jobs" page in AAP visible while performing the next step
        2. Overwrite manually the `/etc/sudoers` file and remove password authentication again
        3. Show how the "Configure Edge Device" Workflow Job is being launched automatically in AAP
        4. Run `cat /etc/sudoers` in the edge device to check that you have the "right" configuration back 
        5. Show the Python script that monitors file changes in `/etc/` with `cat /usr/local/bin/watch_etc.py`

4. Section 4 - Edge computing APPs lifecycle management

    - APPs with Podman and Systemd

        - Deploying an APP in Podman in a declarative way
            1. Show `rhde/prod/rhde_config/apps/podman/quadlet` folder in Gitea
            2. Run the "Create Quadlet APP" Template in AAP
            3. Run `podman ps` on the device
            4. Show the APP by visiting `http:<edge device IP>:<configured port>`
            5. Change something in the `rhde/prod/rhde_config/apps/podman/quadlet/` app and see the change


        - (Optional) Podman "self-managing" features with Podman container image auto-update
            1. Open `http:<edge device ip>:8081` in your laptop
            2. Show the image load problem in the APP
            3. Show the binding betwen `prod` and `v1` tags in Quay.io for the 2048 continer image
            4. Show the issue introduced in container image `v2`
            5. Run the `watch 'podman auto-update --dry-run; echo ""; podman ps'`
            6. Move the `prod` container image tag to `v2` in Quay.io
            7. Show how the new image is detected and deployed but how Podman rollback to the previous version due to the issue
            8. Move the `prod` container image tag to `v3` where the image locad problem is solved and show the fixed app in your Browser 

        - (Optional) Example of Podman additional capabilities for edge: Serverless APP with just Podman and Systemd
            1. Run `podman ps` on the edge device
            2. Run `watch podman ps` on the edge device
            3. Visit `http://<edge device IP>:8080` from your laptop
            4. Show what happened in the `watch podman ps` terminal
            5. Wait 90 seconds and show how the Container is stopped automatically


    - APPs with Microshift

        - Deploy an APP on Microsift from Manifest files on Gitea
            1. Show manifests located in `rhde/prod/rhde_config/apps/microshift/manifest` in Gitea.
            2. Run `watch "oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pod --all-namespace"` as root
            3. Launch the  "Microshift APP Deploy - Manifest" Template in AAP
            4. Open `http://frontend-game2048.apps.<edge device ip>.nip.io` in your laptop
            5. Open "Jobs" in AAP and keep it visible along with the `watch` on the CLI
            6. Change image version to `v3` in `rhde/prod/rhde_config/apps/microshift/manifest/2-deployment.yml`
            7. Check the `watch` command and wait until the new POD is running
            8. Open `http://frontend-game2048.apps.<edge device ip>.nip.io` in your laptop and show the 2048 app with the image loaded

        - Deploy an APP on Microsift with external Helm repo and vars file on Gitea
            1. Open "Jobs" in AAP and `watch "oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pod --all-namespace"`
            2. Show `rhde/prod/rhde_config/apps/microshift/helm/wordpress_vars.yml` in Gitea
            3. Run the  "Microshift APP Deploy - Helm" Template manually in the AAP
            4. Visit `http://wordpress-wordpress.apps.<edge device ip>.nip.io` in your laptop when the PODs are running
            5. Open `rhde/prod/rhde_config/apps/microshift/helm/wordpress_vars.yml` and change the `replicaCount` number
            6. Wait and see how that number of replicas is deployed on Microshift

5. Section 5 - Bulletproof system upgrades

    1. Check that there are no pending upgrades with `watch "rpm-ostree upgrade --preview"`
    2. Modify the `builder_compose_pkgs` in the image definition by removing `python-inotify` and adding `zsh`
    3. Show the Image Creation Workflow in AAP
    4. Explain Greenboot meanwhile the image is created and show the `01-check-packages.sh` script
    5. Publish the new image in AAP
    6. Check the upgrade availability with `rpm-ostree upgrade --preview` in the edge system
    7. Perform the upgrade by either running `rpm-ostree upgrade` and rebooting using the CLI or by launching the "	OSTree Upgrade" Job Template in AAP
    8. Watch the system console while the edge device tries to boot the new system image (and how to finally it fallbacks to the previous image)
    9. Show the "Upgrade Failed" message in Slack
    10. SSH to the edge device and review Greenboot and Journal messages
    11. Show with `rpm-ostree upgrade --check` that we still have pending the upgrade
    12. Create and publish the new Image by modifying the Image description in Gitea adding again the `python-inotify` package.
    13. Perform again the upgrade and check that this time the system is able to complete it.

6. Section 6 - Secure Onboarding with FDO

    1. Open Gitea and explain the files in `rhde_image/test` directory
    2. Modify something in the `test-image-definition.yml` to trigger the build of a new image
    3. Show the Workflow in AAP
    4. Download the ISO from `http://<edge manager ip>/<user>/` and show the `test-ignition.ign` file
    5. Prepare your Hardware or create the VM (with UEFI boot and a TPM module included) 
    6. Open an SSH session in the Edge Management server and run `sudo watch /etc/fdo/stores`    
    7. Boot from the ISO. While waiting explain FDO automations with the `/etc/fdo/serviceinfo-api-server.conf.d/serviceinfo-api-server.yml` file
    8. SSH the edge device and show that both the Ignition and FDO customizations took place. Show `journalctl -u fdo-client-linuxapp` 
    9. Show and explain how the FDO Vouchers where used during the onboarding (in this demo with auto-approval)





















## DEMO deployment

## DEMO steps

### 1 - Modify the RHDE image description

* Go to Gitea in the edge management host at port `3000`
* Log in as a user (by default `user<number>`/`password<number>`)
* Modify the file in `rhde/prod/rhde_image/production-image-definition.yml`. You can include the `bind-utils` package

### 2 - Check that an Ansible Workflow automatically starts and build the new image

* Log in the AAP Controller (port `8443`) as a regular user (by default `user<number>`/`password<number>`)
* Check the "Jobs" view and see if a new Workflow has started 

### 3 - Accept the image publishing in that Workflow once the image is created

* Wait until the image is created, you can check the progress by using Cockpit (port `9090`)
* Approve the image publishing in the Workflow

### 4 - Create an ISO to deploy the image

* Launch the `Create ISO Kickstart` task under "Templates" view in AAP Controller. Default variables should be ok unless you are not using default values for this demo
* Download the ISO from the URL shown in the last `debug` message that you will find in the `Create ISO Kickstart` task output (maybe you need to "Reload output" when the task is done to see the debug message at the end)

  >**Note**
  >
  > If you create/publish new versions of your image for your demo, you don't need to create additional ISO images, you will be able to re-use the same ISO while the environment (`prod`) or the image name changes.


### 5 - Deploy the image in the edge device

* Start the edge device from the ISO that you downloaded (using an USB if it's a physical device).
* Wait until the deployment finishes. Then the device will reboot and use the local drive as first boot option
* Wait a little bit until you see in AAP Controller a new Workflow execution (`Provision Edge Device` Workflow)


### 6 - Check that the device is auto-registered in AAP and correctly onboarded (in this base demo it is just a change in the hostname)

* Log into the edge deivice (you can check the IP in the AAP inventory)
* Check that the hostname was changed and a new entry configured in `/etc/hosts`
* You can also take a look at the Event Driven Automation Controller (port `8445`, credentials `admin`/`R3dh4t1!` if not customized during the deployment) to check out how the request were processed.

