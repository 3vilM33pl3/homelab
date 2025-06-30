import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

// Import networking components (assumes K3s is installed via Ansible)
import "./networking/cilium";

// Import storage components 
import "./storage/longhorn";

// Import certificate management
import "./certificates/cert-manager";

const config = new pulumi.Config();
const k8sNamespace = config.get("k8sNamespace") || "default";
const appLabels = {
    app: "nginx-ingress",
};

// Create a namespace (user supplies the name of the namespace)
const ingressNs = new kubernetes.core.v1.Namespace("ingressns", {metadata: {
    labels: appLabels,
    name: k8sNamespace,
}});

// Use Helm to install the Nginx ingress controller
const ingressController = new kubernetes.helm.v3.Release("ingresscontroller", {
    chart: "nginx-ingress",
    namespace: ingressNs.metadata.name,
    repositoryOpts: {
        repo: "https://helm.nginx.com/stable",
    },
    skipCrds: true,
    values: {
        controller: {
            enableCustomResources: false,
            appprotect: {
                enable: false,
            },
            appprotectdos: {
                enable: false,
            },
            service: {
                extraLabels: appLabels,
            },
        },
    },
    version: "0.14.1",
});

// Export some values for use elsewhere
export const name = ingressController.name;

// Define the Nginx deployment
const nginxDeployment = new kubernetes.apps.v1.Deployment("nginx", {
    spec: {
        selector: { matchLabels: { app: "nginx" } },
        replicas: 1,
        template: {
            metadata: { labels: { app: "nginx" } },
            spec: {
                containers: [{
                    name: "nginx",
                    image: "nginx",
                    ports: [{ containerPort: 80 }],
                }],
            },
        },
    },
});

// Define the service with a LoadBalancer (K3s will assign IP)
const nginxService = new kubernetes.core.v1.Service("nginx", {
    spec: {
        type: "LoadBalancer",
        selector: nginxDeployment.spec.template.metadata.labels,
        ports: [{ port: 80, targetPort: 80 }],
    },
});

// Export nginx service
export const nginxServiceName = nginxService.metadata.name;
