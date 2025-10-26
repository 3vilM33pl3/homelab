# Homelab Infrastructure with OpenTofu

This OpenTofu/Terraform project manages the initial setup for the homelab infrastructure.

> **Note**: This configuration is compatible with both OpenTofu and Terraform. The commands below use `tofu` but you can substitute `terraform` if preferred.

## Infrastructure Overview

### Servers
- **monolith.metatao.net**: Desktop server (nginx installation)
- **ca.metatao.net**: Certificate authority
- **pink.metatao.net**: Kubernetes cluster node
- **orange.metatao.net**: Kubernetes cluster node
- **white.metatao.net**: Kubernetes cluster node

### What This Configuration Does

1. **Nginx Installation**: Installs and enables nginx on the local desktop (monolith.metatao.net)
2. **Kubernetes Hello World**: Deploys a simple hello-world application to the Kubernetes cluster running on pink, orange, and white nodes

## Prerequisites

### 1. Install OpenTofu

#### Option A: Using the Official Installer (Recommended)
```bash
# Download and run the installer
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
sudo ./install-opentofu.sh --install-method deb

# Clean up
rm install-opentofu.sh
```

#### Option B: Manual Installation
```bash
# Download OpenTofu (check https://github.com/opentofu/opentofu/releases for latest)
cd /tmp
wget https://github.com/opentofu/opentofu/releases/download/v1.6.2/tofu_1.6.2_linux_amd64.zip

# Install unzip if needed
sudo apt-get install unzip

# Unzip and install
unzip tofu_1.6.2_linux_amd64.zip
sudo mv tofu /usr/local/bin/
sudo chmod +x /usr/local/bin/tofu

# Clean up
rm tofu_1.6.2_linux_amd64.zip
```

#### Verify Installation
```bash
tofu version
```

You should see output like: `OpenTofu v1.6.2`

### 2. Kubernetes Access

Ensure you have a valid kubeconfig at `~/.kube/config` that can access your cluster:

```bash
# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### 3. Local Permissions

Ensure your user (olivier) has sudo privileges on monolith for nginx installation

## Usage

### Initialize OpenTofu

```bash
cd iac_terraform
tofu init
```

### Preview Changes

```bash
tofu plan
```

### Apply Configuration

```bash
tofu apply
```

You'll be prompted to confirm. Type `yes` to proceed.

### Using Terraform Instead

If you prefer to use Terraform, simply replace `tofu` with `terraform` in all commands:

```bash
terraform init
terraform plan
terraform apply
```

### Verify Deployment

#### Check nginx on monolith
```bash
systemctl status nginx
curl http://localhost
```

#### Check Kubernetes deployment
```bash
kubectl get all -n hello-world
kubectl get svc -n hello-world
```

#### Access hello-world application
```bash
# Get the service IP/port
kubectl get svc hello-world -n hello-world

# Test the application
curl http://<SERVICE-IP>
```

### Destroy Infrastructure

To remove all resources created:

```bash
tofu destroy
```

Note: This will remove the Kubernetes resources but will NOT uninstall nginx from monolith.

## Configuration Variables

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
hello_world_replicas  = 3
hello_world_namespace = "my-namespace"
hello_world_image     = "gcr.io/google-samples/hello-app:2.0"
kubeconfig_path       = "/custom/path/to/kubeconfig"
```

## File Structure

```
iac_terraform/
├── main.tf         # Main configuration (OpenTofu/Terraform compatible)
├── variables.tf    # Variable definitions
├── outputs.tf      # Output definitions
├── .gitignore      # Git ignore patterns for state files
└── README.md       # This file
```

## Resources Created

- **Local**: nginx package on monolith.metatao.net
- **Kubernetes**:
  - Namespace: `hello-world`
  - Deployment: `hello-world` (2 replicas by default)
  - Service: `hello-world` (LoadBalancer type)

## Troubleshooting

### Kubernetes provider connection issues
```bash
# Verify kubeconfig
export KUBECONFIG=~/.kube/config
kubectl config view
kubectl cluster-info
```

### nginx installation issues
```bash
# Check nginx status
systemctl status nginx

# View nginx logs
sudo journalctl -u nginx
```

### Service not accessible
```bash
# Check if LoadBalancer IP is assigned
kubectl get svc -n hello-world

# If using MetalLB or similar, verify the IP pool configuration
# If external IP shows <pending>, you may need to configure a LoadBalancer provider
```

## Next Steps

- Configure ingress controller for external access
- Add TLS certificates from ca.metatao.net
- Expand to deploy additional applications
- Integrate with existing Ansible infrastructure
