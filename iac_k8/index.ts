import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

// Import networking components (assumes K3s is installed via Ansible)
import "./networking/cilium";         // Cilium CNI for pod networking
import "./networking/nginx-ingress";  // nginx-ingress-controller for ingress

// Import storage components 
import "./storage/longhorn";

// Import certificate management
import "./certificates/cert-manager";

// Import cluster applications
import "./cluster/kubernetes-dashboard";

// Export important values for reference
export const clusterEndpoint = "https://10.22.6.91:6443";
export const dashboardURL = "https://dashboard.metatao.net";
export const hubbleUIURL = "http://hubble.metatao.net"; // Can be configured with ingress if needed
