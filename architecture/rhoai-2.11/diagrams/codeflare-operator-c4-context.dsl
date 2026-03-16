workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates distributed AI/ML workloads using Ray clusters"
        admin = person "Platform Administrator" "Configures CodeFlare operator and manages Ray infrastructure"

        codeflare = softwareSystem "CodeFlare Operator" "Kubernetes operator for installation and lifecycle management of CodeFlare distributed workload stack with enhanced security" {
            manager = container "Operator Manager" "Main operator process managing RayCluster and AppWrapper resources" "Go Binary" {
                rayController = component "RayCluster Controller" "Reconciles RayCluster resources, adds OAuth proxy, mTLS, network policies" "Go Controller"
                appWrapperController = component "AppWrapper Controller" "Manages AppWrapper CRDs for workload queueing and gang scheduling" "Go Controller"
                rayWebhook = component "RayCluster Webhook" "Mutates RayCluster resources to inject OAuth proxy and TLS config" "Go Webhook"
                appWrapperWebhook = component "AppWrapper Webhook" "Validates and mutates AppWrapper resources for Kueue integration" "Go Webhook"
                certRotator = component "Certificate Rotator" "Manages webhook TLS certificates and Ray cluster CA certificates" "Go Component"
            }
            webhookServer = container "Webhook Server" "Validates and mutates RayCluster and AppWrapper resources" "Go HTTPS Service"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server"
            healthProbe = container "Health Probe Server" "Provides liveness and readiness endpoints" "HTTP Server"
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base Ray cluster management" "External Operator"
        kueue = softwareSystem "Kueue" "Workload queueing and resource quota management system" "External Operator"
        certManager = softwareSystem "cert-controller" "TLS certificate rotation for webhooks" "External"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with OAuth and Routes" "Platform (Optional)"

        odhOperator = softwareSystem "ODH Operator" "Manages ODH/RHOAI platform components" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "Internal RHOAI"

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing framework for AI/ML workloads" "Managed Workload" {
            rayHead = container "Ray Head Node" "Ray cluster coordinator with dashboard" "Python"
            rayWorkers = container "Ray Worker Nodes" "Distributed compute nodes" "Python"
            oauthProxy = container "OAuth Proxy" "Secures Ray Dashboard with OAuth authentication" "Go Sidecar"
        }

        # User interactions
        user -> codeflare "Creates RayCluster and AppWrapper resources via kubectl/SDK"
        user -> rayCluster "Accesses Ray Dashboard for monitoring"
        admin -> codeflare "Configures operator settings and RBAC"

        # CodeFlare internal
        manager -> webhookServer "Hosts webhook endpoints"
        manager -> metricsServer "Exposes metrics"
        manager -> healthProbe "Provides health checks"

        # CodeFlare → Kubernetes
        codeflare -> k8s "Watches RayCluster, AppWrapper CRDs and reconciles resources" "HTTPS/6443 TLS 1.2+ Bearer Token"
        k8s -> webhookServer "Calls mutating/validating webhooks" "HTTPS/9443 TLS 1.2+ mTLS"

        # CodeFlare → External dependencies
        codeflare -> kuberay "Requires RayCluster CRD availability" "CRD discovery"
        codeflare -> kueue "Creates and manages Kueue Workloads for AppWrappers" "HTTPS/6443 via K8s API"
        certManager -> codeflare "Rotates webhook TLS certificates" "Certificate injection"

        # CodeFlare → OpenShift (optional)
        codeflare -> openshift "Injects OAuth proxy for Ray Dashboard, creates Routes" "HTTPS/6443"
        openshift -> rayCluster "Provides OAuth authentication and TLS certificates" "OAuth flow + service-ca"

        # CodeFlare → RHOAI internal
        codeflare -> odhOperator "Monitors DSCInitialization for platform configuration" "CRD watch"
        prometheus -> codeflare "Scrapes metrics endpoint" "HTTP/8080"

        # CodeFlare → Ray Cluster
        codeflare -> rayCluster "Creates Ray clusters with security enhancements (OAuth, mTLS, NetworkPolicies)" "Kubernetes resources"
        rayCluster -> k8s "Ray pods communicate via Kubernetes services"

        # Ray internal
        rayHead -> rayWorkers "Distributes tasks and manages cluster" "gRPC with mTLS"
        oauthProxy -> rayHead "Forwards authenticated requests to Ray Dashboard" "HTTPS/8265 mTLS"
    }

    views {
        systemContext codeflare "SystemContext" {
            include *
            autoLayout
        }

        container codeflare "Containers" {
            include *
            autoLayout
        }

        component manager "Components" {
            include *
            autoLayout
        }

        dynamic codeflare "RayClusterCreation" "RayCluster creation with security enhancement" {
            user -> k8s "Creates RayCluster"
            k8s -> webhookServer "Mutating webhook call"
            webhookServer -> rayController "Injects OAuth proxy + mTLS config"
            rayController -> k8s "Creates OAuth service, secrets, routes, NetworkPolicies"
            rayController -> rayCluster "Deploys secure Ray cluster"
            autoLayout
        }

        dynamic codeflare "AppWrapperAdmission" "AppWrapper workload admission via Kueue" {
            user -> k8s "Creates AppWrapper"
            k8s -> webhookServer "Validating webhook call"
            appWrapperController -> kueue "Creates Kueue Workload"
            kueue -> appWrapperController "Admits workload (when resources available)"
            appWrapperController -> k8s "Deploys wrapped resources atomically"
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Operator" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #666666
                color #ffffff
            }
            element "Platform (Optional)" {
                background #888888
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Managed Workload" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }

        theme default
    }
}
