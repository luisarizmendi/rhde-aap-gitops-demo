# Building the APPs

If you want to make any change into the APPs, instead of copying the images from my Container Image Registry you can build them with the provided Containerfiles.

The images are based on Red Hat UBI base images, so you will need to have access to Red Hat Registry from your laptop. You can find information about [how to enable access to the registry in this KB article](https://access.redhat.com/RegistryAuthentication)

In order to make it easy (copy/paste the commands below), export these bash variables with your own values: 


```
export registry=<Registry and namespace | ie. quay.io/luisarizmendi >
export registry_username=<Registry Username | ie. luisarizmendi >
```



Then you will need to  be logged into your Registry:

```
podman login -u ${registry_username} ${registry}
```

Once you have access, make your changes and build the images 


```
cd 2048

buildah build -f Containerfile.v1 -t ${registry}/2048:v1 .
buildah build -f Containerfile.v2-error -t ${registry}/2048:v2 .
buildah build -f Containerfile.v3 -t ${registry}/2048:v3 .

podman push ${registry}/2048:v1
podman push ${registry}/2048:v2
podman push ${registry}/2048:v3

podman tag ${registry}/2048:v1 ${registry}/2048:prod
podman push ${registry}/2048:prod

cd ..

cd simple-http

buildah build -f Containerfile.v1 -t ${registry}/simple-http:v1 .
buildah build -f Containerfile.v2 -t ${registry}/simple-http:v2 .

podman push ${registry}/simple-http:v1
podman push ${registry}/simple-http:v2

podman tag ${registry}/simple-http:v1 ${registry}/simple-http:prod
podman push ${registry}/simple-http:prod

cd ..
```





