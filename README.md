**Setup and Update your Homelab Server... easy**

---

# Ultimate Homelab with Ansible

These scripts help setup and update your workstation and servers with Ansible agent-less package, so nothing is installed in the servers!

Ansible scripts are made of *playbooks*. These playbooks include *plays* that:

    - update and upgrade all packages, rebooting if needed
    - install unattended-upgrade packages
    - create and elevate admin user to super user level
    - disable root passwords
    - disable remote root logins
    - create SSH key pairs, updating remote hosts with the public key
    - install zsh, oh-my-zsh, with powerlevel10k and custom plugins, and sets the default shell
    - remove Ubuntu's Snap services and leave-behinds
    - maximize LVM partitions
    - customize the hostname
    - update the timezone
    - install "qemu-guest-agent" if it's a Proxmox VM
    - install and configures UFW (uncomplicated fire wall)
    - install and configures fail2ban to ban multiple login attempts
    ... for now

These scripts are in an early stage, but work fine on my setup. Post your issues and I'll try to help. Most of the material is commented or self-explanatory.

Once installed, your workstation will be 90% ready. I can't think about what the other 10% would be, but I won't say it'll be 100% ready. Open a discussion for more features. Servers have a different story, servers are more like 10% ready to go. They'll be accessible via ansible, with ssh keys, updated, root-locked, ufw and fail2ban up and running, super user created and unattended upgrades installed, to name a few. The rest is up to you. Whether it will be a web server, NAS, proxy manager, VPN, etc. Feel free to open a discussion on what specific servers would be most helpful.

**The code here, will not run out-of-the-box**. You need to configure hosts.yml and possibly ansible.cfg.

