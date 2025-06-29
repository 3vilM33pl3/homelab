import * as kubernetes from "@pulumi/kubernetes";

// Install cert-manager for automatic certificate management
const certManager = new kubernetes.helm.v3.Release("cert-manager", {
    chart: "cert-manager",
    namespace: "cert-manager",
    createNamespace: true,
    repositoryOpts: {
        repo: "https://charts.jetstack.io",
    },
    values: {
        installCRDs: true,
        global: {
            leaderElection: {
                namespace: "cert-manager",
            },
        },
    },
    version: "v1.13.3",
});

// Create ACME ClusterIssuer for your CA
const acmeClusterIssuer = new kubernetes.apiextensions.CustomResource("acme-issuer", {
    apiVersion: "cert-manager.io/v1",
    kind: "ClusterIssuer",
    metadata: {
        name: "metatao-acme-issuer",
    },
    spec: {
        acme: {
            server: "https://ca.metatao.net/acme/acme/directory", // Adjust to your ACME endpoint
            email: "admin@metatao.net", // Your email for ACME registration
            privateKeySecretRef: {
                name: "metatao-acme-private-key",
            },
            solvers: [
                {
                    http01: {
                        ingress: {
                            class: "nginx", // Use nginx ingress for HTTP-01 challenge
                        },
                    },
                },
                {
                    dns01: {
                        // Add DNS-01 solver if you have DNS API access
                        // webhook: { ... }
                    },
                },
            ],
        },
    },
}, { dependsOn: certManager });

// Export cert-manager information
export const certManagerReleaseName = certManager.name;
export const acmeIssuerName = acmeClusterIssuer.metadata.name;