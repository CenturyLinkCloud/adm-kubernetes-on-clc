#/usr/bin/env bash


function exit_message() {
    echo "ERROR: $1" >&2
    exit 1
}

if [ -z ${CLC_CLUSTER_NAME+null_if_undefined} ]
then
  exit_message "please define environment variable CLC_CLUSTER_NAME"
fi

if [ ! -d ./ansible/${CLC_CLUSTER_NAME}.d ]
then
  exit_message "directory ./ansible/${CLC_CLUSTER_NAME}.d does not exist"
fi

if [ ! -e  ./ansible/hosts-${CLC_CLUSTER_NAME} ]
then
  exit_message "ansible file ./ansible/hosts-${CLC_CLUSTER_NAME} does not exist"
fi


### installing kubectl

KUBECTL=$(which kubectl)
if [ -z "$KUBECTL" ]
then
  version=v1.1.7
  arch=$(uname -s | tr '[:upper:]' '[:lower:]')  # linux|darwin
  url="https://storage.googleapis.com/kubernetes-release/release/${version}/bin/${arch}/amd64/kubectl"
  echo "No kubectl found, installing kubectl $version $arch to /usr/local/bin"
  curl -s -O $url
  chmod a+x kubectl
  mv kubectl /usr/local/bin
  KUBECTL=/usr/local/bin/kubectl
fi

echo kubectl binary is located at $KUBECTL
$KUBECTL version -c

### configuring kubectl
set -e

export K8S_CLUSTER=${K8S_CLUSTER-$CLC_CLUSTER_NAME}
export K8S_USER=${K8S_USER-admin}
export K8S_NS=${K8S_NS-default}
export CERT_DIR=./ansible/${CLC_CLUSTER_NAME}.d/k8s_certs

# extract master ip from hosts file
export MASTER_IP=$(grep -A1 master ./ansible/hosts-${CLC_CLUSTER_NAME} |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
export SECURE_PORT=6443

# set default kube config file location to local file kubecfg_${K8S_CLUSTER}
OLDKUBECONFIG=${KUBECONFIG-~/.kube/config}
export KUBECONFIG="$(pwd)/kubecfg_${K8S_CLUSTER}"

# set cluster
kubectl config set-cluster ${K8S_CLUSTER} \
   --server https://${MASTER_IP}:${SECURE_PORT} \
   --insecure-skip-tls-verify=false \
   --embed-certs=true \
   --certificate-authority=${CERT_DIR}/ca.crt

# user, credentials (reusing the kubelet/kube-proxy certificate)
kubectl config set-credentials ${K8S_USER}/${K8S_CLUSTER} \
   --embed-certs=true \
   --client-certificate=${CERT_DIR}/kubecfg.crt \
   --client-key=${CERT_DIR}/kubecfg.key

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
   --server https://${MASTER_IP}:${SECURE_PORT} \
   --insecure-skip-tls-verify=false \
   --embed-certs=true \
   --certificate-authority=${CERT_DIR}/ca.crt

# user, credentials (reusing the kubelet/kube-proxy certificate)
kubectl config set-credentials ${k8s_user}/${k8s_cluster} \
   --embed-certs=true \
   --client-certificate=${CERT_DIR}/kubecfg.crt \
   --client-key=${CERT_DIR}/kubecfg.key

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