#### Table of Contents
- [Contents](#contents)
- [Install](#install)
- [Install TL;DR](#installtldr)
- [Usage](#usage)
- [Debug](#debug)

#### My setup
- Bare metal rack server.
- Proxmox Hypervisor.
- Multple VM's and LXD's.
- Workstation is a Windows 10 with Ubuntu WSL.
- Testing all on Virtualbox VM's.
- Mostly using Ubuntu or lightweight variant.

#### Supported platforms
- Ubuntu 20.04 LTS.
- Windows WSL Ubuntu 20.04.

# Contents
- `ansible_install.sh` bash to install ansible, clone this repository, install vault key, and encrypt. **Start here**
- `.\ansible` directory has ansible scripts, configs, playbooks, hosts, and roles.
- `.\ansible\ansible.cfg` all of ansible's parameters.
- `.\ansible\hosts.yml` customize your hosts and variables here. I didn't create global_vars or vars.
- `.\ansible\deploy_ssh.yml` playbook that creates ssh key pairs and deploys these to the hosts.
- `.\ansible\playbook.yml` playbook that makes everything happen.
- `.\ansible\run.sh` lazy bash script to speed up typing boring commands. This is your quarterback for the plays.
- `~\.vault_key` this file is outside of the repository (of course!). Holds the keys to the castle. Wherever you see a `!vault |` and garbled text, this is what you need to encrypt/decrypt. Use the `ansible_install.sh` to make this file super easy.
- `prep_vm.sh` helps prepare VM. I.e. removes machine-id, etc.

# Overview
1. You install Ansible and this repository on your machine.
2. Configure a couple of files to meet your needs.
3. Then, you can either run the scripts to configure your machine as a workstation, set a remote machine as a workstation, or set multiple machines as servers.

# Install
Download the installation script: `ansible_install.sh` by running this line:
    
    curl -LJO https://raw.githubusercontent.com/juanlazarde/ansible_homelab/main/ansible_install.sh

**or** get  `ansible_install.sh` [here](ansible_install.sh) and save it raw as `ansible_install.sh`.
 
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

    Usage without arguments will install ansible, scripts, and vault key.

    Usage: bash ansible_install.sh [[-a|--no-ansible] [-r|--no-repository] [-v|--no-vault] | [-e|encrypt [FILENAME]] [-d DIRECTORY] [-h|--help]

    Optional arguments:

    -h, --help                : this help text.
    -a, --no-ansible          : don't install Ansible and dependencies.
    -r, --no-repository       : don't download repository with scripts.
    -v, --no-vault            : don't create a secret vault key.
    -d <directory>            : directory where you want to install the Ansible scripts.
    -e, --encrypt <filename>  : create ansible hashed and encrypted variable. DEFAULT: false

## Configure the installation
Edit the following files to meet your needs:

    cd ansible_scripts/ansible
    nano ansible.cfg
    nano hosts.yml

### Encryption
To create hashed and encrypted variables, like passwords, use

    bash ansible_install.sh -e

To save them to files you can:

    bash ansible_install.sh -e encrypted_text.txt

Now you'll need to copy this text and paste it to the `hosts.yml` file for example. When you can't copy/paste, here're a couple of ways we can do this. Feel free to offer other ideas or request a better solution through the issue tracker. `pbcopy` doesn't work on Ubuntu.
1. Insert encrypted text directly into hosts.yml.
2. Pull encrypted file directly in the task.

#### 1. Insert text into hosts.yml
Run this command:

    sed -i.bak "/local_password:/r encrypted_text.txt" ~/ansible_scripts/ansible/hosts.yml

Explanation:
* `sed` stream editor that filters and transforms text.
* `-i.bak` creates a backup of the original file. In this case, `hosts.yml`
* `/local_password:` command to search for string (`local_password`) within the file (`hosts.yml`)
* ` /r encrypted_text.txt` reads the file `encrypted_text.txt`, which we created in the previous step.
* `~/ansible_scripts/ansible/hosts.yml` this is the file being edited.

The variables I've set to encrypted values in `hosts.yml`, are:
* `local_password`
* `guest_password`

But, we'll need to edit it to adjust the proper YAML format. Watch for any spaces in wrong places, trim trailing spaces. In example:

    local_password: !vault |
        $ANSIBLE_VAULT;1.1;AES256
        376563383...

So,

    nano hosts.yml

Remember to delete the `encrypted_text.txt`:

    rm encrypted_text.txt

#### 2. Pull the encrypted text directly from the file.
Insert the following line where the info is required:

    "{{ lookup('file', './encrypted_text.txt', errors='warn') }}"

One last word about the output. This file 1) hashes and 2) encrypts. So, if you decrypt the file or look it up, like mentioned just above, you'll see a hash. Your password is nowhere to be found. Remember this.

## Check connection to hosts
Enter the following command to make sure ansible works and that you can connect to your hosts. It may fail if you don't have aproper SSH connection to the hosts:
    
    ansible all -m ping

## <a name="installtldr"></a>TL;DR
Download

    curl -LJO https://raw.githubusercontent.com/juanlazarde/ansible_homelab/main/ansible_install.sh

Install

    bash ansible_install.sh
    cd ansible_scripts

Configure

    bash ansible_install.sh -e >> /ansible_scripts/ansible/hosts.yml
    cd ansible

Test

    bash run.sh workstations setup --debug --step

Run

    bash run.sh workstations setup 

# Usage
I've created a `run.sh` bash script to simplify my life. But, you can just as easily write command lines.

## First, create and deploy SSH key pair
Start here to make sure there's a proper connection to the hosts. This will run in two stages. First, creates a passwordless SSH key pair for the current machine. Second stage, deploys the public key to all the hosts.

    cd ~/ansible_scripts/ansible
    bash run.sh --deploy-ssh

get help with `bash run.sh --help`.

It will ask for several passwords. First, is the localhost sudo password. Then, it will ask for the remote user's SSH password (usually the same as the user's password) Lastly, it'll ask for a remote sudo password, usually pressing ENTER will do it.

This will create a passwordless private and public key in your local `~/.ssh/` directory, then it will connect to all other hosts and will push the public key to their `~/.ssh/authorized_keys`. You can then test it by `ssh -i ~/.ssh/<ansible key> <remote_user>@<host_ip>` and it shouldn't ask for a password. Success!

This script basically does the following:

    ansible-playbook deploy_ssh.yml --limit localhost
    ansible-playbook deploy_ssh.yml --ask-pass --limit "all:!localhost"

You can target a specific host via: `--limit 192.168.0.17`

## Next, workstation
The script will update and install workstation-client related items. These 'workstation' plays can be applied to the computer you're on; a.k.a. localhost, or to a remote host.

    bash run.sh workstations setup

**or**

if you've set up the `ansible.cfg` file correctly:

    ansible-playbook playbook.yml --limit workstations --tags setup

**or**

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup"

Notice the following:
1. `ask-become-pass` will request sudo password, which is needed for some plays.
2. `--vault-password-file ~/.vault_key` is the secret file that helps decrypt `!vault` variables.
3. `-l "workstations"` it limits the plays to be applied to the workstations defined in `host.yml`.
4. `-t "setup"` it limits the plays to those tagged for setup.

Some ansible quirks:

- `Sorry, try again`. May happen if you've entered the wrong sudo password. Action -> Hit CTRL+C, run again.
- `reboot` module is not executable for a local connection. Meaning, it won't reboot the workstation with the ansible agent. Action -> `sudo shutdown -r now`

## Finally, setup all server.
These are all the plays to be applied to the server group only. These are the remote hosts, like Apache, TrueNas, reverse-proxy, etc.

    bash run.sh servers setup

**or**

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "servers" -t "setup"

## Dry runs or checks without impact or changes to the system.
You'll need to include the flag `-C` with the ansible command. For extra verbosity you'll add `-vvv` to the command. i.e.

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup" -C -vvv

**or**

    bash run.sh workstations setup --debug


# Tags and Limits
To target 'workstations' only, use the arguments `-l "workstations"`, for servers `-l "servers"`.

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

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup" --start-at-task="debugging" --step -vvv

Evaluate a variable with a dummy tasK:

    - name: debugging
      debug: msg="{{ some.variable}}"

**also**

    bash run.sh workstations setup --args --start-at-task="test" --step --debug

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
