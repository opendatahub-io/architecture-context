workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed Ray workloads for AI/ML training and inference"
        platformAdmin = person "Platform Admin" "Configures CodeFlare operator and manages cluster resources"

        codeflare = softwareSystem "CodeFlare Operator" "Kubernetes operator for lifecycle management of CodeFlare distributed workload stack, providing Ray cluster orchestration and batch job scheduling" {
            operatorManager = container "Operator Manager" "Manages RayCluster and AppWrapper reconciliation" "Go Deployment" {
                rayController = component "RayCluster Controller" "Watches RayCluster CRs and adds OAuth, mTLS, network policies" "Go Reconciler"
                appController = component "AppWrapper Controller" "Manages AppWrapper CRs for batch workload scheduling" "Go Reconciler"
                rayWebhook = component "RayCluster Webhook" "Injects OAuth sidecar, mTLS init containers into RayCluster pods" "Go MutatingWebhook"
                appWebhook = component "AppWrapper Webhook" "Validates and mutates AppWrapper resources for Kueue integration" "Go MutatingWebhook"
                certRotator = component "Certificate Rotator" "Manages webhook TLS certificates" "Go Controller"
            }
            metricsExporter = container "Metrics Exporter" "Exposes Prometheus metrics on operator performance" "HTTP Server :8080"
            webhookServer = container "Webhook Server" "Validates and mutates RayCluster and AppWrapper CRs" "HTTPS Server :9443"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle (pods, services)" "External" {
            tags "External"
        }

        kueue = softwareSystem "Kueue" "Job queueing and quota management for AppWrappers" "External" {
            tags "External" "Optional"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes control plane API" "HTTPS :6443"
            tags "External"
        }

        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with additional features" "External" {
            oauth = container "OAuth Server" "Authenticates users accessing Ray dashboards" "HTTPS :443"
            router = container "Router" "Exposes Ray clusters via external routes" "HTTPS :443"
            monitoring = container "Monitoring" "Prometheus-based cluster monitoring" "HTTP :8080"
            tags "External" "Optional"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for Open Data Hub platform" "Internal ODH" {
            tags "Internal ODH"
        }

        certController = softwareSystem "cert-controller" "Automatic webhook certificate generation and rotation" "External" {
            tags "External"
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed compute cluster for AI/ML workloads" "Managed Resource" {
            headPod = container "Ray Head Pod" "Ray cluster head node with dashboard and client endpoint" "Python :8265, :10001"
            workerPods = container "Ray Worker Pods" "Ray cluster worker nodes" "Python"
            oauthProxy = container "OAuth Proxy Sidecar" "Authenticates users via OpenShift OAuth" "Go :8443"
            tags "Managed Resource"
        }

        # User interactions
        dataScientist -> odhDashboard "Creates RayCluster and AppWrapper via web UI"
        dataScientist -> kubernetes "Creates RayCluster/AppWrapper CRs via kubectl"
        dataScientist -> rayCluster "Accesses Ray dashboard and submits jobs" "HTTPS :443"
        platformAdmin -> codeflare "Configures operator settings" "ConfigMap"

        # CodeFlare core interactions
        codeflare -> kubernetes "Watches CRDs (RayCluster, AppWrapper, Workload), creates resources (NetworkPolicy, Route, Secret)" "HTTPS/6443"
        kubernetes -> codeflare "Calls webhooks for validation/mutation" "HTTPS/9443 mTLS"

        # Ray cluster management
        operatorManager -> rayController "Reconciles RayCluster resources"
        operatorManager -> appController "Reconciles AppWrapper resources"
        rayController -> kubernetes "Creates OAuth resources, NetworkPolicies, Routes, mTLS secrets"
        rayWebhook -> rayCluster "Injects OAuth proxy sidecar and mTLS init containers"

        # External dependencies
        codeflare -> kuberay "Extends RayCluster CRD with security features (OAuth, mTLS, NetworkPolicy)" "Kubernetes API"
        codeflare -> kueue "Submits AppWrapper workloads for quota-based scheduling" "Kubernetes API/Workload CRD"
        codeflare -> certController "Uses for webhook certificate rotation" "Secret mount"
        codeflare -> openshift "Creates Routes, uses OAuth for authentication, sends metrics" "Kubernetes API"

        # ODH integration
        odhDashboard -> kubernetes "Creates RayCluster CRs on behalf of users" "HTTPS/6443"

        # Ray cluster operations
        kuberay -> rayCluster "Creates and manages Ray pods and services" "Kubernetes API"
        rayCluster -> openshift "Authenticates users, exposes dashboard" "HTTPS/443 OAuth, Route"

        # Monitoring
        openshift -> codeflare "Scrapes operator metrics" "HTTP/8080"
        openshift -> rayCluster "Scrapes Ray cluster metrics" "HTTP/8080"

        # User access flow
        dataScientist -> openshift "Accesses Ray dashboard via browser" "HTTPS/443"
        openshift -> rayCluster "Forwards authenticated requests" "HTTPS/8443"
        oauthProxy -> openshift "Validates OAuth tokens" "HTTPS/443"
        oauthProxy -> headPod "Proxies to Ray dashboard" "HTTP/8265 localhost"
    }

    views {
        systemContext codeflare "SystemContext" {
            include *
            autoLayout lr
        }

        container codeflare "CodeFlareContainers" {
            include *
            autoLayout lr
        }

        container rayCluster "RayClusterContainers" {
            include *
            autoLayout lr
        }

        component operatorManager "OperatorComponents" {
            include *
            autoLayout lr
        }

        dynamic codeflare "RayClusterCreation" "RayCluster creation and security setup flow" {
            dataScientist -> kubernetes "Creates RayCluster CR"
            kubernetes -> webhookServer "Mutate webhook call (inject OAuth/mTLS)"
            webhookServer -> kubernetes "Returns mutated RayCluster"
            kubernetes -> operatorManager "Watch event (new RayCluster)"
            rayController -> kubernetes "Create NetworkPolicy"
            rayController -> kubernetes "Create Route/Ingress"
            rayController -> kubernetes "Create OAuth ServiceAccount"
            rayController -> kubernetes "Create ClusterRoleBinding"
            rayController -> kubernetes "Create mTLS CA Secret"
            kuberay -> kubernetes "Create Ray Head Pod"
            kuberay -> kubernetes "Create Ray Worker Pods"
            autoLayout lr
        }

        dynamic codeflare "AppWrapperScheduling" "AppWrapper admission and workload scheduling flow" {
            dataScientist -> kubernetes "Creates AppWrapper CR"
            kubernetes -> webhookServer "Mutate/validate webhook"
            webhookServer -> kubernetes "Returns validated AppWrapper"
            kubernetes -> operatorManager "Watch event (new AppWrapper)"
            appController -> kubernetes "Create Kueue Workload CR"
            kueue -> kubernetes "Watch Workload, check quota"
            kueue -> kubernetes "Update Workload status (Admitted)"
            appController -> kubernetes "Deploy wrapped resources (RayCluster/Job)"
            autoLayout lr
        }

        dynamic rayCluster "UserAccess" "User accesses Ray dashboard flow" {
            dataScientist -> router "GET /dashboard (HTTPS)"
            router -> oauthProxy "Forward via Route (HTTPS/8443)"
            oauthProxy -> oauth "Validate/obtain OAuth token"
            oauth -> oauthProxy "Return token"
            oauthProxy -> headPod "Proxy to dashboard (HTTP/8265)"
            headPod -> oauthProxy "Dashboard HTML"
            oauthProxy -> router "HTTPS response"
            router -> dataScientist "Dashboard page"
            autoLayout lr
        }

        styles {
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                opacity 70
            }
            element "Managed Resource" {
                background #f5a623
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
