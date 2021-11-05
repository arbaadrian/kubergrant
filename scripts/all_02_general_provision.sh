#!/bin/bash

# Load variables
source /tmp/vars

# General provisioning commands
echo -e "LANG=en_US.utf-8
LC_ALL=en_US.utf-8" >> /etc/environment
yum install -y https://repo.ius.io/ius-release-el7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y yum-utils wget zip unzip nano tar git
echo -e "$KUBERNETES_CONTROL_PLANE_IP controlplane
10.0.21.41 worker01
10.0.21.42 worker02
10.0.21.43 worker03" >> /etc/hosts