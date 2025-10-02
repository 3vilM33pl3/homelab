# Ansible Infrastructure as Code

This directory contains Ansible playbooks and roles for managing homelab infrastructure and certificate authority configuration.

## Directory Structure

```
iac_ansible/
├── ca/                      # Certificate Authority specific files
│   └── inventory-ca.ini     # Inventory for CA server
├── config/                  # System configuration playbooks
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
├── install-ca.yml         # Certificate Authority setup playbook
└── install-cluster.yml    # Cluster nodes setup playbook
```

## Prerequisites

- Ansible 2.9+ installed on control machine
- SSH access to target hosts
- Python 3 installed on target hosts

## Common Usage

### Initial Setup

```bash
# Setup SSH key authentication (first time only)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-homelab.ini config/ssh-key-auth.yml --ask-pass
```

### Cluster Nodes Setup

```bash
# Install basic software on cluster nodes (white, pink, orange)
ansible-playbook -i inventory-homelab.ini install-cluster.yml

# System updates only
ansible-playbook -i inventory-homelab.ini tasks/apt-upgrade-tasks.yml
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
- **Important**: Replaces the incorrect default udev rules that come with the package

**Note on udev rules**: The default udev rules installed by the infnoise package are incorrect and must be replaced for proper device operation. The corrected rules ensure the device has appropriate permissions and is accessible by the infnoise service.

This hardware RNG is particularly important for the CA server as it generates root certificates and signs all other certificates in the infrastructure.

## Inventory Files

### inventory-homelab.ini
Defines the main homelab hosts:
- **white**: Main server node
- **pink**: Secondary node
- **orange**: Secondary node

### ca/inventory-ca.ini
Defines the Certificate Authority server host.

## Important Notes

- All hosts use Python 3.11 as the interpreter
- Software tasks use the "always" tag for consistent execution

## Adding New Software

1. Create a new task file in `tasks/` directory
2. Include the task file in `install-cluster.yml` or `install-ca.yml` as appropriate
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
- Check Python installation on target hosts for Ansible module execution
