workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed Ray compute workloads"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and jobs on Kubernetes" {
            facade = container "Codeflare Facade" "Single entrypoint with handler pattern" "Python"
            clusterHandler = container "ClusterHandler" "Manages RayCluster lifecycle" "Python"
            jobHandler = container "JobHandler" "Manages RayJob lifecycle" "Python"
            certGen = container "Certificate Generator" "Generates mTLS certs (RSA-3072, SHA-256)" "Python / cryptography"
            kueueUtils = container "Kueue Utilities" "Queue resolution and priority validation" "Python"
            authModule = container "Auth Module" "ContextVar-based K8s client isolation" "Python / kube-authkit"
            vendoredClient = container "Vendored KubeRay Client" "Frozen KubeRay Python client (import-guarded)" "Python"
        }

        kubeRay = softwareSystem "KubeRay Operator" "Manages Ray cluster and job resources on Kubernetes" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queuing and resource quota management" "Internal RHOAI"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "DataScienceCluster, GatewayConfig CRDs" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD operations" "External"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "HTTPRoute and Gateway resources for ingress" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "OpenShift-native ingress routing" "External"
        rayDashboard = softwareSystem "Ray Dashboard" "Job submission and monitoring interface" "External"
        localFS = softwareSystem "Local Filesystem" "TLS certificate storage (~/.local/share/codeflare/tls/)" "External"

        dataScientist -> codeflareSDK "Creates clusters and submits jobs via Python API"

        facade -> clusterHandler "Delegates cluster operations"
        facade -> jobHandler "Delegates job operations"
        facade -> authModule "Authenticates to Kubernetes"
        clusterHandler -> certGen "Generates mTLS client certificates"
        clusterHandler -> kueueUtils "Resolves queues and validates priorities"
        jobHandler -> vendoredClient "Constructs RayJob manifests"

        codeflareSDK -> k8sAPI "CRD operations (RayCluster, RayJob, Kueue resources)" "HTTPS/6443"
        codeflareSDK -> kubeRay "Creates ray.io/v1 RayCluster and RayJob CRs" "via K8s API"
        codeflareSDK -> kueue "Resolves LocalQueues, validates WorkloadPriorityClasses" "via K8s API"
        codeflareSDK -> rhoaiPlatform "Reads DataScienceCluster, GatewayConfig CRs" "via K8s API"
        codeflareSDK -> gatewayAPI "Discovers HTTPRoutes for dashboard URL" "via K8s API"
        codeflareSDK -> openshiftRoutes "Fallback dashboard URL discovery" "via K8s API"
        codeflareSDK -> rayDashboard "Submits jobs and monitors status" "HTTPS/8265 mTLS"
        codeflareSDK -> localFS "Stores generated TLS certificates" "Filesystem (0600)"
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
                background #5ba0d9
                color #ffffff
            }
        }
    }
}
