#!/bin/zsh
# Taken from https://github.com/fishpercolator/silverblue-tilt and modified for macOS.
# Original repo assumes podman's living on the Linux host, whereas this version uses the podman VM

# Registry container name
reg_name='kind-registry'
# Port registered on macOS. Still 5000 w/in the container
reg_port='5001'
# Name for the kind cluster
cluster_name='capi-test'

insecure_calls () {
    # Tell podman (within the podman VM) that it should connect w/o HTTPS
    # https://github.com/kubernetes-sigs/kind/issues/3468#issuecomment-2353668763
    read -r -d '' registry_conf <<EOF
[[registry]]
location = "localhost:${reg_port}"
insecure = true
EOF
    podman machine ssh --username=root sh -c 'cat > /etc/containers/registries.conf.d/local.conf' <<<$registry_conf
}

create_registry_container () {
    # Make the registry container if it's not already running
    case $(podman inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true) in
    false)
      echo "Starting previously configured registry..."
      podman start ${reg_name}
      ;;
    true)
      echo "Registry is already running"
      ;;
    *)
      echo "Creating registry..."
      podman run \
        -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" \
        registry:2
      ;;
    esac
}

create_kind_cluster () {
    case $(podman inspect -f '{{.State.Running}}' ${cluster_name}-control-plane 2>/dev/null || true) in
  false)
    echo "Starting previously configured cluster..."
    podman start ${cluster_name}-control-plane
    ;;
  true)
    echo "Cluster is already running"
    ;;
  *)
    echo "Creating Kubernetes cluster..."
    # Add this patch config until https://github.com/kubernetes-sigs/kind/issues/2875 is resolved
    # One more patch to expose /dev https://github.com/kubernetes-sigs/kind/issues/3389#issuecomment-1784159342
    cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
nodes:
- role: control-plane
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF
    ;;
  esac
  # Now check it's the current kube context on the system
  kube_context=$(kubectl config current-context)
  if [ "$kube_context" != "kind-${cluster_name}" ]; then
    echo "Current context is not right (it's ${kube_context})"
    exit 1
  fi
}

configure_networking () {
    # Tell the kind control plane nodes that they have to reference the container $reg_name when trying to access localhost:$reg_port
    REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
    for node in $(kind --name ${cluster_name} get nodes); do
      podman exec "${node}" mkdir -p "${REGISTRY_DIR}"
      cat <<EOF | podman exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
    done
    
    # Connect the registry container to kind's network if it's not already.
    if [ -z $(podman network inspect kind | jq '.[].containers[].name' | grep "${reg_name}") ]; then
        podman network connect "kind" "kind-registry"
    else
        echo "Network already attached"
    fi
}

insecure_calls
create_registry_container
create_kind_cluster
configure_networking
