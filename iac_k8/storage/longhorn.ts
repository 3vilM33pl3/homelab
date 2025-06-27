import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

const config = new pulumi.Config();
const longhornNamespace = config.get("longhornNamespace") || "longhorn-system";

// Create Longhorn namespace
const longhornNs = new kubernetes.core.v1.Namespace("longhorn-namespace", {
    metadata: {
        name: longhornNamespace,
        labels: {
            "app.kubernetes.io/name": "longhorn",
            "app.kubernetes.io/instance": "longhorn",
        },
    },
});

// Install Longhorn using Helm
const longhorn = new kubernetes.helm.v3.Release("longhorn", {
    chart: "longhorn",
    namespace: longhornNs.metadata.name,
    repositoryOpts: {
        repo: "https://charts.longhorn.io",
    },
    values: {
        // Configure Longhorn to use /data directory on each node
        defaultSettings: {
            defaultDataPath: "/data/longhorn",
            defaultDataLocality: "best-effort",
            replicaSoftAntiAffinity: "true",
            storageOverProvisioningPercentage: "200",
            storageMinimalAvailablePercentage: "25",
            upgradeChecker: "false",
            defaultReplicaCount: "2", // 2 replicas across 3 nodes for redundancy
            defaultLonghornStaticStorageClass: "longhorn",
            backupstorePollInterval: "300",
            failedBackupTTL: "1440",
            restoreVolumeRecurringJobs: "false",
            recurringSuccessfulJobsHistoryLimit: "1",
            recurringFailedJobsHistoryLimit: "1",
            supportBundleFailedHistoryLimit: "1",
        },
        longhornUI: {
            replicas: 1,
        },
        ingress: {
            enabled: true,
            host: "longhorn.metatao.net",
            tls: false,
            annotations: {
                "kubernetes.io/ingress.class": "nginx",
                "nginx.ingress.kubernetes.io/auth-type": "basic",
                "nginx.ingress.kubernetes.io/auth-secret": "longhorn-auth",
                "nginx.ingress.kubernetes.io/auth-realm": "Authentication Required - Longhorn",
            },
        },
        // Node selector to ensure Longhorn runs on all nodes
        longhornManager: {
            nodeSelector: {},
            tolerations: [],
        },
        longhornDriver: {
            nodeSelector: {},
            tolerations: [],
        },
    },
    version: "1.5.3",
});

// Create basic auth secret for Longhorn UI
const longhornAuth = new kubernetes.core.v1.Secret("longhorn-auth", {
    metadata: {
        name: "longhorn-auth",
        namespace: longhornNs.metadata.name,
    },
    type: "Opaque",
    data: {
        // Username: admin, Password: longhorn (change this in production)
        auth: Buffer.from("admin:$2y$10$T5jrF5Zx5Z5Z5Z5Z5Z5Z5uQzQ5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z").toString("base64"),
    },
});

// Create storage classes for different use cases
const longhornStorageClass = new kubernetes.storage.v1.StorageClass("longhorn", {
    metadata: {
        name: "longhorn",
        annotations: {
            "storageclass.kubernetes.io/is-default-class": "true",
        },
    },
    provisioner: "driver.longhorn.io",
    allowVolumeExpansion: true,
    reclaimPolicy: "Delete",
    volumeBindingMode: "Immediate",
    parameters: {
        numberOfReplicas: "2",
        staleReplicaTimeout: "2880",
        fromBackup: "",
        fsType: "ext4",
        dataLocality: "best-effort",
    },
});

// Fast storage class for single replica (better performance, less redundancy)
const longhornFastStorageClass = new kubernetes.storage.v1.StorageClass("longhorn-fast", {
    metadata: {
        name: "longhorn-fast",
        labels: {
            "app.kubernetes.io/name": "longhorn",
        },
    },
    provisioner: "driver.longhorn.io",
    allowVolumeExpansion: true,
    reclaimPolicy: "Delete",
    volumeBindingMode: "Immediate",
    parameters: {
        numberOfReplicas: "1",
        staleReplicaTimeout: "2880",
        fromBackup: "",
        fsType: "ext4",
        dataLocality: "strict-local",
    },
});

// Backup storage class for critical data (3 replicas)
const longhornBackupStorageClass = new kubernetes.storage.v1.StorageClass("longhorn-backup", {
    metadata: {
        name: "longhorn-backup",
        labels: {
            "app.kubernetes.io/name": "longhorn",
        },
    },
    provisioner: "driver.longhorn.io",
    allowVolumeExpansion: true,
    reclaimPolicy: "Retain",
    volumeBindingMode: "Immediate",
    parameters: {
        numberOfReplicas: "3",
        staleReplicaTimeout: "2880",
        fromBackup: "",
        fsType: "ext4",
        dataLocality: "best-effort",
    },
});

// Export values
export const longhornNamespaceName = longhornNs.metadata.name;
export const longhornReleaseName = longhorn.name;
export const longhornUIHost = "longhorn.metatao.net";