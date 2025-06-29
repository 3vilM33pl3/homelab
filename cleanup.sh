#!/bin/bash

# Homelab Cleanup Script
# This script cleanly removes the homelab infrastructure in reverse order:
# 1. Pulumi resources (K8s applications, storage, networking)
# 2. Ansible K3s cluster uninstall

set -e  # Exit on any error

echo "🧹 Starting Homelab Cleanup..."
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Ask for confirmation
echo ""
print_warning "This will completely remove your homelab infrastructure!"
print_warning "This includes:"
print_warning "  • All Kubernetes applications and data"  
print_warning "  • Longhorn storage (all persistent volumes)"
print_warning "  • K3s cluster on all nodes"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

# Phase 1: Remove Pulumi resources
echo ""
print_status "Phase 1: Removing Kubernetes resources with Pulumi..."
echo "===================================================="

PULUMI_DIR="iac_k8"
if [ -d "$PULUMI_DIR" ]; then
    cd "$PULUMI_DIR"
    
    print_status "Destroying Pulumi stack..."
    if pulumi destroy --yes; then
        print_success "Pulumi resources destroyed"
    else
        print_warning "Some Pulumi resources may not have been cleaned up properly"
    fi
    
    cd ..
else
    print_warning "Pulumi directory not found, skipping Pulumi cleanup"
fi

# Phase 2: Remove K3s cluster with Ansible
echo ""
print_status "Phase 2: Removing K3s cluster with Ansible..."
echo "=============================================="

ANSIBLE_DIR="iac_ansible"
INVENTORY="$ANSIBLE_DIR/inventory-homelab.ini"

if [ ! -f "$INVENTORY" ]; then
    print_error "Ansible inventory not found at $INVENTORY"
    exit 1
fi

# Step 1: Uninstall K3s agents first
print_status "Step 1: Uninstalling K3s agents..."
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/cluster/uninstall/k3-uninstall-agent.yml"; then
    print_success "K3s agents uninstalled"
else
    print_warning "Failed to uninstall some K3s agents"
fi

# Step 2: Uninstall K3s server
print_status "Step 2: Uninstalling K3s server..."
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/cluster/uninstall/k3-uninstall-server.yml"; then
    print_success "K3s server uninstalled"
else
    print_warning "Failed to uninstall K3s server"
fi

# Phase 3: Clean up local configuration
echo ""
print_status "Phase 3: Cleaning up local configuration..."
echo "==========================================="

# Remove kubeconfig
if [ -f "$HOME/.kube/config" ]; then
    print_status "Backing up and removing kubeconfig..."
    mv "$HOME/.kube/config" "$HOME/.kube/config.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Kubeconfig backed up and removed"
fi

# Remove generated agent config
AGENT_CONFIG="$ANSIBLE_DIR/k3s-agent-config"
if [ -f "$AGENT_CONFIG" ]; then
    rm "$AGENT_CONFIG"
    print_success "K3s agent config removed"
fi

# Final status
echo ""
print_success "🎉 Homelab cleanup completed!"
echo "============================="
echo ""
print_status "Summary:"
echo "  • Kubernetes resources: Removed via Pulumi"
echo "  • K3s cluster: Uninstalled from all nodes"
echo "  • Local config: Cleaned up and backed up"
echo ""
print_status "Notes:"
echo "  • Node storage directories may still contain data"
echo "  • SSH keys and access are unchanged"
echo "  • To completely clean storage, manually remove /data on each node"
echo ""
print_success "Cleanup script completed successfully! 🧹"