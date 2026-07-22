workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for distributed ML workloads from Jupyter notebooks"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for Ray cluster lifecycle management on Kubernetes/OpenShift" {
            clusterModule = container "Cluster Module" "Core abstraction for creating, scaling, and deleting RayCluster resources" "Python Class"
            configModule = container "ClusterConfiguration" "Configuration specification for Ray cluster resources (CPU, memory, GPU)" "Python Dataclass"
            awManager = container "AWManager" "Manager for submitting and removing AppWrapper YAML files to Kueue local queues" "Python Class"
            rayJobClient = container "RayJobClient" "Wrapper around Ray JobSubmissionClient for job lifecycle operations" "Python Class"
            generateCert = container "generate_cert" "TLS certificate generation utilities for secure Ray client-cluster communication" "Python Module"
            kueueIntegration = container "Kueue Integration" "Functions for LocalQueue discovery, default queue resolution, and queue label management" "Python Module"
            jupyterWidgets = container "Jupyter Widgets" "Interactive ipywidgets-based UI for cluster management in Jupyter notebooks" "Python Module"
            yamlGenerator = container "YAML Generator" "Template-based RayCluster YAML generation from base-template.yaml" "Python Module"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD operations" "External"
        kubeRayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into Ray head and worker pods" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper CRs for Kueue scheduling integration" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queuing system for batch scheduling" "Internal RHOAI"
        rayDashboard = softwareSystem "Ray Dashboard" "Web UI and REST API on Ray head node for job management" "Internal Ray"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Exposes Ray dashboard and client endpoints externally" "External"
        odhNotebooks = softwareSystem "ODH Notebooks" "Jupyter notebook environment where SDK runs" "Internal RHOAI"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Custom CA certificates ConfigMap injected into Ray pod specs" "Internal RHOAI"

        dataScientist -> codeflareSdk "Instantiates Cluster, submits jobs via Python API"
        codeflareSdk -> k8sApiServer "CRUD on RayCluster, AppWrapper, LocalQueue, Route, Secret CRs" "HTTPS/6443, Bearer Token"
        codeflareSdk -> rayDashboard "Submits and monitors Ray jobs" "HTTPS/8265 via Route"
        codeflareSdk -> openshiftRoutes "Discovers Ray dashboard URLs" "HTTPS/6443"

        kubeRayOperator -> k8sApiServer "Watches RayCluster CRs, provisions Ray pods" "Internal"
        codeflareOperator -> k8sApiServer "Watches AppWrapper CRs, integrates with Kueue" "Internal"
        kueue -> k8sApiServer "Watches LocalQueue CRs, schedules workloads" "Internal"

        odhNotebooks -> codeflareSdk "SDK runs inside notebook pods" "Python import"
        codeflareSdk -> odhTrustedCA "Mounts CA bundle ConfigMap in generated RayCluster specs" "Volume mount"

        clusterModule -> configModule "Reads configuration"
        clusterModule -> yamlGenerator "Generates RayCluster YAML"
        clusterModule -> awManager "Wraps in AppWrapper"
        clusterModule -> rayJobClient "Creates job client"
        clusterModule -> generateCert "Generates TLS certs"
        clusterModule -> kueueIntegration "Discovers queues"
        jupyterWidgets -> clusterModule "Manages cluster lifecycle"
    }

    views {
        systemContext codeflareSdk "SystemContext" {
            include *
            autoLayout
        }

        container codeflareSdk "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Ray" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
