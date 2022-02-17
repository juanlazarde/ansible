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
#     --no-ansible, -a            : don't install Ansible and its dependencies.
#     --no-repository, -r         : don't download the repository with Ansible scripts from GitHub.
#     --no-vault, -v              : don't create a secret vault key.
#     --encrypt, -e [filename]    : tool to create a hashed ansible-encrypted variable. Optionally, save it as a file.
#     -d directory name           : directory where you want to install the Ansible scripts. Default: ansible_scripts.
#     --help, -h                  : help info
#
# More info:
#    - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu
#

# Enable xtrace if the DEBUG environment variable is set
#DEBUG=true
[[ ${DEBUG-} =~ ^1|yes|true$ ]] && set -o xtrace && set -x      # Trace the execution of the script (debug)

# A better class of script...
set -o errexit          # Exit on most errors (see the manual)
set -o errtrace         # Make sure any error trap is inherited
set -o nounset          # Disallow expansion of unset variables
set -o pipefail         # Use last non-zero exit code in a pipeline

# DESC: Script initialization.
# ARGS: $@ (optional): Arguments provided to the script.
# OUTS: default variables, directory/file related variables.
#       $default_repository_dir: Directory where the repository will be installed.
#       $default_vault_name: Secret vault encryption key (DO NOT SHARE THESE FILES!!! i.e. add to .gitignore).
#       $default_salt_name: Salt file with salt to hash passwords.
#       $default_encrypted_name: Encrypted file with the variable just encrypted.
#       $default_salt: Default salt value.
#
#       $install_ansible: Install ansible and the dependencies.
#       $install_repository: Retrieve and expand the repository from GitHub.
#       $install_vault: Create the vault key file.
#       $util_encrypt: Hash and encrypt password utility.
function script_init() {
    # Default variables
    default_repository_dir="ansible_scripts"
    default_vault_name=".vault_key"
    default_salt_name=".vault_salt"
    default_salt=""

    # Initialization
    install_ansible='true'
    install_repository='true'
    install_vault='true'
    util_encrypt='false'

    # Read-only variables
    readonly script_params="$*"
    readonly home_dir=$(eval echo "~")
    readonly orig_cwd="${PWD}"
    readonly script_path="${BASH_SOURCE[0]}"
    readonly script_dir="$(dirname "${script_path}")"
    readonly script_name="$(basename "${script_path}")"
    readonly script_name_no_ext="${script_name%.*}"
    readonly vault_path="${home_dir}/${default_vault_name}"
    readonly salt_path="${home_dir}/${default_salt_name}"
    readonly default_repository_dir="${orig_cwd}/${default_repository_dir}"
    if [[ -n ${default_salt} ]]; then
        readonly salt=${default_salt}
    else
        readonly salt=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
    fi

    # Atlernative sources.
    # readonly orig_cwd="$(cd $(dirname '${BASH_SOURCE[0]}') && pwd)"
    # readonly script_name="$(basename $0)""
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
#       $install_ansible: if true it will install ansible
#       $install_repository: if true it will install the repository of ansible scripts
#       $install_vault: if true creates vault key in home folder.
#       $at_least_one: if true one of the three options above was selected.
#       $util_encrypt: if true none of the four variables above will be true, runs encryption func.
#       $repository_dir: is the destination dir for the repository.
function parse_params() {
    local param
    while [[ "$#" -gt 0 ]]; do
        param="${1-}"
        case ${param} in
            -h|--help)              script_usage; exit 0 ;;
            -a|--no-ansible)        install_ansible='false' ;;
            -r|--no-repository)     install_repository='false' ;;
            -v|--no-vault)          install_vault='false' ;;
            -d|--repository-dir)    repository_dir="${2-}"; shift ;;
            -e|--encrypt)           util_encrypt='true'; encrypted_name="${2-}"; break ;;
            *)                      printf '%s\n' "Invalid option '${param}'. Use --help to see the valid options" >&2; exit 1 ;;
        esac
        shift
    done

    # User must enter a valid option or combination of valid options. Exit if all options are false.
    if ! (${install_ansible} || ${install_repository} || ${install_vault} || ${util_encrypt}); then
        printf '%s\n' "Invalid option. Use --help to see the valid options" >&2
        exit 1
    fi

    # If the '-e' option is selected, then all of the other options are ignored.
    if ${util_encrypt}; then
        printf '%s\n' "Using [-e, --encrypt] option will disable all other options."
        install_ansible='false'; install_repository='false'; install_vault='false'; at_least_one='false'
    else
        [[ ${install_ansible} || ${install_repository} || ${install_vault} ]] && at_least_one='true'
        [[ -z "${repository_dir-}" ]] && repository_dir="${default_repository_dir}"
        if [[ ${install_repository} && -d "${repository_dir}" ]]; then printf "Directory '${repository_dir}' exists. Try another.\n"; exit 1; fi
    fi
}


