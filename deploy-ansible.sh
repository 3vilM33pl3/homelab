#!/bin/bash

# Homelab Ansible Deployment Script
# This script deploys the K3s cluster infrastructure using Ansible

set -e  # Exit on any error

echo "🏠 Starting K3s Cluster Deployment with Ansible..."
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    print_error "Ansible is not installed. Please install ansible first."
    exit 1
fi

print_success "Prerequisites check completed"

# Ansible Infrastructure Setup
echo ""
print_status "Setting up K3s cluster with Ansible..."
echo "======================================="

ANSIBLE_DIR="iac_ansible"
INVENTORY="$ANSIBLE_DIR/inventory-homelab.ini"

if [ ! -f "$INVENTORY" ]; then
    print_error "Ansible inventory not found at $INVENTORY"
    exit 1
fi

# Step 1: Enable cgroups (requires reboot)
print_status "Step 1: Enabling cgroups on all nodes..."
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/config/enable-cgroups.yml"; then
    print_success "cgroups configuration completed"
    print_warning "NOTE: Nodes may need to be rebooted for cgroups to take effect"
    print_warning "If this is the first time running, please reboot all nodes and re-run this script"
else
    print_error "Failed to configure cgroups"
    exit 1
fi

# Step 2: Install K3s server
print_status "Step 2: Installing K3s server on white node..."
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/cluster/k3s-server.yml"; then
    print_success "K3s server installation completed"
else
    print_error "Failed to install K3s server"
    exit 1
fi

# Step 3: Install K3s agents
print_status "Step 3: Installing K3s agents on pink and orange nodes..."
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/cluster/k3s-agent.yml"; then
    print_success "K3s agents installation completed"
else
    print_error "Failed to install K3s agents"
    exit 1
fi

# Step 4: Setup kubeconfig
print_status "Step 4: Setting up kubeconfig for local access..."
KUBECONFIG_DIR="$HOME/.kube"
mkdir -p "$KUBECONFIG_DIR"

if ssh olivier@white "sudo cat /etc/rancher/k3s/k3s.yaml" > "$KUBECONFIG_DIR/config.tmp"; then
    # Replace localhost with actual server IP
    sed 's/127.0.0.1/10.22.6.91/g' "$KUBECONFIG_DIR/config.tmp" > "$KUBECONFIG_DIR/config"
    rm "$KUBECONFIG_DIR/config.tmp"
    chmod 600 "$KUBECONFIG_DIR/config"
    print_success "Kubeconfig setup completed"
else
    print_warning "Failed to copy kubeconfig. You may need to set it up manually."
fi

# Verify cluster is ready
print_status "Verifying K3s cluster is ready..."
if kubectl get nodes; then
    print_success "K3s cluster is ready!"
else
    print_error "K3s cluster is not responding. Please check the installation."
    exit 1
fi

# Install additional software
echo ""
print_status "Installing additional software with Ansible..."
echo "=============================================="

print_status "Installing software packages on all nodes..."
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/software-install.yml"; then
    print_success "Software installation completed"
else
    print_warning "Some software installations may have failed. Check the output above."
fi

# Final Status
echo ""
print_success "🎉 K3s cluster deployment completed!"
echo "===================================="
echo ""
print_status "Cluster Information:"
kubectl get nodes -o wide
echo ""
print_status "Next Steps:"
echo "  1. Run ./deploy-pulumi.sh to deploy Kubernetes applications"
echo "  2. Or run pulumi up from the iac_k8/ directory"
echo ""
print_success "Ansible deployment script completed successfully! 🚀"