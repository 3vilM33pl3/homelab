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
                ingress: {
                    enabled: true,
                    hosts: ["hubble.metatao.net"],
                    annotations: {
                        "kubernetes.io/ingress.class": "nginx",
                        "cert-manager.io/cluster-issuer": "metatao-acme-issuer",
                    },
                    tls: [{
                        secretName: "hubble-tls-cert",
                        hosts: ["hubble.metatao.net"],
                    }],
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