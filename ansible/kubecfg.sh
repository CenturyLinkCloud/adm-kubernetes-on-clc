#!/usr/bin/env bash
set -e


function exit_message() {
    echo "ERROR: $1" >&2
    exit 1
}


if [ -z ${CLC_CLUSTER_NAME+null_if_undefined} ]
then
  exit_message "please define environment variable CLC_CLUSTER_NAME"
fi

if [ ! -d ${CLC_CLUSTER_NAME}.d ]
then
  exit_message "directory ${CLC_CLUSTER_NAME}.d does not exist"
fi

if [ ! -e  hosts-${CLC_CLUSTER_NAME} ]
then
  exit_message "ansible file hosts-${CLC_CLUSTER_NAME} does not exist"
fi

export K8S_CLUSTER=${K8S_CLUSTER-$CLC_CLUSTER_NAME}
export K8S_USER=${K8S_USER-admin}
export K8S_NS=${K8S_NS-default}

# extract master ip from hosts file
export MASTER_IP=$(grep -A1 master hosts-${CLC_CLUSTER_NAME} |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

# set default kube config file location to local file kubecfg_${K8S_CLUSTER}
OLDKUBECONFIG=${KUBECONFIG-~/.kube/config}
export KUBECONFIG="$(pwd)/kubecfg_${K8S_CLUSTER}"

# set cluster
kubectl config set-cluster ${K8S_CLUSTER} \
   --server https://${MASTER_IP}:6443 \
   --insecure-skip-tls-verify=false \
   --embed-certs=true \
   --certificate-authority=${CLC_CLUSTER_NAME}.d/k8s_certs/ca.crt

# user, credentials (reusing the kubelet/kube-proxy certificate)
kubectl config set-credentials ${K8S_USER}/${K8S_CLUSTER} \
   --embed-certs=true \
   --client-certificate=${CLC_CLUSTER_NAME}.d/k8s_certs/kubecfg.crt \
   --client-key=${CLC_CLUSTER_NAME}.d/k8s_certs/kubecfg.key

# define context
kubectl config set-context ${K8S_NS}/${K8S_CLUSTER}/${K8S_USER} \
    --user=${K8S_USER}/${K8S_CLUSTER} \
    --namespace=${K8S_NS} \
    --cluster=${K8S_CLUSTER} \

# apply
kubectl config use-context ${K8S_NS}/${K8S_CLUSTER}/${K8S_USER}


cat << EOF > setup-client.test
# set cluster
kubectl config set-cluster ${k8s_cluster} \
   --server https://${MASTER_IP}:6443 \
   --insecure-skip-tls-verify=false \
   --embed-certs=true \
   --certificate-authority=${CLC_CLUSTER_NAME}.d/k8s_certs/ca.crt

# user, credentials (reusing the kubelet/kube-proxy certificate)
kubectl config set-credentials ${k8s_user}/${k8s_cluster} \
   --embed-certs=true \
   --client-certificate=${CLC_CLUSTER_NAME}.d/k8s_certs/kubecfg.crt \
   --client-key=${CLC_CLUSTER_NAME}.d/k8s_certs/kubecfg.key

# define context
kubectl config set-context ${k8s_ns}/${k8s_cluster}/${k8s_user} \
    --user=${k8s_user}/${k8s_cluster} \
    --namespace=${k8s_ns} \
    --cluster=${k8s_cluster} \

# apply
kubectl config use-context ${k8s_ns}/${k8s_cluster}/${k8s_user}
EOF

# test
kubectl cluster-info

echo export KUBECONFIG="${KUBECONFIG}:${OLDKUBECONFIG}"
