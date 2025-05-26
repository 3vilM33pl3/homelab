# Homelab
This project contains everything related to maintaining and configuring the homelab.
## Setup
For bootstrapping, OS update/upgrade and K8s install we use Ansible in `iac_ansible`. And for installing in the K8 cluster we use Pulumi in `iac_k8`. 

Start with setting up SSh key authentication:
```shell
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-k3.ini ssh-key-auth.yml --ask-pass
```