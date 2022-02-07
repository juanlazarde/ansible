#!/usr/bin/env bash
#-----------------------------------------------------
# Visit https://github.com/juanlazarde/ansible_homelab
# Licensed under the MIT License
#-----------------------------------------------------
#
# Syntax: bash ansible_install.sh [optional [-a] [-r] [-v] [-e [<filename>]] [-d <directory name>] [-h]]
#
# Normal usage; without arguments, will install ansible, scripts, and vault key.
#
#     --ansible, -a             : don't install Ansible and its dependencies.
#     --repository, -r          : don't download the repository with Ansible scripts from GitHub.
#     --vault, -v               : don't create a secret vault key
#     --encrypt, -e [<filename>]: tool to create a hashed ansible-encrypted variable. Optionally, save it as a file.
#     -d directory name: directory where you want to install the Ansible scripts. Default: ansible_scripts.
#     --help, -h                : help info
#
# More info:
#    - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu
#

# Exit on error
# set -e

# Define variables.
# -----------------
# Install ansible and the dependencies.
INSTALL_ANS="true"
# Retrieve and expand the repository from GitHub.
INSTALL_REP="true"
# Directory where the repository will be installed.
DEFAULT_DEST="ansible_scripts"
# Install the vault key
INSTALL_VLT="true"
# Secret vault: DO NOT SHARE THIS
DEFAULTVAULT=".vault_key"
# Encryption utility default
UTIL_ENCRYPT="false"
# Encrypted file with the variable just encrypted
ENCRYPTED_FILE=""

# Initialization
# File directory
readonly SCRIPT_BASE="$(cd $(dirname '${BASH_SOURCE[0]}') && pwd)"
# File name
readonly PROGNAME=$(basename $0)

SECRETVAULT="$SCRIPT_BASE/$DEFAULTVAULT"
DESTINATION="$SCRIPT_BASE/$DEFAULT_DEST"

# This is just cool info to have.
# # File name, without the extension
# readonly PROGBASENAME=${PROGNAME%.*}
# # Arguments
# readonly ARGS="$@"
# # Arguments number
# readonly ARGNUM="$#"

# Program usage
usage() {
	echo "Ansible scripts for workstations and servers."
	echo
    echo "Usage without arguments, will install ansible, scripts, and vault key."
    echo
	echo "Usage: bash $PROGNAME [optional [-a] [-r] [-v] [-e] [-d <directory name>] [-h]]"
	echo
	echo "Optional arguments:"
	echo
	echo "  -h, --help"
	echo "      this help text."
	echo "      DEFAULT: yes"
    echo
	echo "  -a, --ansible"
	echo "      don't install Ansible and its dependencies."
    echo "      DEFAULT: yes"
	echo
	echo "  -r, --repository"
	echo "      don't download the repository with Ansible scripts from GitHub."
    echo "      DEFAULT: yes"
	echo
    echo "  -v, --vault"
    echo "      don't create a secret vault key"
    echo "      DEFAULT: yes, here: $SECRETVAULT"
    echo
	echo "  -d <directory>"
	echo "      directory where you want to install the Ansible scripts."
    echo "      DEFAULT: $DESTINATION"
	echo
	echo "  -e, --encrypt <filename>"
	echo "      tool to create an ansible compatible hashed and encrypted variable."
    echo "      DEFAULT: no"
    echo "      <filename> is optional, and it will save the encrypted text to a file."

}

# Loop over command line options
while :
do
  case "$1" in
    -h|--help)          usage; exit 0;;
    -a|--ansible)       INSTALL_ANS="false";;
    -r|--repository)    INSTALL_REP="false";;
    -v|--vault)         INSTALL_VLT="false";;
    -d|--destination)   DESTINATION="$2";;
    -e|--encrypt)       UTIL_ENCRYPT="true"; ENCRYPTED_FILE="$2";;
    -*|--*)             echo "Invalid option '$1'. Use --help to see the valid options" >&2; exit 1;;
    *)                  break;;
  esac
  shift
done

if [ $INSTALL_ANS = "false" ] && [ $INSTALL_REP = "false" ] && [ $INSTALL_VLT = "false" ] && [ $UTIL_ENCRYPT = "false" ]; then
    echo "Invalid option. Use --help to see the valid options" >&2
    exit 1
fi

if [ $UTIL_ENCRYPT = "true" ]; then
    echo "Using [-e, --encrypt] option will disable all other options."
    INSTALL_ANS="false"
    INSTALL_REP="false"
    INSTALL_VLT="false"
fi

AT_LEAST_ONE="false"
if [ $INSTALL_ANS = 'true' ] || [ $INSTALL_REP = 'true' ] || [ $INSTALL_VLT = 'true' ]; then
    AT_LEAST_ONE="true"
fi

# Check whether the directory already exists.
if [ -d "$DESTINATION" ]; then
    echo "Directory '$DESTINATION' exists. Try another."
    exit 3
