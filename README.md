# kubergrant - Kubernetes cluster over Vagrant VMs

## Prerequisites

This entire deployment has been tested with and requires be installed: 

- vagrant >= 2.2.18
- virtualbox = 6.1.26

```bash
# MacOS installation
brew install virtualbox
brew install vagrant
```

For Vagrant, you have to install the following plugins:

```bash
vagrant plugin install vagrant-disksize
# the vbgues plugin will not correctly work on MacOS, hence commented
# vagrant plugin install vagrant-vbguest
```

### variables.sh

You have to create a file named 'variables.sh' in the repository root folder.
You have to set the 3 parameters below with your own data (ssh keys and username/usergroup):

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

KUBERNETES_CONTROL_PLANE_IP="10.0.21.40"
KUBERNETES_WORKER_IP="$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
KUBERNETES_CONTROL_PLANE_PORT="6443"

KUBERNETES_TOOLS_VERSION="1.19.2"
KUBERNETES_HELM_VERSION="3.7.1"
DOCKER_TOOLS_VERSION="18.09.1-3.el7"

  # Add values here after the controlplane has been provisioned and the values are available
KUBERNETES_CLUSTER_TOKEN=""
KUBERNETES_CLUSTER_TOKEN_SHA=""
KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=""

  # Others
NFS_MOUNT_PATH="/tmp/nfs/kubedata"

  # Commands
echo -e "export KUBERNETES_USER_PUBLIC_KEY=\"$KUBERNETES_USER_PUBLIC_KEY\"
export KUBERNETES_USER_USERNAME=$KUBERNETES_USER_USERNAME
export KUBERNETES_USER_GROUP=$KUBERNETES_USER_GROUP
export KUBERNETES_CONTROL_PLANE_IP=$KUBERNETES_CONTROL_PLANE_IP
export KUBERNETES_WORKER_IP=$KUBERNETES_WORKER_IP
export KUBERNETES_CONTROL_PLANE_PORT=$KUBERNETES_CONTROL_PLANE_PORT
export KUBERNETES_TOOLS_VERSION=$KUBERNETES_TOOLS_VERSION
export KUBERNETES_HELM_VERSION=$KUBERNETES_HELM_VERSION
export DOCKER_TOOLS_VERSION=$DOCKER_TOOLS_VERSION
export KUBERNETES_CLUSTER_TOKEN=$KUBERNETES_CLUSTER_TOKEN
export KUBERNETES_CLUSTER_TOKEN_SHA=$KUBERNETES_CLUSTER_TOKEN_SHA
export KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN=$KUBERNETES_DASHBOARD_ADMIN_USER_TOKEN
export NFS_MOUNT_PATH=$NFS_MOUNT_PATH" > /tmp/vars
```

This file is under .gitignore, so you only have to set this once, it will not be committed to the repo.

### env.yaml

In the file 'env.yaml' you can change or set up machine info or add other parameters which will be referenced in the Vagrant file.

```yaml
---
box_image: centos/7
domain: kubernetes
controlplane:
  cpus: 2
  memory: 2048
  disk_size: "40GB"
node:
  # how many worker nodes to create
  count: 1
  cpus: 2
  memory: 2048
ip:
  controlplane: 10.0.21.40
  node_ip_range_from: 10.0.21.41
ports:
  wordpress_port: 30164
  dashboard_port: 31557
```

## Usage

```bash
vagrant up controlplane
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

To stop or destroy the vagrant built infrastructure you have to run one of the commands below

```bash
# to stop the clusters
vagrant halt

# to destroy the cluster
vagrant destroy
```

## Result

A controlplane and X nodes will be created.

Files under the files folder will be available under the /vagrant folder within the Vagrant provisioned machines.

## Other

### 1. To add a sync folder to Vagrant in order to test scripts directly while editing with your favorite IDE

This is currently not supported on MacOS since the VirtualBox guest additions plugin is not working

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

### 3. Install the Dashboard

NOTE: The dashboard implementation is old and may be unsecure - don't use it for anything other than testing

```bash
  # deploy the Dashboard and check the service port
kubectl create -f /vagrant/files/dashboard/kubernetes-dashboard.yml
kubectl get service kubernetes-dashboard -n kube-system

  # Create user for Dashboard admin access
kubectl create -f /vagrant/files/dashboard/dashboard-adminuser.yml
kubectl create -f /vagrant/files/dashboard/dashboard-adminuser-rbac.yml

  # Print access token for said user
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

  # Access below URL with Mozilla and paste in the token (will not work with Chrome) due to SSL
https://controlplane:31557
```

### 4. Install Helm (example taken from here: <https://www.mirantis.com/blog/install-kubernetes-apps-helm/>)

```bash
  # long one liner sed command
sed -i 's@Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf\"@'"Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=systemd --node-ip=$KUBERNETES_WORKER_IP\""'@g' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
cd /tmp
wget https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz
tar -zxvf helm-v3.7.1-linux-amd64.tar.gz
cd helm
sudo cp helm /usr/bin/
sudo cp helm /usr/local/bin/
helm repo update
  # test deploy:
helm install stable/mysql
```

### 5. Install ROOK and CEPH (optional)

```bash
  # this storage type only makes sense to be deployed if you have at least 3 worker nodes configured in the cluster
  # it may not work correctly if you only have one or two
cd /tmp && git clone https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
kubectl create namespace rook-ceph
kubectl create -f crds.yaml -f common.yaml -f operator.yaml -f toolbox.yaml
kubectl create -f cluster.yaml
  # this is a patch for storageclass
kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
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

### 6. For other components to be installed

You can check the file below

```bash
scripts/zero_others_kubernetes_stuff.sh
```

## Upgrade Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```