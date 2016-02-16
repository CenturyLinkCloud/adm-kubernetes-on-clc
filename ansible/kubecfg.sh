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

CLC_CLUSTER_HOME=${HOME}/.clc_kube/${CLC_CLUSTER_NAME}

if [ ! -d ${CLC_CLUSTER_HOME} ]
then
  exit_message "directory ${CLC_CLUSTER_HOME} does not exist"
fi

HOSTS=${CLC_CLUSTER_HOME}/hosts/inventory
if [ ! -e  ${HOSTS} ]
then
  exit_message "ansible file ${HOSTS} does not exist"
fi

PKI=${CLC_CLUSTER_HOME}/pki
if [ ! -d  ${PKI} ]
then
  exit_message "public key infrastructure directory ${PKI} does not exist"
fi

K8S_CLUSTER=${K8S_CLUSTER-$CLC_CLUSTER_NAME}
K8S_USER=${K8S_USER-admin}
K8S_NS=${K8S_NS-default}

# extract master ip from hosts file
export MASTER_IP=$(grep -A1 master ${HOSTS} | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

# set default kube config file location to local file kubecfg_${K8S_CLUSTER}
OLDKUBECONFIG=${KUBECONFIG-~/.kube/config}
export KUBECONFIG="$(pwd)/kubecfg_${K8S_CLUSTER}"

# set cluster
kubectl config set-cluster ${K8S_CLUSTER} \
   --server https://${MASTER_IP}:6443 \
   --insecure-skip-tls-verify=false \
   --embed-certs=true \
   --certificate-authority=${PKI}/ca.crt

# user, credentials (reusing the kubelet/kube-proxy certificate)
kubectl config set-credentials ${K8S_USER}/${K8S_CLUSTER} \
   --embed-certs=true \
   --client-certificate= ${PKI}/kubecfg.crt \
   --client-key= ${PKI}/kubecfg.key

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
   --certificate-authority=${PKI}/ca.crt

# user, credentials (reusing the kubelet/kube-proxy certificate)
kubectl config set-credentials ${k8s_user}/${k8s_cluster} \
   --embed-certs=true \
   --client-certificate=${PKI}/kubecfg.crt \
   --client-key=${PKI}/kubecfg.key

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
