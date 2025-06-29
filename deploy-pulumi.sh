#!/bin/bash

# Homelab Pulumi Deployment Script
# This script deploys Kubernetes applications and resources using Pulumi
# Prerequisites: K3s cluster must be running and kubeconfig configured

set -e  # Exit on any error

echo "☸️  Starting Kubernetes Applications Deployment with Pulumi..."
echo "============================================================="

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

# Check if pulumi is installed
if ! command -v pulumi &> /dev/null; then
    print_error "Pulumi is not installed. Please install pulumi first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if K3s cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please ensure:"
    print_error "  1. K3s cluster is running (run ./deploy-ansible.sh first)"
    print_error "  2. kubeconfig is properly configured"
    exit 1
fi

print_success "Prerequisites check completed"

# Check cluster nodes
print_status "Current cluster status:"
kubectl get nodes

# Pulumi Kubernetes Resources Deployment
echo ""
print_status "Deploying Kubernetes resources with Pulumi..."
echo "=============================================="

PULUMI_DIR="iac_k8"

if [ ! -d "$PULUMI_DIR" ]; then
    print_error "Pulumi directory not found at $PULUMI_DIR"
    exit 1
fi

cd "$PULUMI_DIR"

# Install npm dependencies
print_status "Installing Pulumi dependencies..."
if npm install; then
    print_success "Dependencies installed"
else
    print_error "Failed to install dependencies"
    exit 1
fi

# Check TypeScript compilation
print_status "Checking TypeScript compilation..."
if npx tsc --noEmit; then
    print_success "TypeScript compilation successful"
else
    print_error "TypeScript compilation failed"
    exit 1
fi

# Preview deployment
print_status "Previewing Pulumi deployment..."
if pulumi preview; then
    print_success "Preview completed"
else
    print_error "Preview failed"
    exit 1
fi

# Ask for confirmation
echo ""
print_warning "Ready to deploy the following components:"
print_warning "  • Cilium CNI (advanced networking)"
print_warning "  • Longhorn (distributed storage)"
print_warning "  • Nginx Ingress Controller"
print_warning "  • Sample Nginx application"
echo ""
read -p "Continue with deployment? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Deployment cancelled."
    exit 0
fi

# Deploy with Pulumi
print_status "Deploying Kubernetes resources..."
if pulumi up --yes; then
    print_success "Pulumi deployment completed"
else
    print_error "Pulumi deployment failed"
    exit 1
fi

cd ..

# Post-deployment verification
echo ""
print_status "Verifying deployment..."
echo "======================"

# Check Cilium
print_status "Checking Cilium status..."
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium

# Check Longhorn  
print_status "Checking Longhorn status..."
kubectl get pods -n longhorn-system 2>/dev/null || print_warning "Longhorn namespace not found"

# Check Ingress Controller
print_status "Checking Nginx Ingress Controller..."
kubectl get pods -n nginx-ingress 2>/dev/null || print_warning "Nginx ingress namespace not found"

# Check storage classes
print_status "Available storage classes:"
kubectl get storageclass

# Final Status
echo ""
print_success "🎉 Kubernetes applications deployment completed!"
echo "==============================================="
echo ""
print_status "Available Services:"
kubectl get svc --all-namespaces | grep -E "(LoadBalancer|NodePort)"
echo ""
print_status "Web UIs (if DNS is configured):"
echo "  • Longhorn: http://longhorn.metatao.net (admin/longhorn)"
echo "  • Hubble: http://hubble.metatao.net"
echo ""
print_status "Next Steps:"
echo "  1. Configure DNS entries for *.metatao.net → LoadBalancer IPs"
echo "  2. Test applications and storage"
echo "  3. Monitor cluster with: kubectl get pods --all-namespaces"
echo ""
print_status "To check Longhorn storage:"
echo "  kubectl get pods -n longhorn-system"
echo "  kubectl get storageclass"
echo ""
print_success "Pulumi deployment script completed successfully! 🚀"