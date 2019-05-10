# kubergrant - Kubernetes cluster over Vagrant VMs

## Prerequisites

For Vagrant, you have to install the following plugins:

```bash
vagrant plugin install vagrant-disksize
vagrant plugin install vagrant-vbguest
```

### variables.sh

You have to create a file named 'variables.sh' in the repository root folder.
You have to set the 3 parameters below with your own data (ssh keys and username):

```bash
KUBERNETES_USER_PUBLIC_KEY=''
KUBERNETES_USER_USERNAME=""
KUBERNETES_USER_GROUP=""
```

The entire file should look (or, at least contain all the variables) like this:
(mind the single quotes for KUBERNETES_USER_PUBLIC_KEY)

```bash
#!/bin/bash

  # ENV Variables
KUBERNETES_USER_PUBLIC_KEY=''
KUBERNETES_USER_USERNAME=""
KUBERNETES_USER_GROUP=""

KUBERNETES_MASTER_IP="10.0.21.40"
KUBERNETES_WORKER_IP="$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
KUBERNETES_MASTER_PORT="6443"

KUBERNETES_TOOLS_VERSION="1.14.0"
KUBERNETES_HELM_VERSION="2.13.1"
DOCKER_TOOLS_VERSION="18.09.3-3.el7"

  # Add values here after the master has been provisioned and the values are available
KUBERNETES_CLUSTER_TOKEN=""
KUBERNETES_CLUSTER_TOKEN_SHA=""
KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=""

  # Others
NFS_MOUNT_PATH="/tmp/nfs/kubedata"

  # Commands
echo -e "export KUBERNETES_USER_PUBLIC_KEY=\"$KUBERNETES_USER_PUBLIC_KEY\"
export KUBERNETES_USER_USERNAME=$KUBERNETES_USER_USERNAME
export KUBERNETES_USER_GROUP=$KUBERNETES_USER_GROUP
export KUBERNETES_MASTER_IP=$KUBERNETES_MASTER_IP
export KUBERNETES_WORKER_IP=$KUBERNETES_WORKER_IP
export KUBERNETES_MASTER_PORT=$KUBERNETES_MASTER_PORT
export KUBERNETES_TOOLS_VERSION=$KUBERNETES_TOOLS_VERSION
export KUBERNETES_HELM_VERSION=$KUBERNETES_HELM_VERSION
export DOCKER_TOOLS_VERSION=$DOCKER_TOOLS_VERSION
export KUBERNETES_CLUSTER_TOKEN=$KUBERNETES_CLUSTER_TOKEN
export KUBERNETES_CLUSTER_TOKEN_SHA=$KUBERNETES_CLUSTER_TOKEN_SHA
export KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=$KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN
export NFS_MOUNT_PATH=$NFS_MOUNT_PATH" > /tmp/vars
```

This file is under .gitignore, so you only have to set this once, it will not be commited to the repo.

### env.yaml

In the file 'env.yaml' you can change or set up machine info or add other parameters which will be referenced in the Vagrant file.

```bash
---

box_image: centos/7
master:
  cpus: 1
  memory: 2048
node:
  count: 2
  cpus: 1
  memory: 2048
ip:
  master: 10.0.21.40
  node:   10.0.21.41
```

## Usage

```bash
vagrant up master
```

Wait until the provisioning finishes and copy the admin cluster token and sha sum values from the Vagrant output.

Update your variables.sh file on these variables - they will be used to provision the nodes.

```bash
KUBERNETES_CLUSTER_TOKEN=""
KUBERNETES_CLUSTER_TOKEN_SHA=""
KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=""
```

Provision the rest of the Vagrant nodes

```bash
vagrant up
```

## Result

A master and X nodes will be created.

## Other

### 1. To add a sync folder to Vagrant in order to test scripts directly while editing with your favorite IDE

```bash
  # edit the Vagrantfile, add a line similar to this
machine.vm.synced_folder "app/", "/tmp/app"
  # on guest:
vagrant ssh
  # on host
sudo yum upgrade -y
sudo reboot
  # on guest, after host rebooted
vagrant vbguest --do install --no-cleanup
  # there should be no error and you will see a service being started at the end
vagrant reload
  # to add the shared folder to the host
vagrant ssh
  # should now have two way folder and files sync between client and host
```

### 2. To change the flannel configuration, you can

```bash
kubectl edit cm -n kube-system kube-flannel-cfg

  # Possibly also some cleanup
  # kubectl delete pod -n kube-system -l app=flannel
```

