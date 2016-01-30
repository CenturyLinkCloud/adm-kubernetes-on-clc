
if [ -z ${CLC_CLUSTER_NAME+null_if_undefined}]
  then echo please define environment variable CLC_CLUSTER_NAME
  exit 1
fi

export K8S_CLUSTER=${K8S_CLUSTER-$CLC_CLUSTER_NAME}
export K8S_USER=${K8S_USER-admin}
export K8S_NS=${K8S_NS-default}

export master_ip=10.141.117.12

# set default kube config file location to local file kubecfg_${K8S_CLUSTER}
OLDKUBECONFIG=${KUBECONFIG-~/.kube/config}
export KUBECONFIG="$(pwd)/kubecfg_${K8S_CLUSTER}"

# set cluster
kubectl config set-cluster ${K8S_CLUSTER} \
   --server https://${master_ip}:6443 \
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

# test
kubectl cluster-info

export KUBECONFIG="${KUBECONFIG}:${OLDKUBECONFIG}"
