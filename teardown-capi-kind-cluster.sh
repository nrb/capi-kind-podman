#!/bin/zsh
kind delete cluster --name capi-test
podman container rm -f kind-registry && echo "Deleted kind-registry container"
