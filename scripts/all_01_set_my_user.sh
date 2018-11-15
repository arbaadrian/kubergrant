#!/bin/bash

# Load variables
source /tmp/vars

# General user provisioning commands
groupadd $KUBERNETES_USER_GROUP -g 20000
useradd -u 20000 -g $KUBERNETES_USER_GROUP $KUBERNETES_USER_USERNAME
echo "$KUBERNETES_USER_USERNAME   ALL=(ALL)       NOPASSWD: ALL" | EDITOR="tee -a" visudo
mkdir /home/$KUBERNETES_USER_USERNAME/.ssh
echo "$KUBERNETES_USER_PUBLIC_KEY" >> /home/$KUBERNETES_USER_USERNAME/.ssh/authorized_keys
chmod 600 /home/$KUBERNETES_USER_USERNAME/.ssh/authorized_keys
chmod 700 /home/$KUBERNETES_USER_USERNAME/.ssh
chown -R $KUBERNETES_USER_USERNAME.$KUBERNETES_USER_GROUP /home/$KUBERNETES_USER_USERNAME/.ssh