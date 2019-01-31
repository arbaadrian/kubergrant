#!/bin/bash

###############
## DASHBOARD ##
###############

## METHOD 1
kubectl apply -f /tmp/kubernetes-dashboard.yml
kubectl get service kubernetes-dashboard -n kube-system
### The following line will add the dashboard to the cluster info
kubectl label services kubernetes-dashboard kubernetes.io/cluster-service=true -n kube-system

# Manual
# kubectl -n kube-system edit service kubernetes-dashboard
# kubectl -n kube-system get service kubernetes-dashboard

# Create user for Dashboard admin access
kubectl apply -f /tmp/dashboard-adminuser.yml
kubectl apply -f /tmp/dashboard-adminuser-rbac.yml

# Print access token for said user
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# Access below URL with Mozilla and paste in the token (will not work with Chrome)
https://master:31557



## METHOD 2
## Deploy Dashboard - reference: https://github.com/kubernetes/dashboard/wiki/Creating-sample-user
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
# kubectl get pod -n kube-system | grep dashboard

# nohup kubectl proxy >/dev/null 2>&1 &

# NOT WORKING:
# echo -e "kubectl proxy" > /tmp/kubectl_proxy.sh
# chmod +x /tmp/kubectl_proxy.sh
# echo -e "[Unit]
# Description=Description for sample script goes here
# After=network.target

# [Service]
# Type=simple
# ExecStart=/tmp/kubectl-proxy.sh
# TimeoutStartSec=0

# [Install]
# WantedBy=default.target" > /etc/systemd/system/kubectl-proxy.service
# systemctl daemon-reload
# systemctl enable kubectl-proxy
# systemctl start kubectl-proxy

## You have to do 3 manual steps:
# on your local machine, run command ssh -L 8001:localhost:8001 <your_user>@127.0.0.1 -p <vagrant_assigned_port>
# navigate with browser to http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
# choose Token authentication and insert token from above commands

#######################################################################################################################################
#######################################################################################################################################

#########
## ELK ##
#########

cd /tmp
kubectl apply -f persistent-volume-elk-01.yml
kubectl apply -f persistent-volume-elk-02.yml
tar -zxvf elk_01_k8s_global.tar.gz
tar -zxvf elk_02_elasticsearch.tar.gz
tar -zxvf elk_03_kibana.tar.gz
tar -zxvf elk_04_beats_init.tar.gz
tar -zxvf elk_05_beats_agents.tar.gz
kubectl apply -f elk_01_k8s_global
kubectl apply -f elk_02_elasticsearch
kubectl apply -f elk_03_kibana
kubectl apply -f elk_04_beats_init
kubectl apply -f elk_05_beats_agents
git clone https://github.com/kubernetes/kube-state-metrics.git
kubectl apply -f kube-state-metrics/kubernetes

http://master:31558

#################
## Other stuff ##
#################

# Label your worker node (from the master)
# kubectl label node <nodename> node-role.kubernetes.io/<role>=<role>

# delete deployment
# kubectl get pods --all-namespaces                                                 # get the namespace
# kubectl get deployment --namespace <namespace>                                    # get deployment name
# kubectl delete deployment <deployment> --namespace <namespace>                    # delete deployment with pods
# kubectl delete pod <pod> --namespace <nmespace>                                   # delete a pod
# kubectl get statefulsets --all-namespaces                                         # show all statefulsets
# kubectl delete statefulsets <statefulsets> --namespace=<namespace>                # delete a statefulset
# kubectl get services --all-namespaces                                             # show all services
# kubectl delete services <s1> <s2> --namespace <namespace>                         # delete services
# kubectl get pv --all-namespaces                                                   # show all persistent volumes
# kubectl get pvc --all-namespaces                                                  # show all persistent volume claims
# kubectl delete pvc <pvc> -n <namespace>                                           # delete persistent volume claims
# kubectl delete namespaces <namespace>                                             # deletes a namespace
# kubectl get services kubernetes-dashboard -n kube-system --show-labels -o wide    # show the labels of a particular service

### Print cluster info on screen
kubectl cluster-info