#!/bin/bash

# Load variables
source /tmp/vars

# General provisioning commands
echo -e "LANG=en_US.utf-8
LC_ALL=en_US.utf-8" >> /etc/environment
yum install -y wget zip unzip nano # tar git go telnet net-tools vim
cd /tmp
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y ./epel-release-latest-*.noarch.rpm
rm -rf epel-release-latest-7.noarch.rpm
echo "10.124.55.231    857222-Nexus1-build.tjxeurope.com    nexus.tjxeurope.com" >> /etc/hosts
echo -e "$KUBERNETES_MASTER_IP kube-master.kubernetes
10.0.21.41 kube-work01.kubernetes
10.0.21.42 kube-work02.kubernetes" >> /etc/hosts
rpm -ivh https://centos7.iuscommunity.org/ius-release.rpm