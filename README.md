# Kubernetes on CenturyLink Cloud

These scripts will create a kubernetes cluster on CenturyLink Cloud.  

We use ansible to perform the cluster creation and we provide a simple bash wrapper script _kube-up.sh_ to simplify cluster management.  

## Clusters of VMs or Physical Servers, your choice. 

- We support Kubernetes clusters on both Virtual Machines or Physical Servers. If you want to use physical servers for the worker nodes (minions), simple use the --minion_type=bareMetal flag. 
- For more information on pyhsical servers, visit: https://www.ctl.io/bare-metal/)
- Physical serves are only available in the VA1 and GB3 data centers. 
- VMs are available in all 13 of our public cloud locations

## Requirements

- local installation of ansible _version 2.0_ or newer.  If on OSX, try installing with `brew install ansible`. 
- python and pip
- A CenturyLink Cloud account with rights to create new hosts

Getting ready:

Clone this repository and cd into it.
- `sudo pip install -r requirements.txt`
- `cd ansible`
- Create the credentials file from the template, and `source credentials.sh`


For example, here's a short set of commands for initializing an ansible master on Ubuntu 14:
```
  # system
  apt-get update
  apt-get install -y git python python-crypto
  curl -O https://bootstrap.pypa.io/get-pip.py
  python get-pip.py

  # git
  git config --global user.name User.Name
  git config --global user.email user@example.com
  git config --global credential.helper cache

  # installing this repository
  mkdir -p /home/development
  cd /home/development/
  git clone https://github.com/CenturyLinkCloud/adm-kubernetes-on-clc.git
  cd adm-kubernetes-on-clc/
  pip install -r requirements.txt

  # getting started
  cd ansible
  cp credentials.sh.template credentials.sh; vi credentials.sh
  source credentials.sh
```

## Cluster Creation 

The cluster creation uses ansible to create hosts and to install kubernetes. For convenience, a single shell script is used to carry out all of the tasks.

```
Usage: kube-up.sh [OPTIONS]
Create servers in the CenturyLinkCloud environment and initialize a Kubernetes cluster
Environment variables CLC_V2_API_USERNAME and CLC_V2_API_PASSWD must be set in
order to access the CenturyLinkCloud API

All options (both short and long form) require arguments, and must include "="
between option name and option value.

     -h (--help)                   display this help and exit
     -c= (--clc_cluster_name=)     set the name of the cluster, as used in CLC group names
     -t= (--minion_type=)          standard -> VM (default), bareMetal -> physical]
     -d= (--datacenter=)           VA1 (default)
     -m= (--minion_count=)         number of kubernetes minion nodes
     -mem= (--vm_memory=)          number of GB ram for each minion
     -cpu= (--vm_cpu=)             number of virtual cps for each minion node
     -phyid= (--server_conf_id=)   physical server configuration id, one of
                                      physical_server_20_core_conf_id
                                      physical_server_12_core_conf_id
                                      physical_server_4_core_conf_id (default)
     -etcd_separate_cluster=yes    create a separate cluster of three etcd nodes,
                                   otherwise run etcd on the master node
```
### Cluster Creation Examples

- Cluster name k8s_1, 1 master node and 3 worker minions (on physical machines), in VA1

```
 ./kube-up.sh --clc_cluster_name=k8s_1 --minion_type=bareMetal --minion_count=3 --datacenter=VA1
```

- Cluster name k8s_2, 1 master node, an ha etcd cluster on 3 VMs and 6 worker minions (on VMs), in VA1:

```
 ./kube-up.sh --clc_cluster_name=k8s_2 --minion_type=standard --minion_count=6 --datacenter=VA1 --etcd_separate_cluster=yes
```

- Cluster name k8s_3, 1 master node, and 10 worker minions (on VMs) with higher mem/cpu, in UC1:

```
 ./kube-up.sh --clc_cluster_name=k8s_3 --minion_type=standard --minion_count=10 --datacenter=VA1 -mem=6 -cpu=4
```

## Cluster Deletion

To delete a cluster, log into the CenturyLink Cloud control portal and delete the parent server group that contains the Kubernetes Cluster. We hope to add a scripted option to do this soon. 


## More about the ansible playbooks

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

This playbook can be used outside of the sxcript as well to install additional
applications.  There are templates in the role _kubernetes-manifest_ already
written for several applications.  These can be applied with the
_deploy_kube_applications.yml_ playbook (using the ansible json-syntax for
a command-line list)

```
app_list='{"k8s_apps":["guestbook-all-in-one","kube-ui"]}
ansible-playbook -i hosts-${CLC_CLUSTER_NAME}  -e ${app_list}  deploy_kube_applications.yml
```

## What Kubernetes features do not work on CenturyLink Cloud

- At this time, there is no support services of the type 'loadbalancer'. We are actively working on this and hope to publish the changes soon. 
- At this time, there is no support for persistent storage volumes provided by CenturyLink Cloud. However, customers can bring their pwn persistent storage offering.

## License

The project is licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
