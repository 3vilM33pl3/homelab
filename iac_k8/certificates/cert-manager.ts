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

// Note: ClusterIssuer will be created manually after cert-manager is ready
// This avoids timing issues with webhooks during initial deployment

// Uncomment and deploy separately after cert-manager is running:
/*
const acmeClusterIssuer = new kubernetes.apiextensions.CustomResource("acme-issuer", {
    apiVersion: "cert-manager.io/v1",
    kind: "ClusterIssuer",
    metadata: {
        name: "metatao-acme-issuer",
    },
    spec: {
        acme: {
            server: "https://ca.metatao.net/acme/acme/directory",
            email: "admin@metatao.net",
            privateKeySecretRef: {
                name: "metatao-acme-private-key",
            },
            solvers: [
                {
                    http01: {
                        ingress: {
                            class: "nginx",
                        },
                    },
                },
            ],
        },
    },
}, { dependsOn: certManager });
*/

// Export cert-manager information
export const certManagerReleaseName = certManager.name;
// export const acmeIssuerName = acmeClusterIssuer.metadata.name; // Uncomment when ClusterIssuer is enabled