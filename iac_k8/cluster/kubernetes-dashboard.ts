import * as kubernetes from "@pulumi/kubernetes";

// Create namespace for Kubernetes Dashboard
const dashboardNamespace = new kubernetes.core.v1.Namespace("kubernetes-dashboard", {
    metadata: {
        name: "kubernetes-dashboard",
    },
});

// Apply the standard Kubernetes Dashboard manifest
// Using the recommended v2.7.0 manifest from kubernetes/dashboard project
const dashboardManifest = new kubernetes.yaml.ConfigFile("kubernetes-dashboard-manifest", {
    file: "https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml",
}, { dependsOn: dashboardNamespace });

// Create admin service account for dashboard access
const dashboardAdminServiceAccount = new kubernetes.core.v1.ServiceAccount("dashboard-admin", {
    metadata: {
        name: "dashboard-admin",
        namespace: dashboardNamespace.metadata.name,
    },
}, { dependsOn: dashboardNamespace });

// Create cluster role binding for admin access
const dashboardAdminClusterRoleBinding = new kubernetes.rbac.v1.ClusterRoleBinding("dashboard-admin", {
    metadata: {
        name: "dashboard-admin",
    },
    roleRef: {
        apiGroup: "rbac.authorization.k8s.io",
        kind: "ClusterRole",
        name: "cluster-admin",
    },
    subjects: [{
        kind: "ServiceAccount",
        name: dashboardAdminServiceAccount.metadata.name,
        namespace: dashboardNamespace.metadata.name,
    }],
}, { dependsOn: dashboardAdminServiceAccount });

// Create ingress for dashboard with TLS
const dashboardIngress = new kubernetes.networking.v1.Ingress("kubernetes-dashboard", {
    metadata: {
        name: "kubernetes-dashboard",
        namespace: dashboardNamespace.metadata.name,
        annotations: {
            "kubernetes.io/ingress.class": "nginx",
            "cert-manager.io/cluster-issuer": "metatao-acme-issuer",
            "nginx.ingress.kubernetes.io/backend-protocol": "HTTPS",
            "nginx.ingress.kubernetes.io/ssl-redirect": "true",
        },
    },
    spec: {
        tls: [{
            hosts: ["dashboard.metatao.net"],
            secretName: "dashboard-tls-cert",
        }],
        rules: [{
            host: "dashboard.metatao.net",
            http: {
                paths: [{
                    path: "/",
                    pathType: "Prefix",
                    backend: {
                        service: {
                            name: "kubernetes-dashboard", // Standard dashboard service name
                            port: {
                                number: 443,
                            },
                        },
                    },
                }],
            },
        }],
    },
}, { dependsOn: [dashboardManifest, dashboardNamespace] });

// Export dashboard information
export const dashboardManifestName = dashboardManifest.name;
export const dashboardNamespaceName = dashboardNamespace.metadata.name;
export const dashboardIngressHost = "dashboard.metatao.net";
export const dashboardAdminServiceAccountName = dashboardAdminServiceAccount.metadata.name;