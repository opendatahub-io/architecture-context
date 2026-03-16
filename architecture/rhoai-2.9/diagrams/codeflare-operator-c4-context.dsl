workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray distributed computing clusters for ML workloads"

        codeflare = softwareSystem "CodeFlare Operator" "Enhances KubeRay RayClusters with OAuth authentication, mTLS encryption, and network security policies" {
            controller = container "RayCluster Controller" "Watches RayCluster CRDs and creates OAuth proxies, mTLS certificates, NetworkPolicies, Routes/Ingresses" "Go Reconciler"
            mutatingWebhook = container "Mutating Webhook" "Injects OAuth proxy sidecar and mTLS init containers into RayCluster pods" "Go Admission Webhook"
            validatingWebhook = container "Validating Webhook" "Validates RayCluster configuration for OAuth and mTLS requirements" "Go Admission Webhook"
            certController = container "Certificate Controller" "Rotates and manages webhook server TLS certificates" "Go Certificate Manager"
            metrics = container "Metrics Endpoint" "Exposes Prometheus metrics" "HTTP Service :8080"
            health = container "Health Endpoints" "Liveness and readiness probes" "HTTP Service :8081"
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and manages Ray cluster lifecycle" "External Operator"
        certMgr = softwareSystem "cert-controller" "Rotates TLS certificates for webhook server" "External Controller"
        osAuth = softwareSystem "OpenShift OAuth" "Provides OAuth-based authentication for Ray Dashboard" "External OpenShift Service"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External Platform"
        prometheus = softwareSystem "Prometheus" "Collects and stores metrics from operator" "External Monitoring"

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster with enhanced security" "Managed Workload" {
            rayHead = container "Ray Head Pod" "Runs Ray head node with OAuth proxy sidecar" "Ray + OAuth Proxy"
            rayWorkers = container "Ray Worker Pods" "Runs Ray worker nodes with mTLS certificates" "Ray Workers"
        }

        user -> codeflare "Creates RayCluster via kubectl/oc"
        user -> rayCluster "Accesses Ray Dashboard via OAuth"

        codeflare -> kuberay "Watches for RayCluster CRD"
        codeflare -> k8sAPI "Manages Kubernetes resources (Secrets, Services, Routes, NetworkPolicies)"
        codeflare -> rayCluster "Enhances with OAuth, mTLS, NetworkPolicies"

        k8sAPI -> codeflare "Calls admission webhooks for RayCluster validation/mutation"

        certMgr -> codeflare "Rotates webhook TLS certificates"

        rayCluster -> osAuth "Authenticates users via OAuth proxy"

        prometheus -> codeflare "Scrapes metrics from :8080/metrics"

        kuberay -> rayCluster "Manages Ray cluster lifecycle (Pods, Services)"
        kuberay -> k8sAPI "Creates and manages Ray resources"
    }

    views {
        systemContext codeflare "CodeFlareSystemContext" {
            include *
            autoLayout
        }

        container codeflare "CodeFlareContainers" {
            include *
            autoLayout
        }

        container rayCluster "RayClusterContainers" {
            include *
            autoLayout
        }

        styles {
            element "External Operator" {
                background #999999
                color #ffffff
            }
            element "External Controller" {
                background #999999
                color #ffffff
            }
            element "External OpenShift Service" {
                background #cc0000
                color #ffffff
            }
            element "External Platform" {
                background #326ce5
                color #ffffff
            }
            element "External Monitoring" {
                background #e6522c
                color #ffffff
            }
            element "Managed Workload" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
