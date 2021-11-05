#!/bin/bash

#############
## INGRESS ##
#############

kubectl create namespace ingress
kubectl create -f /tmp/default-backend-deployment.yaml -n ingress
kubectl create -f /tmp/default-backend-service.yaml -n ingress
kubectl create -f /tmp/nginx-ingress-controller-config-map.yaml -n ingress
kubectl create -f /tmp/nginx-ingress-controller-roles.yaml -n ingress
kubectl create -f /tmp/nginx-ingress-controller-deployment.yaml -n ingress
kubectl create -f /tmp/nginx-ingress.yaml -n ingress
kubectl create -f /tmp/nginx-ingress-controller-service.yaml -n ingress


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
https://control_plane:31557



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

http://control_plane:31558

#################
## Other stuff ##
#################

# Label your worker node (from the control_plane)
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
echo -e "export CEPH_DASHBOARD=$(kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo)" >> /tmp/vars
source /tmp/vars
echo $CEPH_DASHBOARD

  ### Print cluster info on screen
kubectl cluster-info

  ## Start an ingress and add an application
helm install --name apps-ingresses stable/nginx-ingress --set rbac.create=true
  # here, we have to expose the port that is opened in vagrant to a port inside kubernetes (example for Dashboard)
# kubectl edit svc apps-ingresses-nginx-ingress-controller
# (...)
# spec
#   ports:
#   - name: http-mgmt
#     nodePort: 31557
#     port: 18080
#     protocol: TCP
#     targetPort: 18080
# (...)

kubectl edit deployments apps-ingresses-nginx-ingress-controller
  # here, we have to add the port that the application will live at
(...)
spec:
  template:
    spec:
      containers:
        ports:
        - containerPort: 18080
          protocol: TCP
(...)

  # now we will add an ingress for nginx, it will return a few nginx details when accessed like so http://control_plane:31557/nginx_status (or IP)
cat > /tmp/nginx-ingress.yaml <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: control_plane
    http:
      paths:
      - backend:
          serviceName: nginx-ingress
          servicePort: 18080
        path: /nginx_status
EOF
kubectl create -f /tmp/nginx-ingress.yaml

  # for apps - none yet
cat > /tmp/app-ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: app-ingress
spec:
  rules:
  - host: control_plane
    http:
      paths:
      - backend:
          serviceName: appsvc1
          servicePort: 80
        path: /app1
      - backend:
          serviceName: appsvc2
          servicePort: 80
        path: /app2
EOF

kubectl create -f /tmp/app-ingress.yaml

################
## ROOK, CEPH ##
################

cd /tmp
git clone https://github.com/rook/rook.git
kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/operator.yaml
kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/cluster.yaml
kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/storageclass.yaml
  # this is a patch for storageclass
kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/toolbox.yaml
  # check if toolbox pod is up
kubectl -n rook-ceph get pod -l "app=rook-ceph-tools"
  # get into toolbox pod and run commands to see the ceph cluster info
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
    ceph status
    ceph osd status
    ceph df
    rados df
  # to remove toolbox: kubectl -n rook-ceph delete deployment rook-ceph-tools
sudo yum install -y xfsprogs
kubectl edit service apps-ingresses-nginx-ingress-controller
  # check to which port is port 80 receiving ingress access - 31096? kubectl get services
(...)
spec
  - name: http
    nodePort: 31096
    port: 80
    protocol: TCP
    targetPort: http
(...)

##########################
## GRAFANA & PROMETHEUS ##
##########################

helm init
helm repo update
helm install --name prometheus stable/prometheus
helm install --name grafana stable/grafana

cat > /tmp/grafana-ingress.yaml <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
spec:
  rules:
  - host: control_plane
    http:
      paths:
      - backend:
          serviceName: grafana
          servicePort: 80
        path: /
EOF

kubectl create -f /tmp/grafana-ingress.yaml
  # add port for prometheus-server in the ingress controller
kubectl edit service apps-ingresses-nginx-ingress-controller
(...)
spec
  - name: prometheus-server
    nodePort: 31559
    port: 81
    protocol: TCP
    targetPort: http
(...)

kubectl edit service prometheus-server
  # change prometheus-server service to listen on port 81
(...)
spec:
  ports:
  - name: http
    port: 81
    protocol: TCP
    targetPort: 9090
(...)

  # get admin password for grafana
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

  # access
http://control_plane:31096

  # below command will give the IP of the prometheus endpoint that needs to be added into grafana datasources
kubectl describe service prometheus-server | grep -i endpoints

#########################################
## WORDPRESS & MYSQL (on top of above) ##
#########################################

kubectl create -f rook/cluster/examples/kubernetes/mysql.yaml
  # edit wordpress.yaml in the Deployment section, make sure version apps/v1beta1 is set instead of apps/v1
kubectl create -f rook/cluster/examples/kubernetes/wordpress.yaml

# cat > /tmp/wordpress-ingress.yaml <<EOF
# ---
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: wordpress-ingress
# spec:
#   rules:
#   - host: control_plane
#     http:
#       paths:
#       - backend:
#           serviceName: wordpress
#           servicePort: 80
#         path: /wp-admin
# EOF

# kubectl create -f /tmp/wordpress-ingress.yaml

  # kubectl get services and open up in vagrant the port assigned for wordpress, ie 32185, and do vagrant reload control_plane
  # do something on wordpress http://control_plane:31096/wp-admin/upload.php
  # if we delete the mysql pod, it will still come back around with the same content
kubectl delete pod $(kubectl get pod -l app=wordpress,tier=mysql -o jsonpath='{.items[0].metadata.name}')