clear
ansible-playbook playbooks/workstation_setup.yml --vault-password-file ~/.vault_key --ask-become-pass -C -v -v --tags test 