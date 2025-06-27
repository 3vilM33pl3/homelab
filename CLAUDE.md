# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a multi-component homelab infrastructure repository containing:
- **iac_ansible/**: Ansible-based Infrastructure as Code for K3s cluster setup and software installation
- **iac_k8/**: Pulumi/TypeScript-based Kubernetes resource deployment
- **raspi-info-display/**: Rust application for Raspberry Pi OLED display

## Architecture

### Ansible Infrastructure (iac_ansible/)
- **Hosts**: Three Raspberry Pi nodes (white, pink, orange) defined in `inventory-homelab.ini`
- **Cluster**: K3s Kubernetes cluster with 'white' as server, 'pink'/'orange' as agents
- **Modular Design**: Software installation broken into individual task files in `software/` directory

### Kubernetes Deployment (iac_k8/)
- **Stack**: Pulumi with TypeScript for K8s resource management
- **CNI**: Cilium for advanced networking with Hubble observability
- **Resources**: Nginx ingress controller and sample nginx deployment with LoadBalancer service

### Raspberry Pi Display (raspi-info-display/)
- **Language**: Rust application using embedded-hal for OLED display
- **Hardware**: SSD1306 OLED display showing system metrics

## Common Commands

### Ansible Operations
```bash
# Setup SSH key authentication (initial setup)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/config/ssh-key-auth.yml --ask-pass

# System updates
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/software-install.yml --tags "apt-upgrade"

# K3s cluster setup (run in order)
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/config/enable-cgroups.yml
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/cluster/k3s-server.yml
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/cluster/k3s-agent.yml

# Deploy CNI and infrastructure (run after K3s cluster is ready)
cd iac_k8 && pulumi up

# Install all software packages
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/software-install.yml

# Uninstall K3s cluster
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/cluster/uninstall/k3-uninstall-agent.yml
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/cluster/uninstall/k3-uninstall-server.yml
```

### Pulumi/Kubernetes Operations
```bash
# From iac_k8/ directory
npm install                    # Install dependencies
pulumi preview                # Preview infrastructure changes
pulumi up                     # Deploy infrastructure
pulumi destroy               # Destroy infrastructure
npx tsc                      # Compile TypeScript
```

### Storage Setup (Longhorn)
```bash
# Prepare nodes for Longhorn (run before K8s deployment)
ansible-playbook -i iac_ansible/inventory-homelab.ini iac_ansible/software-install.yml

# Deploy Cilium CNI and Longhorn storage system
cd iac_k8 && pulumi up

# Access UIs (after deployment, requires DNS or /etc/hosts entries)
# Longhorn UI: http://longhorn.metatao.net (admin / longhorn)
# Hubble UI: http://hubble.metatao.net (network observability)
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
- `iac_ansible/k3s-agent-config`: Generated K3s agent configuration (created by server setup)
- `iac_k8/Pulumi.dev.yaml`: Pulumi stack configuration
- `iac_k8/networking/cilium.ts`: Cilium CNI configuration with Hubble observability
- `iac_k8/storage/longhorn.ts`: Longhorn distributed storage configuration
- `raspi-info-display/Cargo.toml`: Rust project dependencies and metadata

## Storage Configuration

### Longhorn Distributed Storage
- **Node Storage**: Each node has 512GB SSD mounted at `/data`
- **Longhorn Path**: `/data/longhorn` (automatically created)
- **Storage Classes**:
  - `longhorn` (default): 2 replicas, best-effort placement
  - `longhorn-fast`: 1 replica, strict-local placement (better performance)
  - `longhorn-backup`: 3 replicas, retain policy (critical data)

## Development Workflow

1. **Ansible Changes**: Modify playbooks in `iac_ansible/`, test against homelab inventory
2. **Kubernetes Resources**: Update `iac_k8/index.ts`, preview with `pulumi preview` before deploying
3. **Rust Display App**: Develop in `raspi-info-display/`, build and test locally before deployment

## Important Notes

- K3s requires cgroups to be enabled on Raspberry Pi systems before installation
- K3s is configured with Flannel CNI disabled to use Cilium instead
- The K3s server generates a token and config file that agents use to join the cluster
- Cilium provides advanced networking, security policies, and observability via Hubble
- Pulumi state is managed locally (check for `.pulumi/` directory)
- Rust application targets ARM64 architecture for Raspberry Pi deployment