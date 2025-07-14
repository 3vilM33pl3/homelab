import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

// Import networking components (assumes K3s is installed via Ansible)
import "./networking/cilium";

// Import storage components 
import "./storage/longhorn";

// Import certificate management
import "./certificates/cert-manager";

// Sample deployment for testing Cilium ingress
const nginxDeployment = new kubernetes.apps.v1.Deployment("nginx-sample", {
    metadata: {
        name: "nginx-sample",
    },
    spec: {
        selector: { matchLabels: { app: "nginx-sample" } },
        replicas: 2,
        template: {
            metadata: { labels: { app: "nginx-sample" } },
            spec: {
                containers: [{
                    name: "nginx",
                    image: "nginx:alpine",
                    ports: [{ containerPort: 80 }],
                }],
            },
        },
    },
});

// Service for the nginx deployment
const nginxService = new kubernetes.core.v1.Service("nginx-sample", {
    metadata: {
        name: "nginx-sample",
    },
    spec: {
        selector: nginxDeployment.spec.template.metadata.labels,
        ports: [{ port: 80, targetPort: 80 }],
    },
});

// Export values
export const nginxServiceName = nginxService.metadata.name;

// Note: Ingress will be configured after verifying Cilium ingress controller is working
