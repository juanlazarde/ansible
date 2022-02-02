**Setup and Update your Homelab Server... easy**

---

# Homelab ansible script

Scripts here help setup and update the workstation/client and the servers/hosts, with an agent-less package (nothing installed in the servers, all SSH'd).

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

These scripts are in an early stage, but work fine on my setup. Post your issues, and I'll try to help. I'm sharing this repository as a lot comes from developers on GitHub and other sources (like YouTube), and I'm trying to give back.

## My setup
- Bare metal rack server.
- Proxmox Hypervisor
- Multple VM's and LXD's
- Workstation is a Windows 10 with Ubuntu WSL
- Testing all on Virtualbox VM's
- Mostly using Ubuntu or light-weight debian/Ubuntu versions and Docker

# Contents
- `ansible_install.sh` bash to install ansible and clone this repository. **Start here**
- `.\ansible` has ansible scripts, configs, playbooks, hosts, & roles.
- `.\ansible\ansible.cfg` all of ansible's parameters. **If you've installed ansible, Start here**.
- `.\ansible\hosts.yml` customize your hosts and variables here. (no global_vars or vars around). **Then here**
- `.\ansible\server_*.yml` server, lazy bash scripts to speed up typing boring commands.
- `.\ansible\workstation_*.yml` workstation, lazy bash scripts to speed up typing boring commands.
- `.\ansible\test_*.yml` ansible plays for testing, verbose and no changes `--tags test -c -vvv`.
- `~\.vault_key` this file is outside of the repository (of course!). Holds the keys to the castle. Wherever you see a `!vault |` and garbled text, this is what you need to encrypt/decrypt.

# Install
Download or copy and create an .sh file with the contents of `ansible_install.sh`. Run as:

    $ sh ansible_install.sh

This will download Ansible and its dependencies. It will also clone this repository.

# Supported platforms
- Ubuntu 20.04 LTS
- Windows WSL Ubuntu 20.04

# Usage
Go to the script's home directory:

    $ cd ansible_scripts

Running setup for the servers, where I'll make sudo-level changes, and decrypt with my key file.

    $ ansible-playbook -i hosts.yml playbooks/server_setup.yml --ask-become-pass --vault-password-file ~/.vault_key

Running tests for my servers, where I'll need to have elevated priviledges (sudo-level, but no changes will be made), decypt with my key file, be on the no-change mode, and extra-extra verbose (to see what's going on under the hood), and will run only those tasks tagged with `-tags test`.

    $ ansible-playbook -i hosts.yml playbooks/server_setup.yml --ask-become-pass --vault-password-file ~/.vault_key --check -vvv --tags test

There're individual bash files with different command lines depending on server/workstation and update/setup.

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

Please maintain the existing coding style. Add unit tests and examples for any new or changed functionality, if possible.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# License
MIT

# Thanks to...
- [Techno Tim](https://www.youtube.com/channel/UCOk-gHyjcWZNj3Br4oxwh0A)
- [LeaenLinuxTV](https://www.youtube.com/channel/UCxQKHvKbmSzGMvUrVtJYnUA)

# References
- [Ansible Documentation](https://docs.ansible.com/index.html)
- [RedHat - Using Encrypted info with Ansible](https://www.redhat.com/sysadmin/ansible-playbooks-secrets)
- [How Ansible works](https://www.ansible.com/overview/how-ansible-works)
- [Ansible PLaybook Examples](https://www.middlewareinventory.com/blog/ansible-playbook-example/)
- [Sample Ansible Setup](https://docs.ansible.com/ansible/latest/user_guide/sample_setup.html)