#!/bin/bash

# Load variables
source /tmp/vars

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Enable the br_netfilter module so that the packets traversing the bridge are processed 
# by iptables for filtering and for port forwarding, and the kubernetes pods across the cluster can communicate with each other.
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# kubelet requires swap off
swapoff -a

# keep swap off after reboot
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#Install Docker CE
yum install -y yum-utils device-mapper-persistent-data lvm2

mkdir /var/lib/docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y --setopt=obsoletes=0 docker-ce-$DOCKER_TOOLS_VERSION docker-ce-selinux-$DOCKER_TOOLS_VERSION
usermod -aG docker $KUBERNETES_USER_USERNAME
usermod -aG docker vagrant

# Prepare for kubernetes install
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Configure sysctl
echo -e "net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
sysctl -p

# TODO: This command was an ttempt to fix a warning from the kubernetes pre-flight checks, but did not work
# go get github.com/kubernetes-incubator/cri-tools/cmd/crictl

# Install kubernetes
yum install -y kubelet-$KUBERNETES_TOOLS_VERSION kubeadm-$KUBERNETES_TOOLS_VERSION kubectl-$KUBERNETES_TOOLS_VERSION



