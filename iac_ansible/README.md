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
# Full deployment (recommended)
./deploy-cluster.sh

# Deploy with specific tags
./deploy-cluster.sh --tags config,system

# Skip slow cargo package compilation
./deploy-cluster.sh --skip-tags cargo

# Dry-run (check mode)
./deploy-cluster.sh --check

# Or use ansible-playbook directly
ansible-playbook -i inventory-homelab.ini install-cluster.yml

# System updates only
ansible-playbook -i inventory-homelab.ini install-cluster.yml --tags apt
```

#### Available Tags

- `config`: Hostname and timezone configuration
- `system`: System updates, NTP
- `tools`: Essential CLI tools (vim, networking tools)
- `security`: SSH certificates, step-cli
- `ssh`: SSH certificate configuration only
- `certificates`: SSH certificate configuration only
- `dev`: Rust toolchain and cargo packages
- `hardware`: I2C support, info display
- `apt`: APT updates only
- `cargo`: Cargo package compilation (slow on ARM)

### SSH Certificate Authentication

The cluster nodes can be configured to use SSH certificate-based authentication with step-ca:

```bash
# Configure SSH certificates on all cluster nodes
ansible-playbook -i inventory-homelab.ini install-cluster.yml --tags ssh

# Or include in full deployment
./deploy-cluster.sh
```

This configuration:
- Generates host certificates for each node using step-ca
- Configures SSH to trust user certificates signed by the CA
- Sets up proper principals (hostname and FQDN)
- Automatically restarts SSH service

**Prerequisites:**
- step-ca must be running and accessible
- step-cli must be installed on cluster nodes (included in deployment)

### Certificate Authority Setup

```bash
# Setup CA server with all required software
ansible-playbook -i ca/inventory-ca.ini install-ca.yml
```

### Kubernetes Cluster Deployment

The homelab includes Kubernetes deployment using [Kubespray](https://github.com/kubernetes-sigs/kubespray) as a git submodule.

#### Initial Setup

```bash
# Initialize kubespray submodule (first time only)
git submodule update --init --recursive

# Setup Python virtual environment for kubespray
cd ../kubespray
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ../iac_ansible
```

#### Deploy Kubernetes

```bash
# Deploy Kubernetes cluster on white (control plane), orange and pink (workers)
ansible-playbook install-kubernetes.yml

# Or run kubespray directly
cd ../kubespray
source venv/bin/activate
ansible-playbook -i inventory/metatao/inventory.ini -u olivier -b cluster.yml
```

#### Cluster Configuration

- **Control Plane**: white.metatao.net (10.22.6.91)
- **Workers**: orange.metatao.net (10.22.6.92), pink.metatao.net (10.22.6.93)
- **Network Plugin**: Calico
- **Kubernetes Version**: 1.33.5
- **Container Runtime**: containerd

#### Access Cluster

The kubeconfig is automatically generated at `../kubespray/inventory/metatao/artifacts/admin.conf`:

```bash
# Copy to standard location
mkdir -p ~/.kube
cp ../kubespray/inventory/metatao/artifacts/admin.conf ~/.kube/config

# Or use directly
export KUBECONFIG=/home/olivier/Projects/homelab/kubespray/inventory/metatao/artifacts/admin.conf

# Verify cluster
kubectl get nodes
```

**Note**: The cluster is configured with cgroup memory support enabled on all Raspberry Pi nodes (required for Kubernetes).

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

## Configuration

### Ansible User

The default user for Ansible operations is configured in `inventory-homelab.ini`:

```ini
[cluster:vars]
ansible_user=olivier

[cert_authority:vars]
ansible_user=olivier
```

To use a different user, modify the `ansible_user` variable in the inventory file.

### GitHub Downloads

Package downloads from GitHub include SHA256 checksum verification when available. Checksum files should be named `<package>.sha256` and uploaded as release assets.

## Important Notes

- Downloads from GitHub are verified with SHA256 checksums when available
- Cargo package compilation can take 10+ minutes per package on ARM systems
- Use specific tags to run only required tasks for faster deployments

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
