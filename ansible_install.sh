#!/bin/bash
# Run this on the shell with: sh ansible_install.sh

# Folder where the ansible script will be saved.
folder="~/ansible-scripts"

# # Install Ansible and dependencies.
# sudo apt update
# sudo apt install -y software-properties-common
# sudo apt-add-repository --yes ppa:ansible/ansible
# sudo apt update
# sudo apt install -y ansible
# sudo apt install -y openssh-server
# sudo apt install -y sshpass
# echo "Ansible and dependencies installed"

# # Get the latest ansible scripts.
# sudo apt install -y git
git clone https://github.com/juanlazarde/ansible.git $folder
echo "Ansible scripts installed in " $folder
cd $folder