### 3. To install the Dashboard

```bash
kubectl create -f /tmp/kubernetes-dashboard.yml
kubectl get service kubernetes-dashboard -n kube-system

  # Create user for Dashboard admin access
kubectl create -f /tmp/dashboard-adminuser.yml
kubectl create -f /tmp/dashboard-adminuser-rbac.yml

  # Print access token for said user
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

  # Access below URL with Mozilla and paste in the token (will not work with Chrome) due to SSL
https://master:31557
```

### 4. Install Helm and Tiller (example taken from here: <https://www.mirantis.com/blog/install-kubernetes-apps-helm/>)

```bash
  # long one liner sed command
sed -i 's@Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf\"@'"Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --node-ip=$KUBERNETES_WORKER_IP\""'@g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
cd /tmp
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
tar -zxvf helm-v2.11.0-linux-amd64.tar.gz
cd helm
sudo cp helm /usr/bin/
sudo cp helm /usr/local/bin/
sudo cp tiller /usr/bin/
sudo cp tiller /usr/local/bin/
helm init
helm init --upgrade
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
helm repo update
  # test deploy:
helm install stable/mysql
```

### 5. Install an ingress to server for the applications

```bash
  ## Start an ingress and add an application

  # install default nginx-ingress deployment
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

  # now we will add an ingress for nginx, it will return a few nginx details when accessed like so http://master:31557/nginx_status (or IP)
cat > /tmp/nginx-ingress.yaml <<EOF
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: master
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
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: app-ingress
spec:
  rules:
  - host: master
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
```

### 6. Install ROOK and CEPH

```bash
cd /tmp && git clone https://github.com/rook/rook.git
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
```

### 7. Install GRAFANA and PROMETHEUS (backup provided in files/rook_ceph_grafanaingress.tar.gz)

```bash
helm init
helm repo update
helm install --name prometheus stable/prometheus
helm install --name grafana stable/grafana

cat > /tmp/grafana-ingress.yaml <<EOF
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana-ingress
spec:
  rules:
  - host: master
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
http://master:31096

  # below command will give the IP of the prometheus endpoint that needs to be added into grafana datasources
kubectl describe service prometheus-server | grep -i endpoints
```

### 8. Install Wordpress, MySQL, ingress rules and storage class on top of step 5 (backup provided in files/wordpress.tar.gz)

```bash
kubectl create -f /tmp/rook/cluster/examples/kubernetes/mysql.yaml
  # edit wordpress.yaml in the Deployment section, make sure version apps/v1beta1 is set instead of apps/v1
kubectl create -f /tmp/rook/cluster/examples/kubernetes/wordpress.yaml

# cat > /tmp/wordpress-ingress.yaml <<EOF
# ---
# apiVersion: extensions/v1beta1
# kind: Ingress
# metadata:
#   name: wordpress-ingress
# spec:
#   rules:
#   - host: master
#     http:
#       paths:
#       - backend:
#           serviceName: wordpress
#           servicePort: 80
#         path: /wp-admin
# EOF

# kubectl create -f /tmp/wordpress-ingress.yaml

  # kubectl get services and open up in vagrant the port assigned for wordpress, ie 32185, and do vagrant reload master
  # do something on wordpress http://master:31096/wp-admin/upload.php
  # if we delete the mysql pod, it will still come back around with the same content
kubectl delete pod $(kubectl get pod -l app=wordpress,tier=mysql -o jsonpath='{.items[0].metadata.name}')
```

## Upgrade cluster

```bash
  >>> on master
sudo yum update kubeadm kubelet -y
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.14.0
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl drain worker01 --ignore-daemonsets --delete-local-data
  ## if stuck aboce at a pod you can - kubectl delete pod < pod_name > -n < namespace > --grace-period=0 --force
  >>> go to worker01
sudo yum update kubeadm kubelet -y
sudo kubeadm upgrade node config --kubelet-version $(kubelet --version | cut -d ' ' -f 2)
sudo systemctl restart kubelet
sudo systemctl daemon-reload
sudo yum update kubectl -y
  >>> go to master
kubectl uncordon worker01
  >>> repeat for all workers
  >>> go to master after all nodes done
sudo kubeadm upgrade node config --kubelet-version $(kubelet --version | cut -d ' ' -f 2)
sudo systemctl restart kubelet
sudo systemctl daemon-reload
sudo yum update kubectl -y
```

## Upgrade Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
helm init --upgrade
```