# Ansible Infrastructure as Code

This directory contains Ansible playbooks and roles for managing homelab infrastructure, including Kubernetes cluster setup and certificate authority configuration.

## Directory Structure

```
iac_ansible/
├── ca/                      # Certificate Authority specific files
│   └── inventory-ca.ini     # Inventory for CA server
├── cluster/                 # K3s Kubernetes cluster setup
│   ├── k3s-server.yml      # K3s server installation
│   ├── k3s-agent.yml       # K3s agent installation
│   └── uninstall/          # K3s uninstallation playbooks
├── config/                  # System configuration playbooks
│   ├── enable-cgroups.yml  # Enable cgroups for K3s
│   └── ssh-key-auth.yml    # Setup SSH key authentication
├── tasks/                  # Individual software installation tasks
│   ├── apt-upgrade-tasks.yml
│   ├── vim-task.yml
│   ├── yubikey-task.yml
│   ├── step-cli-task.yml
│   ├── step-ca-task.yml
│   ├── ntp-task.yml
│   └── ...
├── inventory-homelab.ini   # Main homelab inventory
├── software-install.yml    # Master software installation playbook
└── install-ca.yml         # Certificate Authority setup playbook
```

## Prerequisites

- Ansible 2.9+ installed on control machine
- SSH access to target hosts
- Python 3 installed on target hosts (or use bootstrap commands below)

## Common Usage

### Initial Setup

```bash
# Setup SSH key authentication (first time only)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-homelab.ini config/ssh-key-auth.yml --ask-pass
```

### K3s Cluster Management

```bash
# Enable cgroups (required before K3s installation on Raspberry Pi)
ansible-playbook -i inventory-homelab.ini config/enable-cgroups.yml

# Install K3s server (on 'white' host)
ansible-playbook -i inventory-homelab.ini cluster/k3s-server.yml

# Install K3s agents (on 'pink' and 'orange' hosts)
ansible-playbook -i inventory-homelab.ini cluster/k3s-agent.yml

# Uninstall K3s cluster
ansible-playbook -i inventory-homelab.ini cluster/uninstall/k3-uninstall-agent.yml
ansible-playbook -i inventory-homelab.ini cluster/uninstall/k3-uninstall-server.yml
```

### Software Installation

```bash
# Install all software packages on homelab
ansible-playbook -i inventory-homelab.ini software-install.yml

# Install with specific tags
ansible-playbook -i inventory-homelab.ini software-install.yml --tags "apt-upgrade"
```

### Certificate Authority Setup

```bash
# Setup CA server with all required software
ansible-playbook -i ca/inventory-ca.ini install-ca.yml
```

### Infnoise True Random Number Generator (TRNG)

The Certificate Authority server uses an Infnoise TRNG hardware device to enhance cryptographic security. This provides:

- **Hardware entropy source**: True random numbers from thermal noise
- **Enhanced key generation**: Improved randomness for certificate private keys
- **FIPS compliance**: Meets requirements for high-security environments
- **Continuous operation**: Feeds entropy to the system's random pool

The Infnoise device is automatically configured during CA setup via the `tasks/infnoise-task.yml` playbook, which:
- Installs necessary drivers and software
- Configures the device for automatic startup
- Integrates with the system's entropy pool
- Ensures proper permissions for the step-ca service

This hardware RNG is particularly important for the CA server as it generates root certificates and signs all other certificates in the infrastructure.

## Inventory Files

### inventory-homelab.ini
Defines the main homelab hosts:
- **white**: K3s server node
- **pink**: K3s agent node
- **orange**: K3s agent node

### ca/inventory-ca.ini
Defines the Certificate Authority server host.

## Important Notes

- K3s is installed with Flannel CNI disabled (for using Cilium instead)
- All hosts use Python 3.11 as the interpreter
- The `k3s-agent-config` file is automatically generated during server setup
- Software tasks use the "always" tag for consistent execution
- CA server runs on Alpine Linux and uses `doas` for privilege escalation

## Adding New Software

1. Create a new task file in `tasks/` directory
2. Include the task file in `software-install.yml` or `install-ca.yml`
3. Use appropriate tags for conditional execution

Example task file:
```yaml
---
- name: Install package
  apt:
    name: package-name
    state: present
```

## Troubleshooting

- If SSH connection fails, check SSH key authentication setup
- For K3s issues, ensure cgroups are enabled and reboot if necessary
- Check Python installation on target hosts for Ansible module execution
- For Alpine Linux hosts, some tasks may need to use `raw` module initially