#!/bin/bash

# Load variables
source /tmp/vars

# Start the services, docker and kubelet.
systemctl enable docker kubelet
systemctl start docker kubelet

#Change the kuberetes cgroup-driver to 'cgroupfs'.
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

#Reload the systemd system and restart the kubelet service.
systemctl daemon-reload
systemctl restart kubelet

# Kubernetes worker node
kubeadm join $KUBERNETES_MASTER_IP:$KUBERNETES_MASTER_PORT --token $KUBERNETES_CLUSTER_TOKEN --discovery-token-ca-cert-hash sha256:$KUBERNETES_CLUSTER_TOKEN_SHA