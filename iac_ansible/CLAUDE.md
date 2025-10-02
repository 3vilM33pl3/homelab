# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an Ansible-based Infrastructure as Code (IaC) repository for managing a homelab environment. It automates the setup and configuration across multiple Raspberry Pi nodes and installs various software packages.

## Architecture

The repository is organized into several main components:

- **Inventory**: `inventory-homelab.ini` defines three hosts (white, pink, orange) with Python 3.11 interpreters
- **Configuration**: `config/` directory handles system configuration tasks like SSH keys
- **Software Installation**: `tasks/` directory contains modular task files for installing various tools

## Key Components

### Main Playbooks
- `install-ca.yml`: Certificate Authority setup playbook
- `config/ssh-key-auth.yml`: Sets up SSH key authentication

### Modular Tasks
All software installation is broken into individual task files in `tasks/` directory, making it easy to add or remove components.

## Common Commands

### Running Playbooks
```bash
# Setup SSH key authentication
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory-homelab.ini config/ssh-key-auth.yml --ask-pass

# Install Certificate Authority software
ansible-playbook -i inventory-homelab.ini install-ca.yml

# System updates
ansible-playbook -i inventory-homelab.ini tasks/apt-upgrade-tasks.yml
```

## Development Workflow

1. **Adding New Software**: Create a new task file in `tasks/` directory and include it in appropriate playbook
2. **Configuration Updates**: Add system configuration tasks to `config/` directory
3. **Testing**: Run playbooks against the homelab inventory to test changes

## Important Notes

- All software tasks use the `always` tag for consistent execution
- The setup assumes Ubuntu/Debian-based systems with apt package manager
