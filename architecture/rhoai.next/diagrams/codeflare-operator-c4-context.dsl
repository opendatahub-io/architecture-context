workspace {
    model {
        dataScientist = person "Data Scientist" "Creates RayClusters and AppWrappers for distributed AI workloads"
        platformAdmin = person "Platform Admin" "Configures operator settings and manages the RHOAI platform"

        codeflareOperator = softwareSystem "codeflare-operator" "Kubernetes operator managing RayCluster lifecycle with OAuth, mTLS, networking, and optional AppWrapper batch scheduling" {
            manager = container "codeflare-operator-manager" "Single-replica controller-runtime manager hosting all controllers and webhooks" "Go Operator" "Deployment"
            rayClusterController = container "RayClusterReconciler" "Watches RayCluster CRs; creates OAuth proxies, Routes, mTLS certs, NetworkPolicies, ClusterRoleBindings" "Go Controller"
            appWrapperController = container "AppWrapper Controller" "Optional Kueue-integrated controller for batch workload grouping; embedded from project-codeflare/appwrapper library" "Go Controller (embedded)"
            webhookServer = container "Admission Webhooks" "Mutating/validating webhooks for RayCluster (sidecar injection, immutability) and AppWrapper" "Webhook Server" "9443/TCP"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle (job execution, pod management)" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queuing and fair-share scheduling" "Internal RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator managing RHOAI component lifecycle" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing RHOAI resources" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Platform OAuth for user authentication" "OpenShift Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Ingress routing with TLS termination" "OpenShift Platform"
        certController = softwareSystem "cert-controller" "OPA cert-rotator for webhook certificate management" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "Platform"

        # User interactions
        dataScientist -> codeflareOperator "Creates RayCluster/AppWrapper via kubectl" "HTTPS/6443"
        platformAdmin -> codeflareOperator "Configures via ConfigMap codeflare-operator-config"

        # Internal component interactions
        manager -> rayClusterController "Manages lifecycle"
        manager -> appWrapperController "Manages lifecycle (when enabled)"
        manager -> webhookServer "Hosts webhook endpoints"

        # External integrations
        codeflareOperator -> k8sAPI "All controller CRUD operations" "HTTPS/6443 TLS 1.2+ SA Token"
        codeflareOperator -> openshiftRoutes "Creates OAuth and RayClient Routes" "HTTPS/6443"
        codeflareOperator -> openshiftOAuth "Dashboard auth via oauth-proxy sidecar" "OAuth delegation"
        codeflareOperator -> kuberay "Discovers namespace for NetworkPolicy config" "Pod discovery"
        codeflareOperator -> kueue "AppWrapper workload queuing integration" "CRD integration"
        codeflareOperator -> odhOperator "Reads DSCInitialization for namespace discovery" "CRD watch"
        certController -> codeflareOperator "Rotates webhook TLS certificates" "Secret injection"

        # Consumers
        dashboard -> codeflareOperator "UI management of RayClusters" "HTTPS"
        pipelines -> codeflareOperator "Submits workloads via AppWrappers" "HTTPS"
    }

    views {
        systemContext codeflareOperator "SystemContext" {
            include *
            autoLayout
        }

        container codeflareOperator "Containers" {
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
            element "OpenShift Platform" {
                background #ee0000
                color #ffffff
            }
            element "Platform" {
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