# DESC: Script usage, when -h, --help are used as an option
# ARGS: None
# OUTS: None
function script_usage() {
    cat << EOF
    Ansible scripts for workstations and servers.

    Usage without arguments will install ansible, scripts, and vault key.

    Usage: bash ${script_name} [optional [-a] [-r] [-v] [-e [<filename>]] [-d <directory name>] [-h]]

    Optional arguments:

    -h, --help                : this help text.
    -a, --no-ansible          : don't install Ansible and dependencies. DEFAULT: ${install_ansible}
    -r, --no-repository       : don't download repository with scripts. DEFAULT: ${install_repository}
    -v, --no-vault            : don't create a secret vault key. DEFAULT: ${install_vault}
                                location:${vault_path}
    -d <directory>            : directory where you want to install the Ansible scripts.
                                location:${default_repository_dir}
    -e, --encrypt <filename>  : create ansible hashed and encrypted variable. DEFAULT: ${util_encrypt}
                                filename is optional
EOF
}

# DESC: Header.
# ARGS: $at_least_one has to be true
# OUTS: None
function header() {
    ! ${at_least_one} && return
    printf '%s\n'   "-----------------------------------" \
                    "Let's install some ansible scripts." \
                    "-----------------------------------" \
                    ""
}

# DESC: Update apt repository of packages, if last the update was older than a day.
# ARGS: $at_least_one has to be true
# OUTS: None
function updatePackages() {
    ! ${at_least_one} && return
    printf '%s\n'   "#####################################" \
                    "#     Updating apt repositories     #" \
                    "#####################################"
    # Skip updating if it has been less than a day.
    if [[ -z "$(find -H /var/lib/apt/lists -maxdepth 0 -mtime 0)" ]]; then
        printf "To install these packages, you'll need 'sudo' powers.\n"
        sudo apt update
    else
        printf "Repositories were updated less than a day ago.\n"
    fi
    printf "\n"
}

# DESC: Install Ansible and dependencies.
# ARGS: $install_ansible has to be true
# OUTS: None
function installAnsible() {
    ! ${install_ansible} && return
    printf '%s\n'   "#####################################" \
                    "# Installing Ansible & dependencies #" \
                    "#####################################"
    sudo apt install -y software-properties-common
    sudo apt-add-repository --yes ppa:ansible/ansible
    sudo apt update
    sudo apt install -y ansible
    sudo apt install -y openssh-client
    sudo apt install -y sshpass
    printf "\n"
}

# DESC: Checks if a package is installed, i.e. whois as mkpasswd is part of the package
# ARGS: "package" name
# OUTS: None
function checkPackage() {
    dpkg -s "${1}" &> /dev/null
    if [ $? -ne 0 ]; then
        printf "%s\n" "I will need sudo priviledge to install ${1}."
        sudo apt install -y "${1}"
        printf "\n"
    fi
}

# DESC: Download the repository with Ansible scripts from GitHub.
# ARGS: $install_repository has to be true
# OUTS: None
function getAnsibleScripts() {
    ! ${install_repository} && return
    printf '%s\n'   "#####################################" \
                    "#      Getting ansible scripts      #" \
                    "#####################################"
    checkPackage "git"
    git clone https://github.com/juanlazarde/ansible_homelab.git "${repository_dir}"
    printf "\nAnsible scripts installed in '$repository_dir'\n"
}

