# Kubernetes Infrastructure as Code (iac_k8)

This directory contains Pulumi/TypeScript configuration for deploying Kubernetes resources on the homelab K3s cluster.

## Architecture

### Components Deployed

1. **Networking**
   - **Cilium CNI**: Advanced networking with native routing, eBPF-based
   - **nginx-ingress-controller**: HTTP/HTTPS ingress management
   - **Hubble**: Network observability (UI available)

2. **Storage**
   - **Longhorn**: Distributed block storage with web UI
   - Multiple storage classes for different performance/reliability needs

3. **Certificate Management**
   - **cert-manager**: Automatic certificate management
   - **Custom ACME Integration**: Works with step-ca server at `ca.metatao.net`
   - **Automatic Renewal**: Certificates renew before expiration

4. **Applications**
   - **Kubernetes Dashboard**: Web UI at `https://dashboard.metatao.net`
   - **Admin Access**: Pre-configured with cluster-admin permissions

## Prerequisites

1. **K3s Cluster**: Must be deployed via Ansible (see `../iac_ansible/`)
2. **DNS Configuration**: Ensure DNS entries point to ingress IPs
3. **Custom CA**: step-ca server running at `https://ca.metatao.net`

## Deployment

### Initial Setup

```bash
# Install dependencies
npm install

# Preview changes
pulumi preview

# Deploy infrastructure
pulumi up
```

### Deployment Order

The components are deployed in dependency order:

1. **Cilium CNI** (networking foundation)
2. **nginx-ingress** (ingress controller) 
3. **Longhorn** (storage)
4. **cert-manager** (certificate management)
5. **Kubernetes Dashboard** (with automatic certificate)

## Configuration

### Network Configuration

- **Node Network**: `10.22.6.0/24`
- **Pod Network**: Managed by Cilium
- **Ingress IPs**: Assigned by K3s LoadBalancer
- **Native Routing**: Enabled for better performance

### Certificate Management

- **ACME Server**: `https://ca.metatao.net/acme/acme/directory`
- **Email**: `admin@metatao.net`
- **Challenge Type**: HTTP-01 via nginx-ingress
- **TLS Skip Verify**: Enabled for self-signed CA

### Storage Classes

- **longhorn** (default): 2 replicas, best-effort placement
- **longhorn-fast**: 1 replica, strict-local placement
- **longhorn-backup**: 3 replicas, retain policy

## Access URLs

After deployment:

- **Kubernetes Dashboard**: `https://dashboard.metatao.net`
- **Longhorn UI**: `http://longhorn.metatao.net` (admin / longhorn)
- **Hubble UI**: `http://hubble.metatao.net` (network observability)

## DNS Requirements

Add these entries to your DNS server (`10.22.6.1`):

```
dashboard.metatao.net  → [nginx-ingress LoadBalancer IP]
longhorn.metatao.net   → [nginx-ingress LoadBalancer IP]  
hubble.metatao.net     → [nginx-ingress LoadBalancer IP]
```

The LoadBalancer IP can be found with:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

## Dashboard Access

### Getting Admin Token

```bash
# Get admin service account token
kubectl create token dashboard-admin -n kubernetes-dashboard

# Or get long-lived token (if using service account tokens)
kubectl get secret -n kubernetes-dashboard dashboard-admin-token-xxxxx -o jsonpath='{.data.token}' | base64 -d
```

### Login Steps

1. Navigate to `https://dashboard.metatao.net`
2. Select "Token" authentication method
3. Paste the admin token
4. Click "Sign In"

## Troubleshooting

### Certificate Issues

```bash
# Check certificate status
kubectl get certificates -A

# Check ACME challenges
kubectl get challenges -A

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Ingress Issues

```bash
# Check nginx-ingress status
kubectl get pods -n ingress-nginx

# Check LoadBalancer IPs
kubectl get svc -n ingress-nginx

# Check ingress resources
kubectl get ingress -A
```

### Storage Issues

```bash
# Check Longhorn status
kubectl get pods -n longhorn-system

# Access Longhorn UI for detailed status
```

## Development Workflow

1. **Make Changes**: Modify TypeScript files in respective directories
2. **Preview**: Run `pulumi preview` to see planned changes
3. **Deploy**: Run `pulumi up` to apply changes
4. **Verify**: Check resources and access URLs

## File Structure

```
iac_k8/
├── networking/
│   ├── cilium.ts           # Cilium CNI configuration
│   └── nginx-ingress.ts    # nginx-ingress-controller
├── storage/
│   └── longhorn.ts         # Longhorn distributed storage
├── certificates/
│   └── cert-manager.ts     # cert-manager + ACME configuration
├── cluster/
│   └── kubernetes-dashboard.ts  # Dashboard deployment + ingress
├── index.ts                # Main entry point
└── README.md              # This file
```

## Notes

- **Architecture**: ARM64 optimized for Raspberry Pi cluster
- **Security**: Uses custom CA for all certificates
- **Performance**: Native routing enabled for better network performance
- **Monitoring**: Hubble provides network observability
- **Storage**: Longhorn provides persistent storage with replication
- **Access**: All services accessible via ingress with automatic HTTPS