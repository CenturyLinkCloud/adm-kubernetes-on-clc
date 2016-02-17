#!/bin/sh
set -e
# deploy k8s cluster on clc
#
# Examples:
#
# Make a cluster with default values:
# > bash kube-up.sh
#
# Make a cluster with custom values (cluster of VMs)
# > bash kube-up.sh --clc_cluster_name=k8s_vm101 --minion_type=standard --minion_count=6 --datacenter=VA1 --vm_memory=4 --vm_cpu=2
#
# Make a cluster with custom values (cluster of physical servers)
# > bash kube-up.sh --clc_cluster_name=k8s_vm101 --minion_type=bareMetal --minion_count=4 --datacenter=VA1
#
# Make a cluster with custom values (cluster of VMs with a separate cluster of etcd nodes)
# > bash kube-up.sh --clc_cluster_name=k8s_vm101 --minion_type=standard --minion_count=6 --datacenter=VA1 --etcd_separate_cluster
#

# Usage info
function show_help() {
cat << EOF
Usage: ${0##*/} [OPTIONS]
Create servers in the CenturyLinkCloud environment and initialize a Kubernetes cluster
Environment variables CLC_V2_API_USERNAME and CLC_V2_API_PASSWD must be set in
order to access the CenturyLinkCloud API

Most options (both short and long form) require arguments, and must include "="
between option name and option value.  _--help_ and _--etcd_separate_cluster_ do
not take arguments

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
     --etcd_separate_cluster       create a separate cluster of three etcd nodes,
                                   otherwise run etcd on the master node
EOF
}

function exit_message() {
    echo "ERROR: $1" >&2
    exit 1
}

extra_args="from_bash=true"

for i in "$@"
do
case $i in
    -h|--help)
    show_help && exit 0
    shift # past argument=value
    ;;
    -c=*|--clc_cluster_name=*)
    CLC_CLUSTER_NAME="${i#*=}"
    extra_args="$extra_args clc_cluster_name=$CLC_CLUSTER_NAME"
    shift # past argument=value
    ;;
    -t=*|--minion_type=*)
    minion_type="${i#*=}"
    extra_args="$extra_args minion_type=$minion_type"
    shift # past argument=value
    ;;
    -d=*|--datacenter=*)
    datacenter="${i#*=}"
    extra_args="$extra_args datacenter=$datacenter"
    shift # past argument=value
    ;;
    -m=*|--minion_count=*)
    minion_count="${i#*=}"
    extra_args="$extra_args minion_count=$minion_count"
    shift # past argument=value
    ;;
    -mem=*|--vm_memory=*)
    vm_memory="${i#*=}"
    extra_args="$extra_args vm_memory=$vm_memory"
    shift # past argument=value
    ;;
    -cpu=*|--vm_cpu=*)
    vm_cpu="${i#*=}"
    extra_args="$extra_args vm_cpu=$vm_cpu"
    shift # past argument=value
    ;;

    -phyid=*|--server_conf_id=*)
    server_conf_id="${i#*=}"
    extra_args="$extra_args server_config_id=$server_conf_id"
    shift # past argument=value
    ;;

    --etcd_separate_cluster*)
    # the ansible variable "etcd_group" has default value "master"
    etcd_separate_cluster=yes
    extra_args="$extra_args etcd_group=etcd"
    shift # past argument with no value
    ;;

    *)
    echo "Unknown option: $1"
    echo
    show_help
  	exit 1
    ;;

esac
done

if [ -z ${CLC_V2_API_USERNAME:-} ] || [ -z ${CLC_V2_API_PASSWD:-} ]
  then
  exit_message 'Environment variables CLC_V2_API_USERNAME, CLC_V2_API_PASSWD must be set'
fi

if [ -z ${CLC_CLUSTER_NAME} ]
  then
  exit_message 'Cluster name must be set with either command-line argument or as environment variable CLC_CLUSTER_NAME'
fi

cd ansible

CLC_CLUSTER_HOME=~/.clc_kube/${CLC_CLUSTER_NAME}

mkdir -p ${CLC_CLUSTER_HOME}/hosts
hosts_file=${CLC_CLUSTER_HOME}/hosts/inventory

if [ -e $hosts_file ]
then
  echo "hosts file $hosts_file already exists, skipping host creation"
else

  echo "Creating Kubernetes Cluster on CenturyLink Cloud"
  echo ""

  #echo "cluster_name  = ${cluster_name}"
  #echo "minion_count     = ${minion_count}"
  #echo "server_type    = ${server_type}"
  #echo "etcd_separate_cluster    = ${etcd_separate_cluster}"

  # echo "Extra Args   : ${extra_args}"
  # echo "ansible-playbook -i /usr/local/bin/clc_inv.py kubernetes-describe-cluster.yml $extra_args"

  #### Part0
  echo "Part0a - Create local sshkey if necessary"
  ansible-playbook create-local-sshkey.yml -e server_cert_store=${CLC_CLUSTER_HOME}/ssh

  echo "Part0b - Create parent group"
  ansible-playbook create-parent-group.yml -e "$extra_args"

  #### Part1a
  # background these in order to run them in parallel
  pids=""
  echo "Part1a -  Building out the infrastructure on CLC"
  { ansible-playbook create-master-hosts.yml -e "$extra_args"; } &
  pids="$pids $!"
  { ansible-playbook create-minion-hosts.yml -e "$extra_args"; } &
  pids="$pids $!"
  if [ -z ${etcd_separate_cluster+x} ]; then
    echo "ETCD will be installed on master server"
  else
    echo "ETCD will be installed on 3 separate VMs not part of k8s cluster"
    { ansible-playbook create-etcd-hosts.yml -e "$extra_args"; } &
    pids="$pids $!"
  fi

  # -----------------------------------------------------
  # a _wait_ checkpoint to make sure these CLC hosts were
  # created safely, exiting if there were problems
  # -----------------------------------------------------
  set +e
  failed=0
  ps $pids
  for pid in $pids
  do
    wait $pid
    exit_val=$?
    if [ $exit_val != 0 ]
    then
      echo "process $pid failed with exit value $exit_val"
      failed=$exit_val
    fi
  done

  if [ $failed != 0 ]
  then
    exit $failed
  fi
  set -e
  # -----------------------------------------------------

  #### Part1b
  echo "Part1b -  create hosts file"
  ansible-playbook create-hosts-file.yml -e "$extra_args"

fi # checking [ -e $hosts_file ]

#### verify access
ansible -i $hosts_file   -m shell -a uptime all

#### Part2
echo "Part2 - Setting up etcd"
#install etcd on master or on separate cluster of vms
ansible-playbook -i $hosts_file  install_etcd.yml -e "$extra_args"

#### Part3
echo "Part3 - Setting up kubernetes"
ansible-playbook -i $hosts_file install_kubernetes.yml -e "$extra_args"

#### Part4
echo "Part4 - Installing standard addons"
standard_addons='{"k8s_apps":["skydns","kube-ui","monitoring"]}'
ansible-playbook -i $hosts_file deploy_kube_applications.yml -e ${standard_addons}

cat <<MESSAGE

Cluster build is complete. To administer the cluster, install and configure
kubectl with

  export CLC_CLUSTER_NAME=$CLC_CLUSTER_NAME
  ./install-kubectl.sh

MESSAGE
