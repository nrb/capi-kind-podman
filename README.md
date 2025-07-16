# Setup script for Cluster API via kind and Podman

This script will create and configure a kind cluster named `capi-test`, backed by Podman, for use with [Cluster API's `Tiltfile`](https://github.com/kubernetes-sigs/cluster-api/blob/main/Tiltfile).
It is specifically written for macOS, where Podman configuration must be changed on the Podman virtual machine.
An example of a tilt-settings.json file is provided.

Code heavily borrowed from https://github.com/fishpercolator/silverblue-tilt and the original [blog post](https://medium.com/@fishpercolator/using-tilt-kubernetes-podman-to-get-a-dev-environment-on-silverblue-without-running-anything-1a6ef7de07ee)

## Prerequisites

1. Podman's [Docker compatibility](https://podman-desktop.io/docs/migrating-from-docker/managing-docker-compatibility)
2. Make the `docker` command a symlink to `$(which podman)`. An alias in your shell profile isn't sufficient.

## Running

At the moment, the script takes no options - just run it:

```shell
create-capi-kind-cluster.sh
```

It will:

1. Create a local registry container and enable HTTP push/pull for Podman within the Podman VM. Without this, `podman push` will fail due to using HTTPS by default.
2. Create a Kind control plane container and set up redirection so that `localhost:5001` on the host will map to the registry container and port.
3. Upload a ConfigMap called `local-registry-hosting` documenting the location of the local registry in the `kube-public` namespace.
4. Attach the registry container to the `kind` podman network so that `kind` and the registry can communicate.

## Cleaning up

To delete the `capi-test` kind cluster and the local registry container


```shell
teardown-capi-kind-cluster.sh
```
