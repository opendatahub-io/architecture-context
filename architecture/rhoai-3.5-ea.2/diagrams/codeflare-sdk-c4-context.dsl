workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters, submits distributed computing jobs via Jupyter notebooks"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and jobs on Kubernetes via KubeRay operator" {
            clusterModule = container "ray.cluster Module" "RayCluster CR lifecycle management (create, apply, status, delete)" "Python"
            rayjobModule = container "ray.rayjobs Module" "RayJob CR submission and management with managed cluster support" "Python"
            clientModule = container "ray.client Module" "Wrapper around Ray JobSubmissionClient for direct job submission" "Python"
            authModule = container "common.kubernetes_cluster" "Kubernetes authentication via kube-authkit (OIDC, OAuth, auto-detect, token)" "Python"
            kueueModule = container "common.kueue Module" "Kueue LocalQueue discovery, default queue detection, WorkloadPriorityClass validation" "Python"
            certModule = container "common.utils.generate_cert" "mTLS certificate generation (RSA 3072-bit, X.509 v3) for secure Ray client connections" "Python"
            widgetModule = container "common.widgets Module" "IPython/Jupyter widgets for interactive cluster management UI" "Python"
            vendoredClient = container "Vendored KubeRay Client" "Vendored fork of KubeRay Python SDK for RayCluster/RayJob API operations" "Python"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob custom resources into Kubernetes pods and services" "Internal Platform"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system for workload prioritization and fair scheduling" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for resource management" "Infrastructure"
        rhoaiGateway = softwareSystem "RHOAI Platform Gateway" "Gateway API / HTTPRoute for dashboard URL routing (RHOAI 3.x)" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Legacy route-based ingress for dashboard access (RHOAI 2.x)" "Internal Platform"
        gatewayConfig = softwareSystem "ODH/RHOAI GatewayConfig" "Fallback hostname resolution for dashboard URL construction" "Internal Platform"
        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster with head node (dashboard 8265, client 10001) and workers" "Runtime"
        s3Storage = softwareSystem "Container Registry" "quay.io/modh/ray runtime images for Ray cluster pods" "External"

        # User interactions
        dataScientist -> codeflareSdk "Creates clusters, submits jobs via Python API" "Python API"

        # SDK to Kubernetes API
        codeflareSdk -> k8sAPI "Creates/manages RayCluster, RayJob CRs, Secrets" "HTTPS/6443, Bearer/OIDC"

        # SDK to Ray Cluster (direct connections)
        codeflareSdk -> rayCluster "Job submission (dashboard), distributed computing (client)" "HTTPS/8265 mTLS, TCP/10001 mTLS"

        # KubeRay reconciliation
        kuberayOperator -> k8sAPI "Watches RayCluster/RayJob CRs, creates pods/services" "HTTPS/6443, Service Account"
        kuberayOperator -> rayCluster "Provisions and manages Ray cluster pods" "Kubernetes API"

        # Kueue integration
        codeflareSdk -> kueue "Discovers queues, validates priority classes" "HTTPS/6443 via K8s API"

        # Dashboard URL discovery
        codeflareSdk -> rhoaiGateway "Discovers dashboard URLs via HTTPRoute/Gateway" "HTTPS/6443 via K8s API"
        codeflareSdk -> openshiftRoutes "Fallback dashboard URL discovery" "HTTPS/6443 via K8s API"
        codeflareSdk -> gatewayConfig "Fallback hostname resolution" "HTTPS/6443 via K8s API"

        # Container images
        rayCluster -> s3Storage "Pulls runtime images" "HTTPS/443"

        # Internal container relationships
        clusterModule -> vendoredClient "Creates RayCluster CRs"
        rayjobModule -> vendoredClient "Creates RayJob CRs"
        clusterModule -> certModule "Generates mTLS client certs"
        clusterModule -> kueueModule "Discovers default queue"
        rayjobModule -> kueueModule "Validates priority class"
        clusterModule -> widgetModule "Renders status widgets"
        clientModule -> rayCluster "Direct job submission"
        vendoredClient -> authModule "Gets authenticated K8s client"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
