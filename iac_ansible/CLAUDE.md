# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an Ansible-based Infrastructure as Code (IaC) repository for managing a homelab environment. It automates the setup and configuration of a K3s Kubernetes cluster across multiple Raspberry Pi nodes and installs various software packages.

## Architecture

The repository is organized into several main components:

- **Inventory**: `inventory-homelab.ini` defines three hosts (white, pink, orange) with Python 3.11 interpreters
- **Cluster Management**: `cluster/` directory contains K3s server and agent installation playbooks
- **Configuration**: `config/` directory handles system configuration tasks like cgroups and SSH keys
- **Software Installation**: `software/` directory contains modular task files for installing various tools

## Key Components

### K3s Cluster Setup
- `cluster/k3s-server.yml`: Installs K3s server on the 'white' host with Traefik disabled
- `cluster/k3s-agent.yml`: Installs K3s agents on 'pink' and 'orange' hosts
- `k3s-agent-config`: Generated configuration file containing server connection details

### Main Playbooks
- `software-install.yml`: Master playbook that orchestrates software installation across all hosts
- `config/enable-cgroups.yml`: Enables cgroups required for container runtime

### Modular Tasks
All software installation is broken into individual task files in `software/` directory, making it easy to add or remove components.

## Common Commands

### Running Playbooks
```bash
# Install all software packages
ansible-playbook -i inventory-homelab.ini software-install.yml

# Set up K3s server (run first)
ansible-playbook -i inventory-homelab.ini cluster/k3s-server.yml

# Set up K3s agents (run after server)
ansible-playbook -i inventory-homelab.ini cluster/k3s-agent.yml

# Enable cgroups (required before K3s installation)
ansible-playbook -i inventory-homelab.ini config/enable-cgroups.yml

# Run specific tasks using tags
ansible-playbook -i inventory-homelab.ini software-install.yml --tags "always"
```

### Uninstalling K3s
```bash
# Uninstall K3s agents
ansible-playbook -i inventory-homelab.ini cluster/uninstall/k3-uninstall-agent.yml

# Uninstall K3s server
ansible-playbook -i inventory-homelab.ini cluster/uninstall/k3-uninstall-server.yml
```

## Development Workflow

1. **Adding New Software**: Create a new task file in `software/` directory and include it in `software-install.yml`
2. **Cluster Changes**: Modify files in `cluster/` directory for K3s-related changes
3. **Configuration Updates**: Add system configuration tasks to `config/` directory
4. **Testing**: Run playbooks against the homelab inventory to test changes

## Important Notes

- The K3s server generates a token and config file (`k3s-agent-config`) that agents use to join the cluster
- All software tasks use the `always` tag for consistent execution
- Cgroups must be enabled before installing K3s on Raspberry Pi systems
- The setup assumes Ubuntu/Debian-based systems with apt package manager