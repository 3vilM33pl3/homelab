#!/bin/bash

# Homelab Complete Deployment Script - Hybrid Ansible + Pulumi Approach
# This script deploys the complete homelab infrastructure using:
# 1. Ansible for K3s cluster setup on Raspberry Pi nodes  
# 2. Pulumi for Kubernetes resources (CNI, storage, applications)
#
# You can also run the individual scripts:
# - ./deploy-ansible.sh (K3s cluster only)
# - ./deploy-pulumi.sh (Kubernetes applications only)

set -e  # Exit on any error

echo "🏠 Starting Complete Homelab Deployment..."
echo "=========================================="

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

# Check if pulumi is installed
if ! command -v pulumi &> /dev/null; then
    print_error "Pulumi is not installed. Please install pulumi first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. Installing kubectl..."
    # You may want to install kubectl here or provide instructions
fi

print_success "Prerequisites check completed"

# Phase 1: Ansible Infrastructure Setup
echo ""
print_status "Phase 1: Running Ansible deployment script..."
echo "=============================================="

if ./deploy-ansible.sh; then
    print_success "Ansible deployment completed"
else
    print_error "Ansible deployment failed"
    exit 1
fi

# Phase 2: Pulumi Kubernetes Resources
echo ""
print_status "Phase 2: Running Pulumi deployment script..."
echo "============================================"

if ./deploy-pulumi.sh; then
    print_success "Pulumi deployment completed"
else
    print_error "Pulumi deployment failed"
    exit 1
fi

# Final Status
echo ""
print_success "🎉 Homelab deployment completed!"
echo "=================================="
echo ""
print_status "Cluster Information:"
kubectl get nodes -o wide
echo ""
print_status "Available Services:"
kubectl get svc --all-namespaces
echo ""
print_status "Web UIs (if DNS is configured):"
echo "  • Longhorn: http://longhorn.metatao.net (admin/longhorn)"
echo "  • Hubble: http://hubble.metatao.net"
echo ""
print_status "⚠️  Initial Setup Notes:"
echo "  • cert-manager is installed but ClusterIssuer needs manual setup"
echo "  • TLS certificates are disabled until ClusterIssuer is configured"
echo "  • To enable ACME certificates:"
echo "    1. Wait for cert-manager to be ready: kubectl get pods -n cert-manager"
echo "    2. Manually apply ClusterIssuer configuration"
echo "    3. Update ingress configurations to enable TLS"
echo ""
print_status "Next Steps:"
echo "  1. Configure DNS entries for *.metatao.net → LoadBalancer IPs"
echo "  2. Test applications and storage"
echo "  3. Monitor cluster with: kubectl get pods --all-namespaces"
echo ""
print_success "Deployment script completed successfully! 🚀"