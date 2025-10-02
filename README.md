# Homelab
This project contains everything related to maintaining and configuring the homelab.

For system configuration, OS updates/upgrades and software installation we use Ansible in `iac_ansible`.

## Setup SSH key authentication

Start with setting up SSH key authentication. The `ANSIBLE_HOST_KEY_CHECKING=False` is needed in case the host on which Ansible runs has done this before with older servers.
```shell
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/config/ssh-key-auth.yml --ask-pass
```

## Upgrade system
```shell
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/tasks/apt-upgrade-tasks.yml
```
