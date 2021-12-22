#!/bin/bash

# Load variables
source /tmp/vars

# Mount the nfs shares
mount -t nfs $KUBERNETES_CONTROL_PLANE_IP:$NFS_MOUNT_PATH /mnt

# Start the services, docker and kubelet.
systemctl enable docker kubelet
systemctl start docker kubelet

#Change the kuberetes cgroup-driver to 'cgroupfs'.
#OLD sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
sed -i 's@Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf\"@'"Environment=\"KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --network-plugin=cni --node-ip=$KUBERNETES_WORKER_IP\""'@g' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

#Reload the systemd system and restart the kubelet service.
systemctl daemon-reload
systemctl restart kubelet

# Kubernetes worker node
kubeadm join $KUBERNETES_CONTROL_PLANE_IP:$KUBERNETES_CONTROL_PLANE_PORT --token $KUBERNETES_CLUSTER_TOKEN --discovery-token-ca-cert-hash $KUBERNETES_CLUSTER_TOKEN_SHA
