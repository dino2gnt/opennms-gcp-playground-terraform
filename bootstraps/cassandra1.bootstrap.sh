#!/bin/bash
ZONE="us-central1-c"  #i hate that the zone is hardcoded, but I'm too lazy to fix it right now.
CONFIG_REPO="https://github.com/dino2gnt/opennms-gcp-playground-ansible.git" #this Ansible repo holds all the configuration roles.

yum -y install epel-release
yum -y install vim net-tools atop tmux gpm tar ansible git lvm2
yum -y update
gcloud compute instances describe $(hostname) --flatten="metadata[vpw]" --zone=$ZONE --quiet | tail -n1 | sed 's/\ //g' > /etc/ansible/.vpw
chmod 0600 ~/.deploy
#if you're using a private repo with a key:
#gcloud compute instances describe $(hostname) --flatten="metadata[deploy-key]" --zone=$ZONE --quiet | tail -n+2 | sed 's/\ \ //g' > ~/.deploy
#ansible-pull -U git@github.com:dino2gnt/opennms-gcp-playground-ansible.git -i localhost,$(hostname), --accept-host-key --private-key ~/.deploy -d /var/lib/ansible --vault-password-file=/etc/ansible/.vpw --clean --force
ansible-pull -U ${CONFIG_REPO} -i localhost,$(hostname), --accept-host-key -d /var/lib/ansible --vault-password-file=/etc/ansible/.vpw --clean --force
