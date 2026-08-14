workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Defines and submits distributed compute workloads"

        codeflareSDK = softwareSystem "codeflare-sdk" "Python client SDK for submitting and managing distributed compute workloads on Kubernetes via Ray, KubeRay, and Kueue" {
            authModule = container "Authentication Module" "Delegates to kube-authkit for Kubernetes API authentication with kubeconfig, in-cluster, and Bearer token strategies" "Python Module"
            rayJobClient = container "RayJobClient" "Wraps Ray Job Submission Client for direct job dispatch to Ray Dashboard" "Python Module"
            kubeRayClient = container "Vendored KubeRay Client" "Manages RayCluster and RayJob CRDs via Kubernetes CustomObjects API" "Python Module (vendored)"
            kueueModule = container "Kueue Integration" "Queries and manages LocalQueue and ClusterQueue resources for batch scheduling" "Python Module"
            certGenerator = container "TLS Certificate Generator" "Generates self-signed CA and server certs (RSA-3072, SHA-256) for Ray cluster communication" "Python Module"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource operations, CRD management, and RBAC enforcement" "External"
        ray = softwareSystem "Ray" "Distributed compute framework with Dashboard HTTP endpoint for job submission" "External"
        kueue = softwareSystem "Kueue" "Queue-aware batch scheduling system managing LocalQueue and ClusterQueue CRDs" "External"
        kubeAuthKit = softwareSystem "kube-authkit" "Authentication library providing auto-detection of Kubernetes credentials" "External"
        kubeRay = softwareSystem "KubeRay Operator" "Kubernetes operator managing RayCluster and RayJob custom resources" "External"

        user -> codeflareSDK "Defines workloads, submits jobs, monitors status" "Python API"
        codeflareSDK -> kubernetesAPI "Creates/reads CRDs, manages Secrets" "HTTPS/443 TLS"
        codeflareSDK -> ray "Submits and monitors jobs" "HTTP/HTTPS configurable TLS"
        codeflareSDK -> kueue "Queries queue capacity and status" "via Kubernetes API"
        codeflareSDK -> kubeAuthKit "Delegates credential auto-detection" "Python library call"

        authModule -> kubeAuthKit "Auto-detect credentials" "Python library call"
        authModule -> kubernetesAPI "Authenticate" "HTTPS/443"
        rayJobClient -> ray "Submit/monitor jobs" "HTTP/HTTPS"
        kubeRayClient -> kubernetesAPI "Create RayCluster/RayJob CRDs" "HTTPS/443"
        kueueModule -> kubernetesAPI "Query LocalQueue/ClusterQueue" "HTTPS/443"
        certGenerator -> kubernetesAPI "Store TLS certs as Secrets" "HTTPS/443"

        kubeRay -> kubernetesAPI "Watches RayCluster/RayJob CRDs" "HTTPS/443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
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
