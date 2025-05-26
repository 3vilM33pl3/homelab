# Homelab
This project contains everything related to maintaining and configuring the homelab.

For bootstrapping, OS update/upgrade and K8s install we use Ansible in `iac_ansible`. And for installing in the K8 cluster we use Pulumi in `iac_k8`. 


## Setup SSH key authentication

Start with setting up SSh key authentication. The `ANSIBLE_HOST_KEY_CHECKING=False` is needed in case the host on which Ansible runs has done this before with older servers.
```shell
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-k3.ini ssh-key-auth.yml --ask-pass
```

## Upgrade system
```
ansible-playbook -i inventory-k3.ini apt-upgrade.yml
```

