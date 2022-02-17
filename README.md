**Setup and Update your Homelab Server... easy**

---

# Ultimate Homelab with Ansible

These scripts help setup and update your workstation and servers with Ansible agent-less package, so nothing is installed in the servers!

Ansible scripts are made of *playbooks*. These playbooks include *roles* that:

    - update and upgrade all packages, rebooting if needed
    - install unattended-upgrade packages
    - create and elevate admin user to super user level
    - disable root passwords
    - disable remote root logins
    - create SSH key pairs, updating remote hosts with the public key
    - install zsh, oh-my-zsh, with powerlevel9k and custom plugins, and sets the default shell
    - remove Ubuntu's Snap services and leave-behinds
    - maximize LVM partitions
    - customize the hostname
    - update the timezone
    - install "qemu-guest-agent" if it's a Proxmox VM
    - install and configures UFW (uncomplicated fire wall)
    - install and configures fail2ban to ban multiple login attempts
    ... for now

These scripts are in an early stage, but work fine on my setup. Post your issues and I'll try to help. I'm sharing this repository, as a lot comes from developers on GitHub and other sources (like YouTube). I'm trying to give back. Most of the material is commented or self-explanatory.

Once installed, your workstation will be 90% ready. I can't think about what the other 10% would be, but I won't say it'll be 100% ready. Open a discussion for more features. Servers have a different story, servers are more like 10% ready to go. They'll be accessible via ansible, with ssh keys, updated, root locked, ufw and fail2ban up and running, super user created and unattended upgrades installed, to name a few. The rest is up to you. Whether it will be a web server, NAS, proxy manager, VPN, etc.

**The code here, will not run out-of-the-box**. You need to configure a couple of files listed below (ansible.cfg, hosts.yml).

