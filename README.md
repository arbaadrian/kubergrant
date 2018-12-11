# kubergrant - Kubernetes cluster over Vagrant VMs

## Prerequisites

For Vagrant, you have to install the following plugins:

```bash
vagrant plugin install vagrant-disksize
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
KUBERNETES_MASTER_PORT="6443"

KUBERNETES_TOOLS_VERSION="1.12.3"
DOCKER_TOOLS_VERSION="18.09.0.ce-1.el7.centos"

# Add values here after the master has been provisioned and the values are available
KUBERNETES_CLUSTER_TOKEN=""
KUBERNETES_CLUSTER_TOKEN_SHA=""
KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=""

# Commands
echo -e "export KUBERNETES_USER_PUBLIC_KEY=\"$KUBERNETES_USER_PUBLIC_KEY\"
export KUBERNETES_USER_USERNAME=$KUBERNETES_USER_USERNAME
export KUBERNETES_USER_GROUP=$KUBERNETES_USER_GROUP
export KUBERNETES_MASTER_IP=$KUBERNETES_MASTER_IP
export KUBERNETES_MASTER_PORT=$KUBERNETES_MASTER_PORT
export KUBERNETES_TOOLS_VERSION=$KUBERNETES_TOOLS_VERSION
export DOCKER_TOOLS_VERSION=$DOCKER_TOOLS_VERSION
export KUBERNETES_CLUSTER_TOKEN=$KUBERNETES_CLUSTER_TOKEN
export KUBERNETES_CLUSTER_TOKEN_SHA=$KUBERNETES_CLUSTER_TOKEN_SHA
export KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=$KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN" > /tmp/vars
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
vagrant up kube-master
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

A master and two nodes will be created.

## Other

1. To add a sync folder to Vagrant in order to test scripts directly while editing with your favorite IDE:

   ```bash
   # edit the Vagrantfile, add a line similar to this
     machine.vm.synced_folder "app/", "/tmp/app"
   # on guest:
   vagrant plugin install vagrant-vbguest
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

2. To change the flannel configuration, you can

   ```bash
   kubectl edit cm -n kube-system kube-flannel-cfg

   # Possibly also some cleanup
   # kubectl delete pod -n kube-system -l app=flannel
   ```

3. To install the Dashboard

   ```bash
   kubectl apply -f /tmp/kubernetes-dashboard.yml
   kubectl -n kube-system get service kubernetes-dashboard

   # Create user for Dashboard admin access
   kubectl apply -f /tmp/dashboard-adminuser.yml
   kubectl apply -f /tmp/dashboard-adminuser-rbac.yml

   # Print access token for said user
   kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

   # Access below URL with Mozilla and paste in the token (will not work with Chrome) due to SSL
   https://master:31557
   ```

4. Install Helm and Tiller (example taken from here: <https://www.mirantis.com/blog/install-kubernetes-apps-helm/>)

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