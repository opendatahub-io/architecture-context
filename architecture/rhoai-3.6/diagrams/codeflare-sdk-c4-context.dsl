workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters, submits distributed computing jobs from Jupyter notebooks"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for Ray cluster lifecycle, job submission, and Kueue integration on Kubernetes/OpenShift" {
            facade = container "Codeflare Facade" "Single entrypoint class with ClusterHandler and JobHandler" "Python Class"
            authLayer = container "Authentication Layer" "kube-authkit integration with ContextVar-based client isolation" "Python Module"
            clusterMgmt = container "Cluster Management" "Builds RayCluster manifests, resolves dashboard URLs, manages TLS certificates" "Python Module"
            jobMgmt = container "Job Management" "RayJob CR creation and Ray JobSubmissionClient wrapper" "Python Module"
            kueueIntegration = container "Kueue Integration" "Queue labeling, autoscaling policy gating, operator version detection" "Python Module"
            certGen = container "Certificate Generator" "RSA-3072 key generation, x509 certificate creation for mTLS" "Python Module"
            vendoredClient = container "Vendored KubeRay Client" "Isolated KubeRay Python client for RayJob API operations" "Python Package"
        }

        kubeRayOperator = softwareSystem "KubeRay Operator" "Manages RayCluster and RayJob lifecycle on Kubernetes" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing and resource management for Kubernetes" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "Infrastructure"
        openshiftRoutes = softwareSystem "OpenShift Routes API" "Exposes services via Routes on OpenShift" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic management (RHOAI v3.0+)" "Infrastructure"
        odhPlatform = softwareSystem "ODH Platform Services" "GatewayConfig and DataScienceCluster CRDs" "Internal RHOAI"
        rayHeadNode = softwareSystem "Ray Head Node" "Distributed computing cluster head with dashboard and job API" "Internal"
        pypi = softwareSystem "PyPI" "Python package repository" "External"

        # User interactions
        dataScientist -> codeflareSDK "Creates clusters, submits jobs via Python API"

        # Internal container relationships
        facade -> authLayer "Authenticates via kube-authkit"
        facade -> clusterMgmt "Creates/manages Ray clusters"
        facade -> jobMgmt "Submits/monitors Ray jobs"
        clusterMgmt -> kueueIntegration "Applies queue labels, checks autoscaling policy"
        clusterMgmt -> certGen "Generates mTLS certificates for Ray connections"
        jobMgmt -> vendoredClient "Uses for RayJob API operations"

        # External interactions
        codeflareSDK -> k8sAPI "All resource operations" "HTTPS/6443, TLS 1.2+, Bearer/OIDC/OAuth"
        codeflareSDK -> kubeRayOperator "Creates RayCluster and RayJob CRs" "via Kubernetes API"
        codeflareSDK -> kueue "Queries LocalQueue, labels resources for queuing" "via Kubernetes API"
        codeflareSDK -> openshiftRoutes "Resolves dashboard URLs (pre-v3.0)" "via Kubernetes API"
        codeflareSDK -> gatewayAPI "Resolves dashboard URLs (v3.0+)" "via Kubernetes API"
        codeflareSDK -> odhPlatform "Queries GatewayConfig, DataScienceCluster" "via Kubernetes API"
        codeflareSDK -> rayHeadNode "Submits jobs, polls status, retrieves logs" "HTTPS/8265, TLS/mTLS"
        codeflareSDK -> pypi "Package installation" "HTTPS/443"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #6c5ce7
                color #ffffff
            }
            element "External" {
                background #e17055
                color #ffffff
            }
        }
    }
}
