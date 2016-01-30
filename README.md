# Kubernetes on CenturyLink Cloud

This tool handles kubernetes cluster creation on CenturyLink Cloud.  

We choose to use ansible to perform the cluster creation and we have also provided a simple bash wrapper script _kube-up.sh_ to simplify cluster management. 

## Find Help

If you run into any problems or want help with anything, we are here to help. Reach out to use via any of the following ways:

- Submit a github issue
or
- Send an email to kubernetes@ctl.io (registering your email with CenturyLink Cloud will be required)


## Clusters of VMs or Physical Servers, your choice. 

- We support Kubernetes clusters on both Virtual Machines or Physical Servers. If you want to use physical servers for the worker nodes (minions), simple use the --minion_type=bareMetal flag. 
- For more information on pyhsical servers, visit: https://www.ctl.io/bare-metal/)
- Physical serves are only available in the VA1 and GB3 data centers. 
- VMs are available in all 13 of our public cloud locations

## Requirements

The requirements to run this script are:

- A linux host (tested on ubuntu and OSX)
- ansible _version 2.0_ or newer.  If on OSX, try installing with `brew install ansible`. 
- python 
- pip
- git
- A CenturyLink Cloud account with rights to create new hosts
- An active VPN connection to the centurylink cloud from your linux/ansible host

## Script Installation

After you have all the requirements met, please follow these instructions to install this script. 

1) Clone this repository and cd into it.
``` 
git clone https://github.com/CenturyLinkCloud/adm-kubernetes-on-clc 
```

2) Install the CenturyLink Cloud SDK and Ansible Modules
```
sudo pip install -r requirements.txt
```

3) Create the credentials file from the template and use it to set your ENV variables

``` 
cp ansible/credentials.sh.template ansible/credentials.sh
vi ansible/credentials.sh
source ansible/credentials.sh
```

#### Ubuntu 14  Walkthrough: Installation of Requirements and Scripts

If you use ubuntu 14, for your convenouce we have provided a step by step guide to install the requirements and install the script.

```
  # system
  apt-get update
  apt-get install -y git python python-crypto
  curl -O https://bootstrap.pypa.io/get-pip.py
  python get-pip.py

  # installing this repository
  mkdir -p ~home/k8s-on-clc
  cd ~home/k8s-on-clc
  git clone https://github.com/CenturyLinkCloud/adm-kubernetes-on-clc.git
  cd adm-kubernetes-on-clc/
  pip install -r requirements.txt

  # getting started
  cd ansible
  cp credentials.sh.template credentials.sh; vi credentials.sh
  source credentials.sh
```

## Cluster Creation 

To create a new Kubernetes cluster, simply run the kube-up.sh script. A complete list of script options and some examples are listed below.

``` 
cd ./adm-kubernetes-on-clc/ansible
bash kube-up.sh
```

#### Script Options
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
#### Script Examples

Create a cluster with name of k8s_1, 1 master node and 3 worker minions (on physical machines), in VA1

```
 bash kube-up.sh --clc_cluster_name=k8s_1 --minion_type=bareMetal --minion_count=3 --datacenter=VA1
```
Create a cluster with name of k8s_2, an ha etcd cluster on 3 VMs and 6 worker minions (on VMs), in VA1

```
 bash kube-up.sh --clc_cluster_name=k8s_2 --minion_type=standard --minion_count=6 --datacenter=VA1 --etcd_separate_cluster=yes
```
Create a cluster with name of k8s_3, 1 master node, and 10 worker minions (on VMs) with higher mem/cpu, in UC1:


```
  bash kube-up.sh --clc_cluster_name=k8s_3 --minion_type=standard --minion_count=10 --datacenter=VA1 -mem=6 -cpu=4
```

## Cluster Deletion

To delete a cluster, log into the CenturyLink Cloud control portal and delete the parent server group that contains the Kubernetes Cluster. We hope to add a scripted option to do this soon. 


## What Kubernetes features do not work on CenturyLink Cloud

- At this time, there is no support services of the type 'loadbalancer'. We are actively working on this and hope to publish the changes soon. 
- At this time, there is no support for persistent storage volumes provided by CenturyLink Cloud. However, customers can bring their pwn persistent storage offering.

## Ansible Files

If you want more information about our ansible files, please [read this file](ansible/README.md)


## License

The project is licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
