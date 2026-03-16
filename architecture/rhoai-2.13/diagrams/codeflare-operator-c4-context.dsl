workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed Ray clusters for AI/ML workloads"

        codeflare = softwareSystem "CodeFlare Operator" "Manages CodeFlare distributed workload stack components including RayClusters and AppWrappers with security enhancements" {
            manager = container "Operator Manager" "Main operator process" "Go Operator" {
                rayController = component "RayCluster Controller" "Reconciles RayCluster resources, configures security (mTLS, OAuth), networking, and policies"
                appController = component "AppWrapper Controller" "Manages AppWrapper resources for gang scheduling and quota management (optional)"
                rayWebhook = component "RayCluster Webhook" "Validates and mutates RayCluster resources"
                appWebhook = component "AppWrapper Webhook" "Validates and mutates AppWrapper resources"
                certController = component "Certificate Controller" "Manages webhook TLS certificates with automatic rotation"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server :8080"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP Server :8081"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages RayCluster CRD and Ray cluster lifecycle; CodeFlare enhances with security" "External"
        kueue = softwareSystem "Kueue" "Workload scheduling and quota management for AppWrappers" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        oauth = softwareSystem "OpenShift OAuth / OAuth Provider" "User authentication for Ray dashboards" "External"
        odh = softwareSystem "OpenDataHub Operator" "Platform operator managing ODH/RHOAI components" "Internal ODH"

        rayCluster = softwareSystem "Ray Cluster" "Distributed Ray cluster with head and worker nodes" {
            rayHead = container "Ray Head Pod" "Ray head node with OAuth proxy sidecar" "Ray + OAuth Proxy"
            rayWorkers = container "Ray Worker Pods" "Ray worker nodes" "Ray"
        }

        # User interactions
        user -> codeflare "Creates RayCluster and AppWrapper CRs via kubectl/SDK"
        user -> rayCluster "Accesses Ray dashboard via browser" "HTTPS/443 with OAuth"

        # CodeFlare interactions
        codeflare -> k8sAPI "Watches and reconciles CRs, creates resources" "HTTPS/6443"
        codeflare -> kuberay "Watches RayCluster CRDs managed by KubeRay" "CRD Watch"
        codeflare -> kueue "Creates and manages Workload CRs for AppWrapper scheduling" "CRD Management"
        codeflare -> odh "Reads DSCInitialization for namespace configuration" "CRD Read"
        codeflare -> rayCluster "Creates and configures with security (mTLS, OAuth, NetworkPolicies)"

        # External integrations
        prometheus -> codeflare "Scrapes metrics" "HTTP/8080"
        k8sAPI -> codeflare "Calls admission webhooks" "HTTPS/9443 mTLS"
        rayCluster -> oauth "Authenticates users via OAuth proxy" "HTTPS/443"
        kuberay -> rayCluster "Manages Ray pod lifecycle"
    }

    views {
        systemContext codeflare "SystemContext" {
            include *
            autoLayout
        }

        container codeflare "CodeFlareContainers" {
            include *
            autoLayout
        }

        component manager "OperatorComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
