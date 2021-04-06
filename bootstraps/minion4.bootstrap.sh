#!/bin/bash
ZONE="us-central1-c"  #i hate that the zone is hardcoded, but I'm too lazy to fix it right now.
CONFIG_REPO="https://github.com/dino2gnt/opennms-gcp-playground-ansible.git" #this Ansible repo holds all the configuration roles.

yum -y install epel-release
yum -y install vim net-tools atop tmux gpm tar ansible git
yum -y update
gcloud compute instances describe $(hostname) --flatten="metadata[vpw]" --zone=$ZONE --quiet | tail -n1 | sed 's/\ //g' > /etc/ansible/.vpw
gcloud compute instances describe $(hostname) --flatten="metadata[minion_location]" --zone=$ZONE --quiet | tail -n1 | sed 's/\ //g' > /tmp/metadata_minion_location
chmod 0600 ~/.deploy
sdb=$(mount | grep -c sdb);
if [ $sdb -eq 0 ]; then
  parted /dev/sdb mklabel gpt
  parted /dev/sdb mkpart 1 xfs 0% 100%
  mkfs.xfs /dev/sdb1
  echo "/dev/sdb1               /data                   xfs     defaults        0 1" >> /etc/fstab
  mkdir -p /data && mount /data
fi
#if you're using a private repo with a key:
#gcloud compute instances describe $(hostname) --flatten="metadata[deploy-key]" --zone=$ZONE --quiet | tail -n+2 | sed 's/\ \ //g' > ~/.deploy
#ansible-pull -U git@github.com:dino2gnt/opennms-gcp-playground-ansible.git -i localhost,$(hostname), --accept-host-key --private-key ~/.deploy -d /var/lib/ansible --vault-password-file=/etc/ansible/.vpw --clean --force
ansible-pull -U ${CONFIG_REPO} -i localhost,$(hostname), --accept-host-key -d /var/lib/ansible --vault-password-file=/etc/ansible/.vpw --clean --force
