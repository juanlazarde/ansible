**Setup and Update your Homelab Server... easy**

---

# Homelab ansible script

These scripts help setup and update your workstation and servers with an agent-less package, so nothing installed in the servers!

These *playbooks* include *plays* such as:

    - apt updating, upgrading, and rebooting (if needed)
    - unattended-upgrade installation
    - elevating admin user to super user level
    - disabling root password
    - creating SSH key pairs and updating remote hosts with the public key
    - disabling remote root login
    - installs zsh, oh-my-zsh, with auto suggestions plugin. Sets as default shell
    - removes Ubuntu's snap services and leave-behinds
    - maximizes LVM partitions
    - customizes the hostname
    - updates the timezone
    - installs "qemu-guest-agent" if it's a Proxmox VM
    - installs and configures UFW (uncomplicated fire wall)
    - installs and configures fail2ban to ban multiple login attempts
    ... for now

These scripts are in an early stage, but work fine on my setup. Post your issues and I'll try to help. I'm sharing this repository as a lot comes from developers on GitHub and other sources (like YouTube) and I'm trying to give back.

**The code here, will not run out-of-the-box. You need to configure a couple of files listed below (ansible.cfg, hosts.yml).**

## My setup
- Bare metal rack server.
- Proxmox Hypervisor
- Multple VM's and LXD's
- Workstation is a Windows 10 with Ubuntu WSL
- Testing all on Virtualbox VM's
- Mostly using Ubuntu or light-weight debian/Ubuntu versions and Docker

# Contents
- `ansible_install.sh` bash to install ansible, clone this repository, install vault key, and encrypt secrets. **Start here**
- `.\ansible` has ansible scripts, configs, playbooks, hosts, & roles.
- `.\ansible\ansible.cfg` all of ansible's parameters. **If you've installed ansible, Start here**.
- `.\ansible\hosts.yml` customize your hosts and variables here. (no global_vars or vars around). **Then here**
- `.\ansible\playbook.yml` server & workstation plays.
- `.\ansible\*.sh` lazy bash scripts to speed up typing boring commands.
- `~\.vault_key` this file is outside of the repository (of course!). Holds the keys to the castle. Wherever you see a `!vault |` and garbled text, this is what you need to encrypt/decrypt. Use the `ansible_install.sh` to make this file super easy.

# Install
Download the installation script: `ansible_install.sh` by running this line:
    
    $ curl -LJO https://raw.githubusercontent.com/juanlazarde/ansible/main/ansible_install.sh

**or** get  `ansible_install.sh` [here](ansible_install.sh) and save it as `ansible_install.sh`.
 
 Run as:

    $ sh ansible_install.sh

This script downloads Ansible with dependencies, installs this git repository locally, creates the vault key, and it helps encrypt information to be inserted to the host.yml.

**OR**

Clone the repository to your ansible-enabled host:

    $ git clone https://github.com/juanlazarde/ansible ~/ansible_scripts
    $ cd ansible_scripts

and run the commands following the guide below.

Make the most out of `ansible_install.sh`:

    Syntax: sh ansible_install.sh [optional [-a] [-r] [-v] [-e] [-d <directory name>] [-h]]

    Normal usage; without arguments, will install ansible, scripts, and vault key.

    --ansible, -a    : don't install Ansible and its dependencies.
    --repository, -r : don't download the repository with Ansible scripts from GitHub.
    --vault, -v      : don't create a secret vault key
    --encrypt, -e    : tool to create an ansible compatible hashed and encrypted variable.
    -d directory name: directory where you want to install the Ansible scripts.
    --help, -h       : help info

## Configure the installation
Edit the following files to meet your needs:

    $ cd ansible_scripts
    $ nano ansible.cfg
    $ nano hosts.yml

Remember to use the `sh ansible_install.sh -e` command to create encrypted variables, like passwords. To save them to files you can `sh ansible_install.sh -e > encrypted_text.txt`


## Check connection to hosts
Enter the following command to make sure ansible works and that you can connect to your hosts:
    
    $ ansible all -m ping

# Supported platforms
- Ubuntu 20.04 LTS
- Windows WSL Ubuntu 20.04

# Usage
## First, workstation
The script will update and install workstation-client related items. Including the creation of ansible ssh keys to be sent to the hosts.

    $ sh workstation_setup.sh