# Table of Contents
- [Contents](#contents)
- [Install](#install)
- [Usage](#usage)
- [Debug](#debug)

# My setup
- Bare metal rack server.
- Proxmox Hypervisor
- Multple VM's and LXD's
- Workstation is a Windows 10 with Ubuntu WSL
- Testing all on Virtualbox VM's
- Mostly using Ubuntu or light-weight debian/Ubuntu versions

# Supported platforms
- Ubuntu 20.04 LTS
- Windows WSL Ubuntu 20.04

# Contents
- `ansible_install.sh` bash to install ansible, clone this repository, install vault key, and encrypt secrets. **Start here**
- `.\ansible` has ansible scripts, configs, playbooks, hosts, & roles.
- `.\ansible\ansible.cfg` all of ansible's parameters. **If you've installed ansible, Start here**.
- `.\ansible\hosts.yml` customize your hosts and variables here. (no global_vars or vars around). **Then here.**
- `.\ansible\playbook.yml` server & workstation plays.
- `.\ansible\*.sh` lazy bash scripts to speed up typing boring commands.
- `~\.vault_key` this file is outside of the repository (of course!). Holds the keys to the castle. Wherever you see a `!vault |` and garbled text, this is what you need to encrypt/decrypt. Use the `ansible_install.sh` to make this file super easy.
- `prep_vm.sh` helps prepare VM.

# Install
Download the installation script: `ansible_install.sh` by running this line:
    
    curl -LJO https://raw.githubusercontent.com/juanlazarde/ansible_homelab/main/ansible_install.sh

**or** get  `ansible_install.sh` [here](ansible_install.sh) and save it as `ansible_install.sh`.
 
 Run as:

    bash ansible_install.sh

This script downloads Ansible with dependencies, installs this git repository locally, creates the vault key, and it helps encrypt information (like passwords) to be inserted to the host.yml.

About the `bash` command. I've included it, because in some shells you'd need to change the ownership if you want to run it as `./ansible_install.sh`

**OR**

Clone the repository to your ansible-enabled workstation:

    git clone https://github.com/juanlazarde/ansible-scripts ~/ansible_scripts
    cd ansible_scripts

and run the commands following the guide below.

Make the most out of `ansible_install.sh`:

    Syntax: bash ansible_install.sh [optional [-a] [-r] [-v] [-e [<file name>]] [-d <directory name>] [-h]]

    Normal usage; without arguments, will install ansible, scripts, and vault key.

    --ansible, -a             : don't install Ansible and its dependencies.
    --repository, -r          : don't download the repository with Ansible scripts from GitHub.
    --vault, -v               : don't create a secret vault key
    --encrypt, -e [<filename>]: tool to create a hashed ansible-encrypted variable. Optionally, save it as a file.
    -d directory name: directory where you want to install the Ansible scripts.
    --help, -h                : help info

## Configure the installation
Edit the following files to meet your needs:

    cd ansible_scripts
    nano ansible.cfg
    nano hosts.yml

### Encryption
Remember to use the `bash ansible_install.sh -e` command to create encrypted variables, like passwords. To save them to files you can:

    bash ansible_install.sh -e encrypted_text.txt

Now you'll need to copy this text and paste it to the `hosts.yml` file for example. When you can't copy/paste, here's a solution. Feel free to offer other ideas or request a better solution through the issue tracker:

    sed -i.bak "/sudo_ssh_passphrase:/r encrypted_text.txt" ~/ansible_scripts/ansible/hosts.yml

Explanation:
* `sed` stream editor that filters and transforms text.
* `-i.bak` creates a backup of the original file. In this case, `hosts.yml`
* `/sudo_ssh_passphrase:` command to search for this string within the file. In this case, `hosts.yml`
* ` /r encrypted_text.txt` reads the file `encrypted_text.txt`, which we created in the previous step.
* `~/ansible_scripts/ansible/hosts.yml` this is the file being edited.

The variables I've set to encrypted values in `hosts.yml`, are:
* `sudo_ssh_passphrase`
* `sudo_password`

But, we'll need to edit it to adjust the proper YAML format. In example:

    sudo_ssh_passphrase: !vault |
        $ANSIBLE_VAULT;1.1;AES256
        376563383...

So,

    nano hosts.yml

Remember to delete the `encrypted_text.txt`:

    rm encrypted_text.txt

## Check connection to hosts
Enter the following command to make sure ansible works and that you can connect to your hosts:
    
    ansible all -m ping

# Usage
## First, workstation
The script will update and install workstation-client related items. Including the creation of ansible ssh keys to be sent to the hosts.

    bash workstation_setup.sh

**or**

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup"

Notice the following:
1. `ask-become-pass` will request sudo password, which is needed for some plays.
2. `--vault-password-file ~/.vault_key` is the secret file that helps decrypt `!vault` variables.
3. `-l "workstations"` it limits the plays to be applied to the workstations defind in `host.yml`.
4. `-t "setup"` it limits the plays to those tagged for setup.

Some ansible quirks:

- `Sorry, try again`. May happen if you entered the wrong sudo password. Action -> Hit CTRL+C, run again.
- `reboot` module is not executable for a local connection. Meaning, it won't reboot the workstation with the ansible agent. Action -> `sudo shutdown -r now`

## Then, deploy the ansible ssh keys to all servers-hosts.
It's very helpful, recommended even, to create an 'ansible' SSH key pair in the workstation-client. Then Distribute the public key to all the hosts, and save it to the authorized key file. This way your ansible plays will establish a valid connection to each host, do their job, and get out.

    bash deploy_ansible_ssh.sh

## Finally, setup all server.
These are all the plays to be applied to the server group only. These are the remote hosts, like Apache, TrueNas, reverse-proxy, etc.

    bash server_setup.sh

**or**

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "servers" -t "setup"

## Dry runs or checks without impact or changes to the system.
You'll need to include the flag `-C` a the end of the ansible command.
For extra verbose youll add `-vvv` to the command. i.e.

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup" -C -vvv


# Tags and Limits
To target workstations only, use the arguments `-l "workstations"`, for servers `-l "servers"`.

To run setups only, use `-t "setup"`, for updates `-t "update"`, for ssh deployment `-t "ssh"`

# Ansible common commands
## Install:
	sudo apt update
	sudo apt-add-repository --yes --update ppa:ansible/ansible
	sudo apt install -y ansible software-properties-common sshpass openssh-server

Create SSH key and profile:

    # Create the SSH Key pair. Never share the private one (wihout extension).
    ssh-keygen -t ed25519 -C "Ansible" -f ~/.ssh/ansible -q -N ""
    
    # Add Public SSH key to authorized_keys in the host.
    ssh-copy-id -i ~/.ssh/ansible.pub <remote_IP>

    # (optional) Minimizes entering SSH password during a session.
    eval $(ssh-agent) && ssh-add

    # (optional, optional) Add the command above as an alias: ssha.
    echo ""alias ssha='eval $(ssh-agent -s) && ssh-add ~/.ssh/ansible'"" >> ~/.zshrc >> ~/.bashrc


Test connection:

    ansible -i hosts <remote_IP> -m ping --user <user> --ask-pass -o
	# or
	ansible -i hosts ubuntu -m ping --key-file ~/.ssh/ansible -o
	
## Usage
	# Gather hosts info
	ansible all -m gather_facts
	
	# Send a command to all hosts
	ansible all -m apt -a name=vim-nox --become --ask-become-pass
	
	# Automate items in playbook to all hosts
	ansible-playbook -i hosts playbooks/upgrade_apt.yml \
	--user someuser --ask-pass --ask-become-pass
	# or
	ansible-playbook playbooks/upgrade_apt.yml --ask-become-pass
	
	# -----------------------------
    # --> Encrypting with Vault <--
    # -----------------------------
	sudo apt update && sudo apt install -y whois # to install mkpasswd
	mkpasswd -m sha-512 > ~/.vault_key && chmod 600 ~/.vault_key
	
	# Encrypt:
	ansible-vault encrypt --vault-password-file ~/.vault_key <filename>
	
	# Decrypt:
	ansible-vault decrypt --vault-password-file ~/.vault_key <filename>
	
	# Edit:
	ansible-vault edit --vault-password-file ~/.vault_key <filename>
	
	# Using ansible playbook with vault:
	ansible-playbook site.yml --ask-become-pass --vault-password-file ~/.vault_key
	
	# Create an encrypted and hashed password variable
	mkpasswd --method=sha-512 --salt=1234asdf | ansible-vault encrypt --vault-password-file ~/.vault_key | sed '/$ANSIBLE/i \!vault |'
	
	# Download and execute from GIT
	sudo ansible-pull --vault-password-file ~/.vault_key -U https://github.com/juanlazarde/ansible.git

# Debug
Use tags `-t "test"`, step by step `--step`, start at a certain task `--start-at-task "here"`, and show what's under the hood with `-vvv`

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup" --start-at-task="test" --step -vvv

Evaluate a variable with a dummy tasK:

    - name: Debugging
      debug: msg="{{ some.variable}}"


# Bonus - Prepare the VM
When creating a VM template for i.e. Proxmox, it's recommended to prepare the current session. Here's a script that will help set some of these out.

Run:

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/juanlazarde/ansible_homelab/main/prep_vm.sh)"
    
This will:

1. Install cloud-init if it's not installed: `sudo apt install -y cloud-init`
2. Remove SSH host keys: `	sudo rm /etc/ssh/ssh_host_*`
3. If the machine identifier exists, then truncate it, usually in Unbuntu: `cat /etc/machine-id && sudo truncate -s 0 /etc/machine-id`
4. Create a symbolic link: ls -l /var/lib/dbus/machine-id || sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
5. Clean up packages: `(sudo apt clean; sudo apt autoremove) && sudo poweroff`

If there're problems connecting via SSH, try:

    sudo dpkg-reconfigure openssh-server

# Contributing
The issue tracker is the preferred channel for bug reports, features requests and submitting pull requests.

Please maintain the existing coding style. Add unit tests and examples for any new or changed functionality, if possible. Use the `.editorconfig` to maintain consistency.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# License
MIT

Ansible:registered: is a registered trademark of Red Hat Inc.

# Thanks to...
- [Techno Tim](https://www.youtube.com/channel/UCOk-gHyjcWZNj3Br4oxwh0A)
- [LearnLinuxTV](https://www.youtube.com/channel/UCxQKHvKbmSzGMvUrVtJYnUA)

As they've inspired me to get into the homelab server world, tought me Linux, Ansible, setting everything up, and they don't even know it.

# References
- [Ansible Documentation](https://docs.ansible.com/index.html)
- [Using Encrypted info with Ansible](https://www.redhat.com/sysadmin/ansible-playbooks-secrets)
- [How Ansible works](https://www.ansible.com/overview/how-ansible-works)
- [Ansible Playbook Examples](https://www.middlewareinventory.com/blog/ansible-playbook-example/)
- [Sample Ansible Setup](https://docs.ansible.com/ansible/latest/user_guide/sample_setup.html)
