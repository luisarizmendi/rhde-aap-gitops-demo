# APPs with Microshift

## Video

[![Section 4 Microshift - Video](https://img.youtube.com/vi/tmMjHBq28bY/0.jpg)](https://www.youtube.com/watch?v=tmMjHBq28bY)


---


During the onboarding, Applications are deployed automatically into Microshift in two ways during this demo:
  * Using the manifest located in Gitea (`rhde/prod/rhde_config/microshift/manifest`)
  * Using the manifest located in `/usr/lib/microshift/manifests/`. Those manifest were created by a custom RPM (`workload-manifests`) installed while preparing the RHDE image.

You can also deploy applications with Helm in Microshift, that will also be explained below.

Depending on the network Bandwidth and the system resources, Microshift can take some time to start since it needs to download the container images and run the required PODs (I've seen even 15 minutes delays). While starting you will see PODs such as `ovnkube-master`, `ovnkube-node` and `node-resolver` in `ContainerCreating` and the rest of PODs in `Pending`.

If after some time your PODs are still not running, it could happen that your system does not have a right `pull-secret` configured in `/etc/crio/openshift-pull-secret` (it should have been deployed by AAP during the onboarding from Gitea).

  >**Note**
  >
  > Remember that you included your pull secret in a file (`prod/rhde_config/os/etc/crio/openshift-pull-secret`) on your Gitea repository before onboarding, so the file must be already copied to device into `/etc/crio/openshift-pull-secret`



## Apps deployed during onboarding from `/usr/lib/microshift/manifests/`

In Microshift you can deploy applications automatically if you configure Kustomize and a set of manifest in `/usr/lib/microshift/manifests/`. In this demo we included those manifest and kustomize file using a custom RPM (`workload-manifests`) that we included in the image that we created.

You can see how the APPs are running by following these steps:

1) Connect using SSH to the edge device

2) Review all the deployed Microshift PODs:

```bash
oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pods --all-namespaces
```

3) You can check the embeded manifest in the RHDE image located in `rhde/prod/rhde_config/microshift/manifest`


4) Check the APP routes. You will see that there are no routes configured. That's because I didn't want to fix the domain in the custom RPM files. You can expose the application if you want to access it

```bash
oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig -n test expose service hello-test-service
```

.
  >**Note**
  >
  > Microshift, which is a Kubernetes node, will rely on a wildcard domain name to publish the APPs. Since the edge device IP is not fixed by the playbooks we don't setup any DNS entry on the edge local server. The easiest way to obtain a wildcard for this demo is by using the [nio.ip](http://nio.io) service which resolves to the IP that you use as a prefix on the domain name (so `http://1.1.1.1.nip.io` will resolve to `1.1.1.1`). As you can see there is already a deployed test app that you can check on `http://test.apps.<edge device ip>.nip.io` on the Web Browser with the SOCKS proxy configured..

5) We deployed the `2048` app in version `v1`. If you remember that version had a problem that does not load an image. Open `http://frontend-game2048.apps.<edge device ip>.nip.io/` and check that is the case. 

6) Open the SSH CLI on the edge device and run the command `watch "sudo oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pods --all-namespaces"` to show continuosly the running PODs. Let this CLI terminal visible.

7) Then go to Gitea and in `rhde/prod/rhde_config/microshift/manifest/2048/app_2048-microshift-2-deploy.yml` change the container image from version `v1` to `v3` where the issue is fixed. You will see in thej CLI terminal how a new deployment of the application is created. Once in `Running` status open again the application and you will see how now the image issue has been fixed.


## Apps deployed during onboarding from Manifest in Gitea

As it happens with the Podman Quadlet applications that are deployed automatically thanks to a webhook in Gitea and EDA, all manifests located under `rhde/prod/rhde_config/microshift/manifests` will be automatically deployed in the device during the onboarding.

In the same way, if you add or modify any file there, that will trigger a new App deployment in the devices.


## Deploy an APP with Helm repo

Now we are going to deploy a new APP on Microshift using Helm, but keeping the variables in our Gitea.

  >**Note**
  >
  > In the case of Helm applications, there is no webhook configured to EDA, so if you wan to deploy the applications described in `rhde/prod/rhde_config/microshift/helm` you will need to manually launch the "Microshift APP Deploy - Helm" with the right variables.

In Gitea you can find under `rhde/prod/rhde_config/microshift/helm` the Helm variables used by an example `wordpress` APP. You can launch the deployment from AAP:

1. Open `rhde/prod/rhde_config/microshift/helm/wordpress/wordpress_vars.yml` where you will find the definition of the variables for a Helm Chart that deploys `Wordpress`.

2. If you want, you can change something in that file (ie. the `wordpressBlogName`), then launch manually the AAP Template "Microshift APP Deploy - Helm" to get installed the APP on the edge device

  >**Note**
  >
  > The Helm Chart repo (`https://raw.githubusercontent.com/luisarizmendi/helm-chart-repo/main/packages`) and Chart (the one that deploys `Wordpress`) are defined on the variables associated to the AAP Template. This is just an example for the demo, in production there might be better ways to do it, more if you use many different Helm Charts.

3. Wait until the PODs are running and show the APP at `http://wordpress-wordpress.apps.<edge device ip>.nip.io`






