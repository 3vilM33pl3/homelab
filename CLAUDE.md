# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a multi-component homelab infrastructure repository containing:
- **iac_ansible/**: Ansible-based Infrastructure as Code for system configuration and software installation
- **raspi-info-display/**: Rust application for Raspberry Pi OLED display

## Architecture

### Ansible Infrastructure (iac_ansible/)
- **Hosts**: Three Raspberry Pi nodes (white, pink, orange) defined in `inventory-homelab.ini`
- **Modular Design**: Software installation broken into individual task files in `tasks/` directory

### Raspberry Pi Display (raspi-info-display/)
- **Language**: Rust application using embedded-hal for OLED display
- **Hardware**: SSD1306 OLED display showing system metrics

## Common Commands

### Ansible Operations
```bash
# Setup SSH key authentication (initial setup)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/config/ssh-key-auth.yml --ask-pass

# System updates
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/tasks/apt-upgrade-tasks.yml
```

### Rust Application (raspi-info-display/)
```bash
# From raspi-info-display/ directory
cargo build                  # Build application
cargo build --release       # Build optimized release
cargo run                    # Run application
cargo test                   # Run tests
```

## Key Configuration Files

- `iac_ansible/inventory-homelab.ini`: Ansible inventory defining target hosts
- `raspi-info-display/Cargo.toml`: Rust project dependencies and metadata

## Development Workflow

1. **Ansible Changes**: Modify playbooks in `iac_ansible/`, test against homelab inventory
2. **Rust Display App**: Develop in `raspi-info-display/`, build and test locally before deployment

## Important Notes

- Rust application targets ARM64 architecture for Raspberry Pi deployment
