#!/bin/bash
set -e

echo "🔍 Validating Kubernetes Infrastructure Deployment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        exit 1
    fi
}

# Function to check if resource exists
check_resource() {
    local resource=$1
    local namespace=${2:-""}
    local name=$3
    
    if [ -n "$namespace" ]; then
        kubectl get $resource -n $namespace $name >/dev/null 2>&1
    else
        kubectl get $resource $name >/dev/null 2>&1
    fi
}

# Check prerequisites
echo "🔧 Checking prerequisites..."
check_command kubectl
check_command curl
echo -e "${GREEN}✅ All prerequisites installed${NC}"

# Check cluster connectivity
echo
echo "🌐 Checking cluster connectivity..."
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Cluster is reachable${NC}"
else
    echo -e "${RED}❌ Cannot connect to cluster${NC}"
    exit 1
fi

# Check nodes
echo
echo "🖥️  Checking cluster nodes..."
READY_NODES=$(kubectl get nodes --no-headers | grep -c Ready)
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
echo "Ready nodes: $READY_NODES/$TOTAL_NODES"
if [ $READY_NODES -eq $TOTAL_NODES ]; then
    echo -e "${GREEN}✅ All nodes are ready${NC}"
else
    echo -e "${YELLOW}⚠️  Some nodes are not ready${NC}"
fi

# Check Cilium
echo
echo "🕸️  Checking Cilium CNI..."
if check_resource "pods" "kube-system" "-l k8s-app=cilium"; then
    CILIUM_READY=$(kubectl get pods -n kube-system -l k8s-app=cilium --no-headers | grep -c Running)
    CILIUM_TOTAL=$(kubectl get pods -n kube-system -l k8s-app=cilium --no-headers | wc -l)
    echo "Cilium pods: $CILIUM_READY/$CILIUM_TOTAL running"
    if [ $CILIUM_READY -eq $CILIUM_TOTAL ]; then
        echo -e "${GREEN}✅ Cilium is running on all nodes${NC}"
    else
        echo -e "${YELLOW}⚠️  Some Cilium pods are not running${NC}"
    fi
else
    echo -e "${RED}❌ Cilium pods not found${NC}"
fi

# Check nginx-ingress
echo
echo "🚪 Checking nginx-ingress..."
if check_resource "pods" "ingress-nginx" "-l app.kubernetes.io/name=ingress-nginx"; then
    NGINX_READY=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --no-headers | grep -c Running)
    echo "nginx-ingress controller: $NGINX_READY/1 running"
    if [ $NGINX_READY -eq 1 ]; then
        echo -e "${GREEN}✅ nginx-ingress controller is running${NC}"
        
        # Check LoadBalancer IP
        LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$LB_IP" ]; then
            echo "LoadBalancer IP: $LB_IP"
            echo -e "${GREEN}✅ LoadBalancer has external IP${NC}"
        else
            echo -e "${YELLOW}⚠️  LoadBalancer IP is pending${NC}"
        fi
    else
        echo -e "${RED}❌ nginx-ingress controller is not running${NC}"
    fi
else
    echo -e "${RED}❌ nginx-ingress controller not found${NC}"
fi

# Check cert-manager
echo
echo "📜 Checking cert-manager..."
if check_resource "pods" "cert-manager" "-l app=cert-manager"; then
    CERTMGR_READY=$(kubectl get pods -n cert-manager -l app=cert-manager --no-headers | grep -c Running)
    echo "cert-manager pods: $CERTMGR_READY/3 running"
    if [ $CERTMGR_READY -eq 3 ]; then
        echo -e "${GREEN}✅ cert-manager is running${NC}"
        
        # Check ClusterIssuer
        if check_resource "clusterissuer" "" "metatao-acme-issuer"; then
            ISSUER_READY=$(kubectl get clusterissuer metatao-acme-issuer -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
            if [ "$ISSUER_READY" = "True" ]; then
                echo -e "${GREEN}✅ ACME ClusterIssuer is ready${NC}"
            else
                echo -e "${YELLOW}⚠️  ACME ClusterIssuer is not ready${NC}"
            fi
        else
            echo -e "${RED}❌ ACME ClusterIssuer not found${NC}"
        fi
    else
        echo -e "${RED}❌ cert-manager is not fully running${NC}"
    fi
else
    echo -e "${RED}❌ cert-manager not found${NC}"
fi

# Check Longhorn
echo
echo "💾 Checking Longhorn storage..."
if check_resource "pods" "longhorn-system" "-l app=longhorn-manager"; then
    LONGHORN_READY=$(kubectl get pods -n longhorn-system -l app=longhorn-manager --no-headers | grep -c Running)
    LONGHORN_TOTAL=$(kubectl get pods -n longhorn-system -l app=longhorn-manager --no-headers | wc -l)
    echo "Longhorn manager pods: $LONGHORN_READY/$LONGHORN_TOTAL running"
    if [ $LONGHORN_READY -eq $LONGHORN_TOTAL ]; then
        echo -e "${GREEN}✅ Longhorn is running${NC}"
    else
        echo -e "${YELLOW}⚠️  Some Longhorn pods are not running${NC}"
    fi
else
    echo -e "${RED}❌ Longhorn not found${NC}"
fi

# Check Kubernetes Dashboard
echo
echo "📊 Checking Kubernetes Dashboard..."
if check_resource "pods" "kubernetes-dashboard" "-l k8s-app=kubernetes-dashboard"; then
    DASHBOARD_READY=$(kubectl get pods -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard --no-headers | grep -c Running)
    echo "Dashboard pods: $DASHBOARD_READY/1 running"
    if [ $DASHBOARD_READY -eq 1 ]; then
        echo -e "${GREEN}✅ Kubernetes Dashboard is running${NC}"
        
        # Check certificate
        if check_resource "certificates" "kubernetes-dashboard" "dashboard-tls-cert"; then
            CERT_READY=$(kubectl get certificate -n kubernetes-dashboard dashboard-tls-cert -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
            if [ "$CERT_READY" = "True" ]; then
                echo -e "${GREEN}✅ Dashboard certificate is ready${NC}"
            else
                echo -e "${YELLOW}⚠️  Dashboard certificate is not ready${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Dashboard certificate not found${NC}"
        fi
    else
        echo -e "${RED}❌ Kubernetes Dashboard is not running${NC}"
    fi
else
    echo -e "${RED}❌ Kubernetes Dashboard not found${NC}"
fi

# Test HTTPS access
echo
echo "🌐 Testing HTTPS access..."
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$LB_IP" ]; then
    echo "Testing dashboard access at https://dashboard.metatao.net..."
    if curl -s -k --connect-timeout 10 "https://dashboard.metatao.net" | grep -q "Kubernetes Dashboard" 2>/dev/null; then
        echo -e "${GREEN}✅ Dashboard is accessible via HTTPS${NC}"
    else
        echo -e "${YELLOW}⚠️  Dashboard HTTPS access test failed (check DNS)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Cannot test HTTPS access - no LoadBalancer IP${NC}"
fi

echo
echo "🎉 Validation complete!"
echo
echo "📋 Summary:"
echo "- Access Kubernetes Dashboard: https://dashboard.metatao.net"
echo "- Access Longhorn UI: http://longhorn.metatao.net (admin / longhorn)"
echo "- Access Hubble UI: http://hubble.metatao.net"
echo
echo "💡 To get dashboard admin token:"
echo "kubectl create token dashboard-admin -n kubernetes-dashboard"