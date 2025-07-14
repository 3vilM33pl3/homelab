import * as kubernetes from "@pulumi/kubernetes";

// Create an example Ingress resource using Cilium ingress controller
const exampleIngress = new kubernetes.networking.v1.Ingress("example-ingress", {
    metadata: {
        name: "example-ingress",
        annotations: {
            "kubernetes.io/ingress.class": "cilium",
            "cert-manager.io/cluster-issuer": "metatao-acme-issuer", // For TLS
        },
    },
    spec: {
        rules: [{
            host: "example.metatao.net",
            http: {
                paths: [{
                    path: "/",
                    pathType: "Prefix",
                    backend: {
                        service: {
                            name: "nginx",
                            port: {
                                number: 80,
                            },
                        },
                    },
                }],
            },
        }],
        tls: [{
            secretName: "example-tls-cert",
            hosts: ["example.metatao.net"],
        }],
    },
});

export const ingressHost = exampleIngress.spec.rules[0].host;