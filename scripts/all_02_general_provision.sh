#!/bin/bash

# Load variables
source /tmp/vars

# General provisioning commands
echo -e "LANG=en_US.utf-8
LC_ALL=en_US.utf-8" >> /etc/environment
cd /tmp
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh https://centos7.iuscommunity.org/ius-release.rpm
yum install -y wget zip unzip nano tar git
echo -e "$KUBERNETES_MASTER_IP master
10.0.21.41 worker01
10.0.21.42 worker02
10.0.21.43 worker03" >> /etc/hosts