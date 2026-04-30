workspace {
    model {
        user = person "Data Scientist" "Creates and deploys distributed Ray computing workloads on RHOAI"

        kuberay = softwareSystem "KubeRay Operator" "Manages the lifecycle of RayCluster, RayJob, and RayService custom resources and their associated Kubernetes infrastructure" {
            rayClusterController = container "RayCluster Controller" "Manages Ray cluster pod lifecycle, services, ingress, and RBAC" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Manages Ray job submission, lifecycle, and deletion policies" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Manages Ray Serve deployments with zero-downtime upgrades" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Creates Gateway API HTTPRoutes and injects kube-rbac-proxy sidecars" "Go (controller-runtime)"
            mtlsController = container "mTLS Controller" "Manages cert-manager certificates for inter-node TLS" "Go (controller-runtime)"
            networkPolicyController = container "NetworkPolicy Controller" "Creates annotation-driven network isolation policies" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates RayCluster custom resources" "Go (admission webhook)" "9443/TCP HTTPS"
        }

        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform operator" "Internal RHOAI" {
            rhodsOperator = container "RHODS Operator" "Deploys KubeRay via kustomize manifests" "Go Operator"
            dsgw = container "data-science-gateway" "Platform Gateway for external traffic routing" "Gateway API"
        }

        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and ReferenceGrant for authenticated dashboard access" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar proxy (OIDC + SubjectAccessReview)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        redis = softwareSystem "Redis" "External state store for GCS fault tolerance" "External"
        volcano = softwareSystem "Volcano / YuniKorn" "Batch scheduling for gang scheduling support" "External"

        // User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl/dashboard"
        user -> rhoaiPlatform "Accesses Ray dashboards via Gateway" "HTTPS/443"

        // Platform interactions
        rhoaiPlatform -> kuberay "Deploys operator via kustomize manifests"

        // KubeRay dependencies
        kuberay -> kubernetesAPI "Watches CRDs, CRUD pods/services/jobs/RBAC" "HTTPS/443"
        kuberay -> certManager "Creates Issuer and Certificate resources for mTLS" "CRD Create/Watch"
        kuberay -> gatewayAPI "Creates HTTPRoutes for dashboard access" "CRD Create"
        kuberay -> kubeRBACProxy "Injects as sidecar for authenticated dashboard access" "HTTPS/8443"
        kuberay -> redis "GCS fault tolerance external storage (optional)" "TCP/6379"
        kuberay -> volcano "Gang scheduling integration (optional)" "Pod annotations"

        // Internal interactions
        rayClusterController -> webhookServer "Validates RayCluster CRs"
        rayJobController -> rayClusterController "Creates RayCluster for job execution"
        rayServiceController -> rayClusterController "Manages active/pending RayCluster pairs"
        authController -> rayClusterController "Adds kube-rbac-proxy sidecar to head pods"
        mtlsController -> rayClusterController "Mounts TLS secrets into head/worker pods"
        networkPolicyController -> rayClusterController "Creates NetworkPolicy for cluster pods"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "Containers" {
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
