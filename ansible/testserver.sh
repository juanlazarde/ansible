clear
set -v
ansible-playbook playbooks/server_setup.yml --ask-become-pass --vault-password-file ~/.vault_key --check --verbose --verbose --tags test