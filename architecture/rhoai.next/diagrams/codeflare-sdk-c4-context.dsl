workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters, submits ML training jobs from Jupyter notebooks"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for requesting, managing, and interacting with Ray clusters and batch workloads on Kubernetes/OpenShift" {
            clusterModule = container "ray.cluster" "Core Cluster class for creating, scaling, monitoring, and deleting Ray clusters" "Python Module"
            appwrapperModule = container "ray.appwrapper" "AWManager for submitting/removing AppWrapper CRs wrapping RayCluster resources" "Python Module"
            jobClient = container "ray.client" "RayJobClient wrapper for Ray Job Submission Client" "Python Module"
            authModule = container "common.kubernetes_cluster" "Token and KubeConfig authentication, K8s API client management" "Python Module"
            kueueModule = container "common.kueue" "Kueue LocalQueue discovery, listing, and queue label management" "Python Module"
            certModule = container "common.utils.generate_cert" "TLS certificate generation for Ray client-cluster mTLS" "Python Module"
            widgetsModule = container "common.widgets" "Jupyter ipywidgets-based UI for interactive cluster management" "Python Module"
        }

        kubeRay = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into Ray head/worker pods" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper CRs for Kueue integration" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Fair-share workload scheduling via LocalQueues" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all CRD operations" "Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external Route-based access to Ray Dashboard" "Platform"
        rayDashboard = softwareSystem "Ray Dashboard" "Ray cluster web UI and job submission REST API" "Ray Cluster"
        jupyterEnv = softwareSystem "Jupyter Notebook Environment" "RHOAI workbench where SDK executes" "Platform"

        # User interactions
        dataScientist -> codeflareSDK "Creates clusters, submits jobs via Python API"
        dataScientist -> jupyterEnv "Works in Jupyter notebooks"

        # SDK to platform
        codeflareSDK -> k8sAPI "CRD CRUD operations (RayCluster, AppWrapper, LocalQueue, Route, Secret)" "HTTPS/6443, Bearer Token"
        codeflareSDK -> rayDashboard "Submits and monitors Ray jobs" "HTTP(S)/8265, Bearer Token"
        codeflareSDK -> openshiftRouter "Discovers Ray Dashboard and Client URLs" "HTTPS/443"

        # Platform operator interactions
        kubeRay -> k8sAPI "Reconciles RayCluster CRs into pods" "HTTPS/6443, ServiceAccount"
        codeflareOperator -> k8sAPI "Reconciles AppWrapper CRs" "HTTPS/6443, ServiceAccount"
        kueue -> k8sAPI "Manages workload scheduling via LocalQueues" "HTTPS/6443, ServiceAccount"

        # Container relationships
        clusterModule -> authModule "Authenticates via"
        clusterModule -> appwrapperModule "Wraps RayCluster in AppWrapper"
        clusterModule -> kueueModule "Discovers default queue"
        jobClient -> certModule "Uses TLS certs for mTLS"
        widgetsModule -> clusterModule "Manages clusters via UI"
    }

    views {
        systemContext codeflareSDK "SystemContext" {
            include *
            autoLayout
        }

        container codeflareSDK "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Ray Cluster" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
