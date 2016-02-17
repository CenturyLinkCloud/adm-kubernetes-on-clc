
## More about the ansible playbooks

For those interested in the ansible files themselves, here is a little more information about them.

### Creating virtual hosts (part 1)

Three playbooks are used to create hosts
- create-etcd-hosts.yml
- create-minion-hosts.yml
- create-master-hosts.yml

Each of these playbooks uses the _clc_provisioning_ role, runs on localhost and
makes http calls to the CenturyLink Cloud API.

### Provisioning the cluster (parts 2-4)

#### Installing etcd

In part 2, the _kube-up.sh_ script calls a playbook to install etcd.

`ansible-playbook -i hosts-${CLC_CLUSTER_NAME} install_etcd.yml -e ${extra_args}`


#### Installing Kubernetes

In part 3, the _kube-up.sh_ script calls a playbook to install kubernetes, with
differerent configurations for the master and minion nodes.

`ansible-playbook -i hosts-${CLC_CLUSTER_NAME} install_kubernetes.yml -e ${extra_args}`

#### Running Kubernetes applications

In part 4, the _kube-up.sh_ script calls a playbook to deploy some of the standard
addons

This playbook can be used outside of the script as well to install additional
applications.  There are templates in the role _kubernetes-manifest_ already
written for several applications.  These can be applied with the
_deploy_kube_applications.yml_ playbook (using the ansible json-syntax for
a command-line list)

```
app_list='{"k8s_apps":["guestbook-all-in-one","kube-ui"]}
ansible-playbook -i hosts-${CLC_CLUSTER_NAME}  -e ${app_list}  deploy_kube_applications.yml
```
