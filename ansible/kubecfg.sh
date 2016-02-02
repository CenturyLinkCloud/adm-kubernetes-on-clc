export CLC_CLUSTER_NAME=k8s_dev2

export k8s_cluster=thursday
export k8s_user=admin
export k8s_ns=default

export master_ip=10.136.191.16

# set default kube config file location to local file kubecfg_${k8s_cluster}
OLDKUBECONFIG=${KUBECONFIG-~/.kube/config}
KUBECONFIG="$(pwd)/kubecfg_${k8s_cluster}"

# set cluster
kubectl config set-cluster ${k8s_cluster} \
   --server https://${master_ip}:6443 \
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


echo "# set cluster
kubectl config set-cluster ${k8s_cluster} \
   --server https://${master_ip}:6443 \
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
" >> setup-client.test

# test
kubectl cluster-info

export KUBECONFIG="${KUBECONFIG}:${OLDKUBECONFIG}"
