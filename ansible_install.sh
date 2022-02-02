#!/bin/bash

# Install Ansible and dependencies.
sudo apt update
sudo apt install -y software-properties-common
sudo apt-add-repository --yes ppa:ansible/ansible
sudo apt update
sudo apt install -y ansible
sudo apt install -y openssh-server
sudo apt install -y sshpass
echo "Ansible and dependencies installed"

# Get the latest ansible scripts
sudo apt install -y git
folder="~/ansible-scripts"
git clone https://github.com/juanlazarde/ansible.git $folder
cd $folder
