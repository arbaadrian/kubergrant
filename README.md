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

1 To add a sync folder to Vagrant in order to test scripts

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

2 To change the flannel configuration, you can

```bash
kubectl edit cm -n kube-system kube-flannel-cfg

# Possibly alo some cleanup
# kubectl delete pod -n kube-system -l app=flannel
```

3 To install the Dashboard

```bash
# SSh to your cluster master machine
ssh <user>@master

# Run these commands
sudo su
chmod +x /tmp/others_kubernetes_deploy_dashboard.sh
/tmp/others_kubernetes_deploy_dashboard.sh

## You also have to do 3 manual steps:

# on your local machine, run command ssh -L 8001:localhost:8001 <your_user>@127.0.0.1 -p <vagrant_assigned_port>
# navigate with browser to http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
# choose Token authentication and insert token from above commands
```