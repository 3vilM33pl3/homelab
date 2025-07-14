import * as kubernetes from "@pulumi/kubernetes";

// Install nginx-ingress-controller
const nginxIngress = new kubernetes.helm.v3.Release("nginx-ingress", {
    chart: "ingress-nginx",
    namespace: "ingress-nginx",
    createNamespace: true,
    repositoryOpts: {
        repo: "https://kubernetes.github.io/ingress-nginx",
    },
    values: {
        controller: {
            // Configure for K3s LoadBalancer
            service: {
                type: "LoadBalancer",
                loadBalancerIP: "", // Let K3s assign IPs automatically
            },
            
            // Enable SSL passthrough for applications that handle their own TLS
            extraArgs: {
                "enable-ssl-passthrough": "true",
            },
            
            // Configure for ARM64 architecture (Raspberry Pi)
            nodeSelector: {
                "kubernetes.io/arch": "arm64",
            },
            
            // Resource configuration for Raspberry Pi
            resources: {
                limits: {
                    cpu: "200m",
                    memory: "256Mi",
                },
                requests: {
                    cpu: "100m",
                    memory: "128Mi",
                },
            },
            
            // Enable metrics for monitoring (optional)
            metrics: {
                enabled: true,
                serviceMonitor: {
                    enabled: false, // Can enable if Prometheus operator is installed
                },
            },
            
            // Configure admission webhook
            admissionWebhooks: {
                enabled: true,
                failurePolicy: "Fail",
                port: 8443,
                certificate: "/usr/local/certificates/cert",
                key: "/usr/local/certificates/key",
                namespaceSelector: {},
                objectSelector: {},
            },
        },
        
        // Default backend for handling unmatched requests
        defaultBackend: {
            enabled: true,
            image: {
                repository: "registry.k8s.io/defaultbackend-arm64",
                tag: "1.5",
            },
            nodeSelector: {
                "kubernetes.io/arch": "arm64",
            },
            resources: {
                limits: {
                    cpu: "10m",
                    memory: "20Mi",
                },
                requests: {
                    cpu: "5m",
                    memory: "10Mi",
                },
            },
        },
    },
    version: "4.8.3", // Stable version compatible with K3s
});

// Export nginx-ingress information
export const nginxIngressReleaseName = nginxIngress.name;
export const nginxIngressNamespace = "ingress-nginx";
export const nginxIngressClass = "nginx";