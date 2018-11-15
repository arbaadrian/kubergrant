# kubergrant - Kubernetes cluster in Vagrant

## Prerequisites

### variables.sh

You have to create a file named 'variables.sh' in the repository root folder.
You have to set 3 parameters with your own data.

KUBERNETES_USER_PUBLIC_KEY=""
KUBERNETES_USER_USERNAME=""
KUBERNETES_USER_GROUP=""

The file will look like this in the end:

```bash
#!/bin/bash

# ENV Variables

KUBERNETES_USER_PUBLIC_KEY=''
KUBERNETES_USER_USERNAME=""
KUBERNETES_USER_GROUP=""

KUBERNETES_MASTER_IP="10.0.21.40"
KUBERNETES_MASTER_PORT="6443"

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
export KUBERNETES_CLUSTER_TOKEN=$KUBERNETES_CLUSTER_TOKEN
export KUBERNETES_CLUSTER_TOKEN_SHA=$KUBERNETES_CLUSTER_TOKEN_SHA" > /tmp/vars
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

Update your variables.sh file on these 2 parameters - they will be used to provision the nodes.

KUBERNETES_CLUSTER_TOKEN=""
KUBERNETES_CLUSTER_TOKEN_SHA=""

Provision the rest of the Vagrant nodes

```bash
vagrant up
```

## Result

A master and two nodes will be created.

## Other

1 To change the flannel configuration, you can

```bash
kubectl edit cm -n kube-system kube-flannel-cfg

# Possibly alo some cleanup
# kubectl delete pod -n kube-system -l app=flannel
```

2 To install the Dashboard, ssh to the master and

```bash
sudo su
chmod +x /tmp/others_kubernetes_deploy_dashboard.sh
/tmp/others_kubernetes_deploy_dashboard.sh

## You have to do 3 manual steps:
# on your local machine, run command ssh -L 8001:localhost:8001 <your_user>@127.0.0.1 -p <vagrant_assigned_port>
# navigate with browser to http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
# choose Token authentication and insert token from above commands
```