ansible-playbook playbook.yml -i hosts.yml --ask-become-pass --vault-password-file ~/.vault_key -l "servers" -t "update"
