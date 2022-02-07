#!/usr/bin/env bash
#-----------------------------------------------------
# Visit https://github.com/juanlazarde/ansible_homelab
# Licensed under the MIT License
#-----------------------------------------------------
#
# Syntax: bash prep_vm
#
# Normal usage; without arguments, will install run a script to prepare the machine as a template for VM.
#

echo "Install cloud-init if it's not installed."
sudo apt install -y cloud-init

echo "Remove SSH host keys"
sudo rm -f /etc/ssh/ssh_host_*

echo "Truncate machine identifier, if it exists. Usually in Unbuntu"
cat /etc/machine-id && sudo truncate -s 0 /etc/machine-id

echo "Create a symbolic link to machine id"
ls -l /var/lib/dbus/machine-id || sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "Clean up packages"
(sudo apt clean; sudo apt autoremove -y) && sudo poweroff

echo "On Proxmox, the next steps are:"
echo "[VM] -> Right click and Convert to Template. It will remove the current VM."
echo "[Template VM] -> Hardware -> Remove the CD-DVD with the ISO."
echo "[Template VM] -> Hardware -> Add a CloudInit Drive."
echo "[Template VM] -> Cloud-Init -> Edit as needed."
echo
echo "If SSH in is not possible, try:"
echo "$ sudo dpkg-reconfigure openssh-server"

