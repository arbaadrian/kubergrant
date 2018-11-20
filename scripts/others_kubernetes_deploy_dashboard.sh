#!/bin/bash

## METHOD 1
kubectl apply -f /tmp/kubernetes-dashboard.yml
kubectl -n kube-system get service kubernetes-dashboard

# Manual
# kubectl -n kube-system edit service kubernetes-dashboard
# kubectl -n kube-system get service kubernetes-dashboard

# Create user for Dashboard admin access
kubectl apply -f /tmp/dashboard-adminuser.yml
kubectl apply -f /tmp/dashboard-adminuser-rbac.yml

# Print access token for said user
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# Access below URL with Mozilla and paste in the token (will not work with Chrome)
https://kube-master:31557

#######################################################################################################################################

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