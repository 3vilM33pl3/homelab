import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

const config = new pulumi.Config();
const ciliumNamespace = config.get("ciliumNamespace") || "kube-system";

// Install Cilium CNI using Helm
const cilium = new kubernetes.helm.v3.Release("cilium", {
    chart: "cilium",
    namespace: ciliumNamespace,
    repositoryOpts: {
        repo: "https://helm.cilium.io/",
    },
    values: {
        // Basic Cilium configuration for K3s
        kubeProxyReplacement: "strict",
        k8sServiceHost: "10.22.6.91", // White node IP (K3s server)
        k8sServicePort: "6443",
        
        // Enable features for better observability and security
        hubble: {
            enabled: true,
            relay: {
                enabled: true,
            },
            ui: {
                enabled: true,
                // Ingress disabled - can be added separately with nginx-ingress if needed
                ingress: {
                    enabled: false,
                },
            },
        },
        
        // Network policy enforcement
        policyEnforcement: "default",
        
        // Enable monitoring
        prometheus: {
            enabled: true,
            serviceMonitor: {
                enabled: false, // Disable for now to avoid CRD issues
            },
        },
        
        // Disable Cilium Ingress Controller (using nginx-ingress instead)
        ingressController: {
            enabled: false,
        },
        
        // Enable L7 proxy for ingress
        l7Proxy: true,
        
        // Enable ingress secrets sync
        ingressSecretsSync: {
            enabled: true,
        },
        
        // Enable gateway API support
        gatewayAPI: {
            enabled: false, // Disable for now, can enable later if needed
        },
        
        // Operator configuration
        operator: {
            replicas: 1,
            prometheus: {
                enabled: true,
                serviceMonitor: {
                    enabled: false, // Disable for now to avoid CRD issues
                },
            },
        },
        
        // IPAM configuration
        ipam: {
            mode: "kubernetes",
        },
        
        // Enable native routing mode for better performance
        routingMode: "native",
        autoDirectNodeRoutes: true,
        ipv4NativeRoutingCIDR: "10.22.6.0/24", // Your node network CIDR
        
        // Configure tunneling to ensure connectivity
        tunnelMode: "disabled", // Use native routing instead of tunneling
        
        // Enable host routing for external network access
        enableHostLegacyRouting: false,
        installNoConntrackIptablesRules: false,
        
        // Configure masquerading for host network access
        masquerade: true,
        enableIPv4Masquerade: true,
        ipv4MasqueradeInterfaces: "eth0",
        
        // Ensure proper routing to host network
        enableHostReachableServices: true,
        hostServices: {
            enabled: true,
            protocols: "tcp,udp",
        },
        
        // Enable external services to be reachable
        enableExternalIPs: true,
        
        // Security settings
        encryption: {
            enabled: false, // Can enable for enhanced security if needed
            type: "wireguard",
        },
        
        // Enable bandwidth manager for QoS
        bandwidthManager: {
            enabled: true,
        },
        
        // Resource limits
        resources: {
            limits: {
                memory: "512Mi",
            },
            requests: {
                cpu: "100m",
                memory: "128Mi",
            },
        },
    },
    version: "1.14.5",
});

// Export Cilium information
export const ciliumReleaseName = cilium.name;
export const ciliumNamespaceName = ciliumNamespace;
export const hubbleUIHost = "hubble.metatao.net";