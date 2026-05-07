workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters and jobs via Jupyter notebooks or Python scripts"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and Ray jobs on Kubernetes/OpenShift" {
            clusterModule = container "Cluster Module" "Manages RayCluster CR lifecycle — create, apply, status, delete, wait_ready" "Python"
            rayJobModule = container "RayJob Module" "Manages RayJob CR lifecycle — submit, stop, resubmit, delete, status tracking" "Python"
            authModule = container "Authentication Module" "Kubernetes authentication via kube-authkit (auto-detect, kubeconfig, in-cluster)" "Python"
            tlsGenerator = container "TLS Certificate Generator" "Generates client TLS certificates signed by KubeRay CA for mTLS connections" "Python (cryptography)"
            kueueIntegration = container "Kueue Integration" "Lists local queues, validates queue existence, manages workload labels" "Python"
            jupyterWidgets = container "Jupyter Widgets" "ipywidgets-based UI for interactive cluster management in notebooks" "Python (ipywidgets)"
            rayJobClient = container "RayJobClient" "Thin wrapper around Ray JobSubmissionClient for direct job submission" "Python"
            vendoredKubeRay = container "Vendored KubeRay Client" "Forked kuberay python_client for RayJob and RayCluster API operations" "Python"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource operations" "Infrastructure"
        kubeRayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob custom resources into pods and services" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queuing and scheduling for Ray clusters/jobs" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Gateway API-based ingress for Ray dashboard access (v3.0+)" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Route-based ingress for Ray dashboard access (pre-v3.0)" "Infrastructure"
        rayCluster = softwareSystem "Ray Cluster" "Distributed compute cluster with head and worker pods" "Runtime"
        containerRegistry = softwareSystem "Container Registry" "quay.io/modh/ray — CUDA/ROCm runtime images" "External"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Custom CA certificates for Ray cluster pods" "Internal RHOAI"

        # User interactions
        user -> codeflareSdk "Creates clusters, submits jobs via Python API"

        # SDK → K8s API
        clusterModule -> kubernetesApi "Server-Side Apply RayCluster CR" "HTTPS/6443 Bearer Token"
        rayJobModule -> kubernetesApi "Create RayJob CR, Secrets" "HTTPS/6443 Bearer Token"
        authModule -> kubernetesApi "Authenticate, discover namespace" "HTTPS/6443"
        tlsGenerator -> kubernetesApi "Read CA Secret" "HTTPS/6443 Bearer Token"
        kueueIntegration -> kubernetesApi "List LocalQueues, Workloads" "HTTPS/6443 Bearer Token"
        clusterModule -> kubernetesApi "List HTTPRoutes, Routes, Ingresses" "HTTPS/6443 Bearer Token"

        # SDK → Ray Cluster
        rayJobClient -> rayCluster "Submit jobs via Dashboard API" "HTTP/8265 or HTTPS/443"
        codeflareSdk -> rayCluster "ray.init() direct connection" "gRPC/10001 mTLS"
        tlsGenerator -> rayCluster "mTLS client cert for connections" "gRPC mTLS"

        # Platform operator interactions
        kubeRayOperator -> kubernetesApi "Reconcile RayCluster/RayJob CRs" "HTTPS/6443 SA Token"
        kueue -> kubernetesApi "Manage Workload admission" "HTTPS/6443 SA Token"
        kubeRayOperator -> rayCluster "Create pods, services, CA secrets"

        # Ingress
        rhoaiGateway -> rayCluster "Proxy dashboard requests" "HTTPS/443 → HTTP/8265"
        openshiftRouter -> rayCluster "Proxy dashboard requests" "HTTPS/443 → HTTP/8265"

        # External
        rayCluster -> containerRegistry "Pull runtime images" "HTTPS/443"
        rayCluster -> odhTrustedCA "Mount custom CA certs" "ConfigMap volume"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Runtime" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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
