workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters and jobs from Jupyter notebooks or Python scripts"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and jobs on Kubernetes/OpenShift" {
            clusterModule = container "Cluster Module" "Manages interactive RayCluster lifecycle (create, wait, connect, delete)" "Python (ray/cluster/)"
            rayJobModule = container "RayJob Module" "Manages declarative RayJob submission with local file packaging" "Python (ray/rayjobs/)"
            authModule = container "Auth Module" "Unified Kubernetes authentication via kube-authkit" "Python (common/kubernetes_cluster/auth.py)"
            tlsGenerator = container "TLS Certificate Generator" "Generates mTLS certificates (RSA-3072, SHA-256) for Ray client connections" "Python (common/utils/generate_cert.py)"
            kueueModule = container "Kueue Utilities" "Lists local queues, validates priority classes, checks admission status" "Python (common/kueue/kueue.py)"
            widgets = container "Jupyter Widgets" "Interactive cluster management UI for notebook environments" "Python (common/widgets/widgets.py)"
            kuberayClient = container "Vendored KubeRay Client" "Low-level Kubernetes API wrappers for RayCluster and RayJob CRs" "Python (vendored/python_client/)"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob CRs into Ray head/worker pods" "Internal Platform"
        kueueController = softwareSystem "Kueue Controller" "Resource quota and queuing for Ray clusters and jobs" "Internal Platform"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Gateway API for Ray dashboard URL resolution (v3.0+)" "Internal Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Route-based dashboard URL resolution (pre-v3.0 fallback)" "Internal Platform"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD operations, secrets, and resource management" "Infrastructure"
        rayCluster = softwareSystem "Ray Cluster" "Head and worker pods running Ray framework for distributed computing" "Runtime"

        user -> codeflareSDK "Creates clusters and submits jobs via" "Python API"

        clusterModule -> kuberayClient "Builds and applies RayCluster CRs via"
        rayJobModule -> kuberayClient "Builds and applies RayJob CRs via"
        clusterModule -> tlsGenerator "Generates mTLS certificates via"
        clusterModule -> kueueModule "Validates queues via"
        rayJobModule -> kueueModule "Validates priority classes via"
        clusterModule -> widgets "Displays cluster status via"
        clusterModule -> authModule "Authenticates via"
        rayJobModule -> authModule "Authenticates via"

        kuberayClient -> k8sAPI "CRUD operations on CRDs" "HTTPS/6443"
        authModule -> k8sAPI "Authenticates to" "HTTPS/6443 (Bearer/OIDC/OAuth)"
        kueueModule -> k8sAPI "Lists queues and workloads" "HTTPS/6443"
        tlsGenerator -> k8sAPI "Reads CA Secret" "HTTPS/6443"

        codeflareSDK -> rayCluster "Connects for interactive use" "gRPC/10001 mTLS"
        codeflareSDK -> rhoaiGateway "Resolves dashboard URL" "HTTPS/443"
        codeflareSDK -> openshiftRouter "Fallback dashboard URL" "HTTPS/443"

        kuberayOperator -> k8sAPI "Watches and reconciles CRs" "HTTPS/6443"
        kuberayOperator -> rayCluster "Creates and manages pods"
        kueueController -> k8sAPI "Manages resource quotas" "HTTPS/6443"
        rhoaiGateway -> rayCluster "Proxies dashboard access" "HTTP/8265"
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
                background #4a90e2
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
            element "Person" {
                background #6a1b9a
                color #ffffff
                shape person
            }
            element "Container" {
                background #1565c0
                color #ffffff
            }
        }
    }
}
