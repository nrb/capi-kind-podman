# Setup script for Cluster API via kind and Podman

This script will create and configure a kind cluster named `capi`, backed by Podman, for use with [Cluster API's `Tiltfile`](https://github.com/kubernetes-sigs/cluster-api/blob/main/Tiltfile).
It is specifically written for macOS, where Podman configuration must be changed on the Podman virtual machine.

Code heavily borrowed from https://github.com/fishpercolator/silverblue-tilt and the original [blog post](https://medium.com/@fishpercolator/using-tilt-kubernetes-podman-to-get-a-dev-environment-on-silverblue-without-running-anything-1a6ef7de07ee)

## Running

At the moment, the script takes no options - just run it:

```
create-capi-kind-cluster.sh
```

It will:

1. Create a local registry container and enable HTTP push/pull for Podman within the Podman VM. Without this, `podman push` will fail due to using HTTPS by default.
2. Create a Kind control plane container and set up redirection so that `localhost:5001` will map to the registry container and port.
3. Attach the registry container to the `kind` podman network so that `kind` and the registry can communicate.
