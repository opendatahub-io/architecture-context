workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed Ray clusters for ML training, batch inference, and serving"
        admin = person "Platform Administrator" "Deploys and configures KubeRay operator on OpenShift"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator that manages the lifecycle of Ray clusters, jobs, and services for distributed computing and ML workloads" {
            operator = container "KubeRay Operator" "Manages RayCluster, RayJob, RayService lifecycle" "Go Operator" {
                rayClusterCtrl = component "RayCluster Controller" "Manages Ray cluster lifecycle (head + worker pods)" "Go Controller"
                rayJobCtrl = component "RayJob Controller" "Creates RayCluster and submits jobs" "Go Controller"
                rayServiceCtrl = component "RayService Controller" "Manages RayCluster with Ray Serve for zero-downtime upgrades" "Go Controller"
                authCtrl = component "Authentication Controller" "Manages OAuth/OIDC authentication on OpenShift" "Go Controller"
                networkPolicyCtrl = component "NetworkPolicy Controller" "Creates NetworkPolicies for secure communication" "Go Controller"
                mtlsCtrl = component "mTLS Controller" "Manages cert-manager Certificates for Ray mTLS" "Go Controller"
            }

            webhook = container "Webhook Server" "Validates and mutates RayCluster CRs" "Go Admission Webhook"

            rayCluster = container "Ray Cluster" "Distributed computing cluster for ML workloads" "Python/Ray" {
                headPod = component "Ray Head Pod" "Runs GCS, dashboard, and client API" "Ray Head Node"
                workerPods = component "Ray Worker Pods" "Execute distributed tasks" "Ray Worker Nodes"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Manages cluster resources and CRDs" "External"
        openshift = softwareSystem "OpenShift Platform" "Enterprise Kubernetes distribution" "External" {
            oauthServer = container "OAuth Server" "Provides authentication for Ray dashboard" "OAuth/OIDC Provider"
            routeAPI = container "Route API" "Exposes Ray dashboard externally" "OpenShift Ingress"
            serviceCA = container "Service CA" "Issues certificates for OAuth proxy" "Certificate Authority"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks and mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Advanced ingress routing for Ray clusters" "External (Optional)"
        externalRedis = softwareSystem "External Redis" "Ray GCS fault tolerance external storage" "External (Optional)"
        registry = softwareSystem "Container Registry" "Stores Ray container images" "External (quay.io, registry.redhat.io)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External (Optional)"

        kueue = softwareSystem "Kueue" "Batch job queuing and resource quotas" "Internal ODH (Optional)"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and configures KubeRay operator" "Internal ODH"

        # User relationships
        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl/oc"
        user -> rayCluster "Accesses Ray dashboard via browser"
        admin -> rhoaiOperator "Configures KubeRay component"

        # Operator relationships
        operator -> kubernetes "Watches CRDs, creates/updates/deletes resources (Pods, Services, Routes, NetworkPolicies, etc.)" "HTTPS/6443"
        webhook -> kubernetes "Validates and mutates RayCluster CRs" "HTTPS/9443"

        rayClusterCtrl -> headPod "Creates and manages Ray head pod"
        rayClusterCtrl -> workerPods "Creates and manages Ray worker pods"
        rayJobCtrl -> headPod "Submits jobs via dashboard API" "HTTP/8265"
        authCtrl -> oauthServer "Validates OAuth tokens" "HTTPS/443"
        authCtrl -> routeAPI "Creates Routes for dashboard access"
        mtlsCtrl -> certManager "Creates Certificates and Issuers" "HTTPS/6443"
        networkPolicyCtrl -> kubernetes "Creates NetworkPolicies for Ray cluster isolation"

        # Ray cluster relationships
        workerPods -> headPod "Connects to GCS, executes distributed tasks" "TCP/6379"
        headPod -> externalRedis "GCS fault tolerance external storage (optional)" "TCP/6379"
        headPod -> registry "Pulls Ray container images" "HTTPS/443"

        # External integrations
        kuberay -> certManager "Uses for webhook TLS and Ray pod mTLS" "via Kubernetes API"
        kuberay -> openshift "Uses OAuth, Routes, Service CA for authentication and external access"
        kuberay -> gatewayAPI "Uses HTTPRoutes for advanced ingress routing (optional)"
        kuberay -> kueue "Integrates for batch job queuing (optional)"

        rhoaiOperator -> kuberay "Deploys and configures KubeRay operator" "via Kubernetes API"
        prometheus -> operator "Scrapes metrics from /metrics endpoint" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray cluster metrics"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout lr
        }

        container kuberay "KubeRayContainers" {
            include *
            autoLayout lr
        }

        component operator "OperatorComponents" {
            include *
            autoLayout lr
        }

        component rayCluster "RayClusterComponents" {
            include *
            autoLayout lr
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
            element "External (Optional)" {
                background #cccccc
                color #000000
            }
            element "Internal ODH (Optional)" {
                background #aae87f
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6ca6e2
                color #ffffff
            }
            element "Component" {
                background #8ec0f2
                color #000000
            }
        }

        theme default
    }
}