fi

# Update apt repository of packages.
updatePackages() {
    echo "#####################################"
    echo "#     Updating apt repositories     #"
    echo "#####################################"
    echo "To install these packages, you'll need 'sudo' powers."
    sudo apt update
}

# Install Ansible and dependencies.
installAnsible() {
    echo "#####################################"
    echo "# Installing Ansible & dependencies #"
    echo "#####################################"
    sudo apt install -y software-properties-common
    sudo apt-add-repository --yes ppa:ansible/ansible
    sudo apt update
    sudo apt install -y ansible
    sudo apt install -y openssh-client
    sudo apt install -y sshpass
    echo
    echo "Ansible and dependencies installed"
}

# Check if whois is installed. mkpasswd is part of the package
checkPackage() {
    dpkg -s $1 &> /dev/null
    if [ $? -ne 0 ]; then
        echo "I will need sudo priviledge to install $1."
        sudo apt install -y $1
        echo
    fi
}

# Download the repository with Ansible scripts from GitHub.
getAnsibleScripts() {
    echo
    echo "#####################################"
    echo "#      Getting ansible scripts      #"
    echo "#####################################"
    checkPackage "git"
    git clone https://github.com/juanlazarde/ansible_homelab.git "$DESTINATION"
    echo
    echo "Ansible scripts installed in '$DESTINATION'"
    cd "$DESTINATION"
}

# Create secret Ansible vault.
createVault() {
    echo
    echo "#####################################"
    echo "#      Create secret vault key      #"
    echo "#####################################"
    echo
    checkPackage "whois"
    echo "Enter the secret password for the vault. It will be hashed."
    set -C  # don't overwrite file
	mkpasswd -m sha-512 > $SECRETVAULT
    chmod 600 $SECRETVAULT
    set +C
    echo
    echo "Remember your password. Otherwise, delete the file and run this script again."
    echo "Secret key stored here '$SECRETVAULT'"
}

# Suggestions for next steps.
nextSteps() {
    echo
    echo "#####################################"
    echo "#             Next steps            #"
    echo "#####################################"
    echo
    echo "1. Get into the ansible directory:"
    echo "      $ cd $DESTINATION"
    echo "2. Edit ansible.cfg"
    echo "3. Edit hosts.yml"
    echo "4. Confirm connection to hosts:"
    echo "      $ ansible all -m ping"
    echo "5. Run workstation script:"
    echo "      $ bash workstation_setup.sh"
    echo "6. Run SSH deployment to hosts"
    echo "      $ bash deploy_ansible_ssh.sh"
    echo "7. Run remote host plays:"
    echo "      $ bash sever_setup.sh"
    echo
}

# Encryption utility for ansible variables.
ansibleEncrypt() {
    echo
    echo "#####################################"
    echo "#   Encryption with Ansible vault   #"
    echo "#####################################"
    echo
    echo "* Must have installed 'mkpasswd' part of the 'whois' pkg, 'ansible', and 'sed'"
    echo "* Encryption key location: $SECRETVAULT"
    echo "* If you want the output in a file, type:"
    echo "      $ bash $PROGNAME -e encrypted_text.txt"
    echo
    # Check that mkpasswd is installed (part of whois)
    checkPackage "whois"

    # Check that the Ansible Vault key was created.
    if [ -f "$SECRETVAULT" ]; then

        # Password request, hashing and encrypting. Dependeing on existance of file name after '-e' it will save or show.
        echo "Enter your password here. It will be hashed and encrypted. Remember the password."
        if [ "$ENCRYPTED_FILE" = "" ]; then
            mkpasswd --method=sha-512 | ansible-vault encrypt --vault-password-file $SECRETVAULT | sed '/$ANSIBLE/i \!vault |'
        else
            mkpasswd --method=sha-512 | ansible-vault encrypt --vault-password-file $SECRETVAULT | sed '/$ANSIBLE/i \!vault |' >> "$ENCRYPTED_FILE"
            echo
            echo "Saved encrypted text to $ENCRYPTED_FILE"
        fi

    else
        echo "Sectret Ansible Vault key is not available (i.e. not created)."
        echo "Run 'bash ansible_install -a -r'. This will create $SECRETVAULT"
    fi
}

if [ $AT_LEAST_ONE = 'true' ]; then
    echo "Let's install some ansible scripts."
    echo "-----------------------------------"
    echo
    updatePackages
fi

if [ $INSTALL_ANS = 'true' ]; then
    # echo "Install Ansible"
    installAnsible
fi

if [ $INSTALL_REP = 'true' ]; then
    # echo "Install Repository"
    getAnsibleScripts
fi

if [ $INSTALL_VLT = 'true' ]; then
    # echo "Install Vault"
    createVault
fi

if [ $AT_LEAST_ONE = 'true' ]; then
    nextSteps
fi

if [ $UTIL_ENCRYPT = 'true' ]; then
    ansibleEncrypt
fi
