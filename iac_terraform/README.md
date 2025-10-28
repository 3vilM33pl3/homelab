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
3. **WireGuard VPN Server**: Deploys WireGuard VPN on monolith for secure remote access to the homelab network

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
# Get the service and NodePort
kubectl get svc hello-world -n hello-world

# Access via any node IP and the NodePort (e.g., 31559)
# Replace <NODE-IP> with pink, orange, or white node IP
curl http://<NODE-IP>:<NODE-PORT>

# Example with node IP 10.22.6.x and NodePort 31559:
curl http://10.22.6.x:31559
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
├── main.tf                  # Main configuration (nginx, Kubernetes)
├── variables.tf             # Variable definitions for main resources
├── outputs.tf               # Output definitions for main resources
├── wireguard.tf             # WireGuard VPN server configuration
├── wireguard-variables.tf   # WireGuard-specific variables
├── wireguard-outputs.tf     # WireGuard outputs and next steps
├── .gitignore               # Git ignore patterns for state files
└── README.md                # This file
```

## Resources Created

- **Local**: nginx package on monolith.metatao.net
- **Kubernetes**:
  - Namespace: `hello-world`
  - Deployment: `hello-world` (2 replicas by default)
  - Service: `hello-world` (NodePort type)

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
# Check service status and get NodePort
kubectl get svc -n hello-world

# Test from a cluster node
curl http://localhost:<NODE-PORT>

# Test from outside the cluster using node IP
curl http://<NODE-IP>:<NODE-PORT>

# Check pod status
kubectl get pods -n hello-world

# Check pod logs if needed
kubectl logs -n hello-world -l app=hello-world
```

## WireGuard VPN Setup

This configuration includes a WireGuard VPN server deployment on monolith for secure remote access to your homelab.

### WireGuard Features

- **Server Location**: monolith.metatao.net
- **Management UI**: wg-easy web interface
- **Public Endpoint**: vpn.metatao.net:51820
- **VPN Network**: 10.8.0.x (clients assigned 10.8.0.2, 10.8.0.3, etc.)
- **Accessible Networks**: 10.22.6.0/24 (your homelab)
- **DNS Server**: 10.22.6.1 (OpenWrt)

### WireGuard Configuration

The WireGuard deployment is controlled by variables in `wireguard-variables.tf`. To customize:

```hcl
# Create terraform.tfvars
wireguard_enabled = true
wireguard_ui_password = "your-secure-password"
wireguard_port = 51820
wireguard_ui_port = 51821
```

**Important**: Set the UI password via environment variable for security:

```bash
export TF_VAR_wireguard_ui_password="your-secure-password"
tofu apply
```

**Note**: The password will be automatically hashed using bcrypt when the container is deployed. If you don't set a password, the default password "changeme" will be used (you should change this!).

### WireGuard Deployment Steps

1. **Deploy with OpenTofu**:
   ```bash
   cd iac_terraform
   export TF_VAR_wireguard_ui_password="your-secure-password"
   tofu apply
   ```

2. **Configure OpenWrt Port Forwarding** (one-time manual step):
   - Login to OpenWrt at http://10.22.6.1
   - Navigate to **Network > Firewall > Port Forwards**
   - Add new rule:
     - Name: `WireGuard VPN`
     - Protocol: `UDP`
     - External port: `51820`
     - Internal IP: `<monolith-ip>`
     - Internal port: `51820`

3. **Access wg-easy Management UI**:
   ```bash
   # On monolith or via SSH tunnel
   http://localhost:51821
   ```

4. **Create VPN Clients**:
   - Click "New Client" in the web UI
   - Enter client name (e.g., "iPhone", "Laptop")
   - Download configuration:
     - **Mobile**: Scan QR code with WireGuard app
     - **Desktop**: Download .conf file

5. **Install WireGuard Client**:
   - **iOS**: Install WireGuard from App Store, scan QR code
   - **Android**: Install WireGuard from Play Store, scan QR code
   - **Linux**: Install WireGuard, import .conf file
   - **macOS/Windows**: Install WireGuard GUI, import .conf file

6. **Test VPN Connection**:
   ```bash
   # Connect via WireGuard client, then test:
   ping 10.22.6.1
   nslookup monolith.metatao.net
   ssh olivier@10.22.6.x
   ```

### WireGuard Management

#### View Container Status
```bash
docker ps | grep wg-easy
docker logs wg-easy
```

#### Restart WireGuard
```bash
docker restart wg-easy
```

#### Stop WireGuard
```bash
docker stop wg-easy
```

#### Update WireGuard Configuration
```bash
# Modify wireguard-variables.tf or set environment variables
export TF_VAR_wireguard_port=51820
tofu apply
```

### Disable WireGuard

To disable WireGuard without destroying other infrastructure:

```hcl
# In terraform.tfvars
wireguard_enabled = false
```

```bash
tofu apply
```

### WireGuard Security Notes

- The wg-easy web UI is only accessible locally on monolith (port 51821)
- To access the UI remotely, use SSH port forwarding:
  ```bash
  ssh -L 51821:localhost:51821 olivier@monolith.metatao.net
  # Then access http://localhost:51821 in your browser
  ```
- Change the default UI password immediately
- WireGuard uses Curve25519 public/private key pairs (not X.509 certificates)
- Keys are automatically generated by wg-easy on first run
- Configuration is persisted in `~/.wg-easy` on monolith

## Next Steps

- Configure ingress controller for external access
- Add TLS certificates from ca.metatao.net for wg-easy web UI
- Expand to deploy additional applications
- Integrate with existing Ansible infrastructure
