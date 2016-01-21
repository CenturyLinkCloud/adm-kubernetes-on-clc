#!/bin/sh
#
# deploy k8s cluster on clc
# 
# Examples: 
# 
# Make a cluster with default values:
# > bash kube-up.sh 
# 
# Make a cluster with custom values (cluster of VMs)
# > bash kube-up.sh --clc_cluster_name=k8s_vm101 --minion_type=vm --minion_count=6 --datacenter=WA1 --vm_memory=4 --vm_cpu=2
#
# Make a cluster with custom values (cluster of physical servers)
# > bash kube-up.sh --clc_cluster_name=k8s_vm101 --minion_type=bareMetal --minion_count=4 --datacenter=VA1 
#

extra_args="from_bash=true"

for i in "$@"
do
case $i in
    -c=*|--clc_cluster_name=*)
    clc_cluster_name="${i#*=}"
    extra_args="$extra_args clc_cluster_name=$clc_cluster_name"
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
    extra_args="$extra_args server_conf_id=$server_conf_id"    
    shift # past argument=value
    ;;        
        
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done


echo "Creating Kubernetes Cluster on CenturyLink Cloud"
echo ""

#echo "cluster_name  = ${cluster_name}"
#echo "minion_count     = ${minion_count}"
#echo "server_type    = ${server_type}"
#
#echo "Extra Args   : ${extra_args}"
#echo "ansible-playbook -i /usr/local/bin/clc_inv.py kubernetes-describe-cluster.yml $extra_args"



    

#### Part1a 
echo "Part1a -  Building out the infrastructure on CLC"
{ ansible-playbook create-master-hosts.yml -e "$extra_args"; } &
{ ansible-playbook create-etcd-hosts.yml -e "$extra_args"; } &
{ ansible-playbook create-minion-hosts.yml -e "$extra_args"; } &
wait

#### Part1b 
echo "Part1b -  create hosts file"
{ ansible-playbook create-hosts-file.yml -e "$extra_args"; } &
wait

#### Part2 
echo "Part2 - Setting up etcd"
{ ansible-playbook -i hosts-$clc_cluster_name install_etcd.yml; } &
wait

#### Part3 
echo "Part3 - Setting up kubernetes"
{ ansible-playbook -i hosts-$clc_cluster_name install_kubernetes.yml; } &
wait


#### Part X - Running test phase and displaying cluster info
#echo "Starting testing Phase"
#{ ansible-playbook -i /usr/local/bin/clc_inv.py kubernetes-describe-cluster.yml -e "$extra_args"; } &
#wait



echo "      Output of 'kubectl cluster-info' on master server"
echo ""
#cat /tmp/$cluster_name
echo ""

echo "All done. Try out your k8 cluster today! -ck"
echo "> kubectl get nodes"
echo "> kubectl cluster-info"
