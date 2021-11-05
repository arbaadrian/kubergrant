#!/bin/bash

#############
## INGRESS ##
#############

kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set rbac.create=true

# we have to edit he validation webhook config to allow creation of ingresses for all resources otherwise ingress creations will fail
kubectl get ValidatingWebhookConfiguration ingress-nginx-admission -oyaml > ingress-nginx-admission.yaml
sed -i 's/networking.k8s.io/\"\"/' ingress-nginx-admission.yaml
kubectl apply -f ingress-nginx-admission.yaml

###############
### CHEESES ###
###############

kubectl apply -f /vagrant/files/cheeses/

###############
## DASHBOARD ##
###############

## METHOD 1
kubectl apply -f /vagrant/files/dashboard/kubernetes-dashboard.yml
kubectl get service kubernetes-dashboard -n kube-system
### The following line will add the dashboard to the cluster info
kubectl label services kubernetes-dashboard kubernetes.io/cluster-service=true -n kube-system

# Create user for Dashboard admin access
kubectl apply -f /vagrant/files/dashboard/dashboard-adminuser.yml
kubectl apply -f /vagrant/files/dashboard/dashboard-adminuser-rbac.yml

# Print access token for said user
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# Access below URL with Mozilla and paste in the token (will not work with Chrome)
# https://controlplane:31557

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

#################
## Other stuff ##
#################

# Label your worker node (from the controlplane)
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
# kubectl get pods -l key=value -o jsonpath={.items[*].spec.containers[*].name} -n <namespace>      # print containers in a pod
# docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike 53e68464f13a      # pulls an image that shows me what's running in my container
# kubectl exec -it <pod_name> -n <namespace> -- <commands>

## HELM
# helm install stable/heapster                                                      # install a release
# helm install --name my-release stable/heapster                                    # install a release and give it a name
# helm ls --all --short                                                             # show all releases deployed with helm
# helm delete quoting-swan --purge                                                  # delete a release

#################
## ROOK & CEPH ##
#################

# cd /tmp
# git clone https://github.com/rook/rook.git
# kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/operator.yaml
# kubectl create -f /tmp/ceph-cluster.yml
# kubectl create -f /tmp/ceph-dashboard-nodeip.yml

  # to get the password for the ceph 'admin' user
# echo -e "export CEPH_DASHBOARD=$(kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo)" >> /tmp/vars
# source /tmp/vars
# echo $CEPH_DASHBOARD

  ### Print cluster info on screen
kubectl cluster-info

################
## ROOK, CEPH ##
################

# cd /tmp
# git clone https://github.com/rook/rook.git
# kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/operator.yaml
# kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/cluster.yaml
# kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/storageclass.yaml
#   # this is a patch for storageclass
# kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/toolbox.yaml
#   # check if toolbox pod is up
# kubectl -n rook-ceph get pod -l "app=rook-ceph-tools"
#   # get into toolbox pod and run commands to see the ceph cluster info
# kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
#     ceph status
#     ceph osd status
#     ceph df
#     rados df
#   # to remove toolbox: kubectl -n rook-ceph delete deployment rook-ceph-tools
# sudo yum install -y xfsprogs
