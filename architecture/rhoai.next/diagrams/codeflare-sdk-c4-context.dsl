workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters, submits ML workloads from Jupyter notebooks"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for Ray cluster lifecycle management, job submission, and workload queuing on Kubernetes/OpenShift" {
            clusterModule = container "ray.cluster" "Cluster class for creating, scaling, monitoring, and deleting Ray clusters" "Python Module"
            appwrapperModule = container "ray.appwrapper" "AWManager for AppWrapper CR operations wrapping RayCluster resources" "Python Module"
            rayJobClient = container "ray.client" "RayJobClient wrapper for Ray Job Submission Client" "Python Module"
            authModule = container "common.kubernetes_cluster" "Authentication (Token, KubeConfig) and Kubernetes API client management" "Python Module"
            kueueModule = container "common.kueue" "Kueue LocalQueue discovery and queue label management" "Python Module"
            certModule = container "common.utils.generate_cert" "TLS certificate generation for Ray client-cluster mTLS" "Python Module"
            widgetsModule = container "common.widgets" "Jupyter ipywidgets-based UI for interactive cluster management" "Python Module"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Central API for all cluster resource operations" "External"
        kubeRay = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into Ray head/worker pods" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper CRs for Kueue integration" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Fair-share workload scheduling for Kubernetes" "Internal RHOAI"
        rayDashboard = softwareSystem "Ray Dashboard" "Ray cluster management and job submission API" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Manages Routes for external access to cluster services" "External"
        jupyterNotebook = softwareSystem "Jupyter Notebook Environment" "RHOAI workbench where SDK runs" "Internal RHOAI"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "ConfigMap with custom CA certificates for trust chain" "Internal RHOAI"

        dataScientist -> codeflareSdk "Creates clusters, submits jobs via Python API"
        dataScientist -> jupyterNotebook "Works in notebook environment"
        jupyterNotebook -> codeflareSdk "Hosts SDK as pip package"

        codeflareSdk -> k8sApiServer "CRD CRUD operations (RayCluster, AppWrapper, LocalQueue, Route, Secret)" "HTTPS/6443"
        codeflareSdk -> rayDashboard "Submits and monitors Ray jobs" "HTTP(S)/8265"
        codeflareSdk -> openshiftRouter "Discovers Ray Dashboard and Client URLs via Routes" "HTTPS/6443"

        k8sApiServer -> kubeRay "Notifies of RayCluster CR changes"
        k8sApiServer -> codeflareOperator "Notifies of AppWrapper CR changes"
        k8sApiServer -> kueue "Notifies of workload scheduling"

        kubeRay -> k8sApiServer "Creates Ray head/worker pods" "HTTPS/6443"

        clusterModule -> authModule "Authenticates via"
        clusterModule -> appwrapperModule "Wraps in AppWrapper"
        clusterModule -> kueueModule "Discovers queues"
        clusterModule -> certModule "Generates TLS certs"
        rayJobClient -> rayDashboard "Submits jobs" "HTTP(S)/8265"
        widgetsModule -> clusterModule "Manages clusters"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
        }
    }
}
