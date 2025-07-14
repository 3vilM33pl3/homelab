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

// ClusterIssuer for custom Certificate Authority
const acmeClusterIssuer = new kubernetes.apiextensions.CustomResource("acme-issuer", {
    apiVersion: "cert-manager.io/v1",
    kind: "ClusterIssuer",
    metadata: {
        name: "metatao-acme-issuer",
    },
    spec: {
        acme: {
            server: "https://10.22.6.2/acme/acme/directory",
            email: "admin@metatao.net",
            skipTLSVerify: true,
            privateKeySecretRef: {
                name: "metatao-acme-private-key",
            },
            solvers: [
                {
                    http01: {
                        ingress: {
                            class: "cilium",
                        },
                    },
                },
            ],
        },
    },
}, { dependsOn: certManager });

// Export cert-manager information
export const certManagerReleaseName = certManager.name;
export const acmeIssuerName = acmeClusterIssuer.metadata.name;