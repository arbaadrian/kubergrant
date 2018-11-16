#!/bin/bash

# Load variables
NODENAME=$(hostname -s)
source /tmp/vars

# Start the docker and kubelet services.
systemctl enable docker kubelet
systemctl start docker kubelet

# Change the kuberetes cgroup-driver to 'cgroupfs'.
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Reload the systemd system and restart the kubelet service.
systemctl daemon-reload
systemctl restart kubelet

# Kubernetes Cluster Initialization
kubeadm init --apiserver-cert-extra-sans=$KUBERNETES_MASTER_IP --node-name $NODENAME --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$KUBERNETES_MASTER_IP

# Create new '.kube' configuration directory and copy the configuration 'admin.conf'.
# for our user
mkdir -p /home/$KUBERNETES_USER_USERNAME/.kube
cp /etc/kubernetes/admin.conf /home/$KUBERNETES_USER_USERNAME/.kube/config
chown -R $KUBERNETES_USER_USERNAME.$KUBERNETES_USER_GROUP /home/$KUBERNETES_USER_USERNAME/.kube

# for vagrant user
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant.vagrant /home/vagrant/.kube

# for root
mkdir /root/.kube
ln -s /etc/kubernetes/admin.conf /root/.kube/config

# Deploy the flannel network to the kubernetes cluster
kubectl apply -f /tmp/kube-flannel.yml