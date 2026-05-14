workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters and jobs from Jupyter notebooks"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and jobs on Kubernetes with Kueue integration" {
            rayCluster = container "ray.cluster" "Ray cluster lifecycle management (create, apply, delete, status, wait_ready)" "Python Module"
            rayJobs = container "ray.rayjobs" "Ray job submission and management via RayJob CRDs" "Python Module"
            rayClient = container "ray.client" "Direct HTTP job submission via Ray JobSubmissionClient" "Python Module"
            kubeAuth = container "kubernetes_cluster" "Kubernetes authentication and API client management" "Python Module"
            kueueMod = container "kueue" "LocalQueue listing, default queue resolution, WorkloadPriorityClass validation" "Python Module"
            utils = container "utils" "TLS certificate generation (RSA 3072-bit), Ray image selection, validation" "Python Module"
            widgets = container "widgets" "Jupyter/IPython interactive widgets for cluster management UI" "Python Module"
            vendoredClient = container "vendored.python_client" "Vendored KubeRay Python client (RayClusterApi, RayjobApi)" "Python Module"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Manages Ray cluster and job lifecycle on Kubernetes via CRDs" "External"
        kueueController = softwareSystem "Kueue Controller" "Job queuing, admission control, and resource quota management" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        gatewayApi = softwareSystem "Gateway API / OpenShift Routes" "Dashboard URL resolution via HTTPRoute, Route, or Ingress" "External"
        rayHead = softwareSystem "Ray Head Node" "Ray cluster head providing dashboard, GCS, and client ports" "External"
        redis = softwareSystem "Redis" "External state store for GCS fault tolerance" "External Optional"
        containerRegistry = softwareSystem "Container Registry" "quay.io/modh/ray - Ray runtime container images" "External"
        kubeAuthkit = softwareSystem "kube-authkit" "Authentication auto-detection (OIDC, OAuth, token, kubeconfig)" "External Library"

        # User interactions
        user -> codeflareSdk "Creates clusters and submits jobs via Python API"
        user -> widgets "Manages clusters via Jupyter notebook widgets"

        # Internal container relationships
        rayCluster -> vendoredClient "Delegates CRD operations"
        rayJobs -> vendoredClient "Delegates CRD operations"
        rayCluster -> kubeAuth "Authenticates API calls"
        rayJobs -> kubeAuth "Authenticates API calls"
        rayClient -> kubeAuth "Authenticates API calls"
        rayCluster -> utils "Generates TLS certificates"
        rayJobs -> utils "Generates TLS certificates"
        rayCluster -> kueueMod "Queue integration"
        rayJobs -> kueueMod "Queue integration"
        widgets -> rayCluster "Manages cluster lifecycle"
        kubeAuth -> kubeAuthkit "Delegates authentication" "Python library"

        # External system relationships
        codeflareSdk -> k8sApi "CRD CRUD, Secret management, namespace discovery" "HTTPS/6443 TLS 1.2+"
        codeflareSdk -> rayHead "Job submission, status polling, dashboard health check" "HTTP(S)/8265 mTLS optional"
        vendoredClient -> k8sApi "CustomObjectsApi for ray.io CRDs" "HTTPS/6443"
        kuberayOperator -> k8sApi "Watches RayCluster/RayJob CRDs" "HTTPS/6443"
        kueueController -> k8sApi "Manages Workload admission" "HTTPS/6443"
        codeflareSdk -> gatewayApi "Discovers dashboard URL" "HTTPS/6443"
        rayHead -> redis "GCS fault tolerance state" "TCP"
        rayHead -> containerRegistry "Pulls runtime images" "HTTPS/443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "External Library" {
                background #b0bec5
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