**or**

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup"

## Then, deploy the ansible ssh keys to all servers-hosts.

    $ sh deploy_ansible_ssh.sh

## Finally, setup all server-hosts.

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "servers" -t "setup"

**or**

    $ sh server_setup.sh

## Dry runs or checks without impact or changes to the system.
You'll need to include the flag `-C` a the end of the ansible command.
For extra verbose youll add `-vvv` to the command. i.e.

    ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "workstations" -t "setup" -C -vvv


# Tags and Limits
To target workstations only, use the arguments `-l "workstation"`, for servers `-l "server"`.

To run setups only, use `-t "setup"`, for updates `-t "update"`, for ssh deployment `-t "ssh"`

# Ansible common commands
## Install:
	$ sudo apt update
	$ sudo apt-add-repository --yes --update ppa:ansible/ansible
	$ sudo apt install -y ansible software-properties-common sshpass openssh-server

Create SSH key and profile:

    Create the SSH Key pair. Never share the private one (wihout extension).
    $ ssh-keygen -t ed25519 -C "Ansible" -f ~/.ssh/ansible -q -N ""
    
    Add Public SSH key to authorized_keys in the host.
    $ ssh-copy-id -i ~/.ssh/ansible.pub <remote_IP>

    (optional) Minimizes entering SSH password during a session.
    $ eval $(ssh-agent) && ssh-add

    (optional, optional) Add the command above as an alias: ssha.
    $ echo ""alias ssha='eval $(ssh-agent -s) && ssh-add ~/.ssh/ansible'"" >> ~/.zshrc >> ~/.bashrc


Test connection:

    $ ansible -i hosts <remote_IP> -m ping --user <user> --ask-pass -o
	or
	$ ansible -i hosts ubuntu -m ping --key-file ~/.ssh/ansible -o
	
## Usage
	Gather hosts info
	$ ansible all -m gather_facts
	
	Send a command to all hosts
	$ ansible all -m apt -a name=vim-nox --become --ask-become-pass
	
	Automate items in playbook to all hosts
	$ ansible-playbook -i hosts playbooks/upgrade_apt.yml \
	--user someuser --ask-pass --ask-become-pass
	or
	$ ansible-playbook playbooks/upgrade_apt.yml --ask-become-pass
	
	-----------------------------
    --> Encrypting with Vault <--
    -----------------------------
	$ sudo apt update && sudo apt install -y whois # to install mkpasswd
	$ mkpasswd -m sha-512 > ~/.vault_key && chmod 600 ~/.vault_key
	
	Encrypt::
	$ ansible-vault encrypt --vault-password-file ~/.vault_key <filename>
	
	Decrypt:
	$ ansible-vault decrypt --vault-password-file ~/.vault_key <filename>
	
	Edit:
	$ ansible-vault edit --vault-password-file ~/.vault_key <filename>
	
	Using ansible playbook with vault:
	$ ansible-playbook site.yml --ask-become-pass --vault-password-file ~/.vault_key
	
	Create an encrypted and hashed password variable
	$ mkpasswd --method=sha-512 --salt=1234asdf | ansible-vault encrypt --vault-password-file ~/.vault_key | sed '/$ANSIBLE/i \!vault |'
	
	Download and execute from GIT
	$ sudo ansible-pull --vault-password-file ~/.vault_key -U https://github.com/juanlazarde/ansible.git

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

# Thanks to...
As they've inspired me to get into the homelab server world, tought me Linux, Ansible, setting everything up, and they don't even know it.
- [Techno Tim](https://www.youtube.com/channel/UCOk-gHyjcWZNj3Br4oxwh0A)
- [LearnLinuxTV](https://www.youtube.com/channel/UCxQKHvKbmSzGMvUrVtJYnUA)

# References
- [Ansible Documentation](https://docs.ansible.com/index.html)
- [Using Encrypted info with Ansible](https://www.redhat.com/sysadmin/ansible-playbooks-secrets)
- [How Ansible works](https://www.ansible.com/overview/how-ansible-works)
- [Ansible Playbook Examples](https://www.middlewareinventory.com/blog/ansible-playbook-example/)
- [Sample Ansible Setup](https://docs.ansible.com/ansible/latest/user_guide/sample_setup.html)