# DESC: Create secret Ansible vault file and salt for hashing, using mkpasswd.
# ARGS: $install_vault has to be true
# OUTS: None
function createVault() {
    ! ${install_vault} && return
    printf '%s\n'   "#####################################" \
                    "#      Create secret vault key      #" \
                    "#####################################"
    checkPackage "whois"
    set -C  # don't overwrite file
    printf '%s' "${salt}" > ${salt_path}
    chmod 600 ${salt_path}
    printf "Enter the secret password for the vault. It will be hashed.\n"
	mkpasswd --method=sha-512 --salt=${salt} | tr -d '\n' > ${vault_path}
    chmod 600 ${vault_path}
    set +C
    printf '%s\n'   "Remember your password. Otherwise, delete the vault key and salt file, and run this script again." \
                    "If you don't want to install ansible and the script, use options '-a -r' to skip." \
                    "Secret key stored here '${vault_path}'" \
                    "Secret salt stored here '${salt_path}'" \
                    ""
}

# DESC: Next step instructions.
# ARGS: $at_least_one has to be true
# OUTS: None
function nextSteps() {
    ! ${at_least_one} && return
    cat << EOF

    #####################################"
    #             Next steps            #"
    #####################################"

    1. Get into the ansible directory:"
        $ cd ${repository_dir}"
    2. Edit ansible.cfg"
    3. Edit hosts.yml"
    4. Create hashed & encrypted variables with '${script_name} -e'"
    5. Confirm connection to hosts:"
        $ ansible all -m ping"
    6. Run workstation script:"
        $ bash workstation_setup.sh"
    7. Run SSH deployment to hosts"
        $ bash deploy_ansible_ssh.sh"
    8. Run remote host plays:"
        $ bash sever_setup.sh"

EOF
}

# DESC: Encryption utility for ansible variables.
# ARGS: $util_encrypt has to be true
# OUTS: None
function ansibleEncrypt() {
    ! ${util_encrypt} && return
    printf '%s\n'   "#####################################" \
                    "#   Encryption with Ansible vault   #" \
                    "#####################################" \
                    "" \
                    "* Must have installed 'mkpasswd' part of the 'whois' pkg, 'ansible', and 'sed'" \
                    "* Encryption key location: ${vault_path}" \
                    "* Encryption salt location: ${salt_path}" \
                    "* If you want the output in a file, type:" \
                    "      $ bash ${script_name} -e encrypted_text.txt" \
                    ""
    # Check that mkpasswd is installed (part of whois)
    checkPackage "whois"

    # Read the secret salt file if it was created (otherwise use the default, set above)
    [[ -f "${salt_path}" ]] && current_salt=$(cat ${salt_path}) || current_salt=${salt}

    # Check that the Ansible Vault key was created.
    if [ -f "${vault_path}" ]; then
        # Password request, hashing and encrypting. Depending on existance of file name after '-e' it will save or show.
        printf "Enter your password here. It will be hashed and encrypted. Remember the password.\n"
        if [ -n "${encrypted_name}" ]; then
            mkpasswd --method=sha-512 --salt=${current_salt} | \
            tr -d '\n' | \
            ansible-vault encrypt --vault-password-file ${vault_path} | \
            sed '/$ANSIBLE/i \!vault |'
        else
            mkpasswd --method=sha-512 --salt=${current_salt} | \
            tr -d '\n' | \
            ansible-vault encrypt --vault-password-file ${vault_path} | \
            sed '/$ANSIBLE/i \!vault |' \
            > "${encrypted_name}"
            printf "\nSaved encrypted text to ${encrypted_name}"
        fi
        # To Decrypt and check that everything is ok:
        # ansible localhost -m ansible.builtin.debug -a var="test" -e "@test.yml" --vault-password-file ~/.vault_key

    else
        printf  "\nSecret Ansible Vault key is not available (i.e. not created)." \
                "Run 'bash ${script_name} -a -r'. This will create ${vault_path}"
    fi
    printf "\n"
}


# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {

    script_init "$@"
    parse_params "$@"

    header
    updatePackages
    installAnsible
    getAnsibleScripts
    createVault
    nextSteps

    ansibleEncrypt
}

# Invoke main with args
main "$@"

# Approach for Bash:  https://github.com/ralish/bash-script-template/blob/main/template.sh
# Reference for Bash: https://www.cheatsheet.wtf/bash/
