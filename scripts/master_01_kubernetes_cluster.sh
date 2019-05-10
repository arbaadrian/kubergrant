#!/bin/bash

# Load variables
NODENAME=$(hostname -s)
source /tmp/vars

# Install nfs server on master (for playing with volumes)
yum install -y nfs-server

# Enable and start the nfs server service
systemctl enable nfs-server
systemctl start nfs-server

# Configure the nfs share
cat > /etc/exports << EOF
$NFS_MOUNT_PATH   *(rw,sync,no_subtree_check,insecure)
EOF

# Create the required nfs folders
mkdir -p $NFS_MOUNT_PATH
mkdir $NFS_MOUNT_PATH/{pva,pvb,pvc,pvd,pve,pvf}

# Set correct nfs permissions
cd $NFS_MOUNT_PATH && chmod -R 777 ../

# Export the folders
exportfs -rav

# Check the nfs folders
exportfs -v
showmount -e

# Start the docker and kubelet services.
systemctl enable docker kubelet
systemctl start docker kubelet

# Change the kuberetes cgroup-driver to 'cgroupfs'.
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sed -i 's@Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf\"@'"Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --node-ip=$KUBERNETES_MASTER_IP\""'@g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

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

# Install helm and tiller
cd /tmp
wget https://storage.googleapis.com/kubernetes-helm/helm-v$KUBERNETES_HELM_VERSION-linux-amd64.tar.gz
tar -zxvf helm-v$KUBERNETES_HELM_VERSION-linux-amd64.tar.gz
cp linux-amd64/helm /usr/bin/
cp linux-amd64/tiller /usr/bin/
cp linux-amd64/helm /usr/local/bin/
cp linux-amd64/tiller /usr/local/bin/
helm init
helm repo update
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

# print cluster join token
kubeadm token create --print-join-command