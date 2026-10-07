workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters, jobs, and serving endpoints"
        clusterAdmin = person "Cluster Admin" "Manages OpenShift cluster and TLS security profiles"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing Ray cluster lifecycle, jobs, and serving via CRDs" {
            manager = container "ray-operator (manager)" "Core operator binary running all controllers, webhooks, and metrics server" "Go 1.25 / controller-runtime v0.22.4"
            rayClusterController = container "RayCluster Reconciler" "Manages Ray cluster lifecycle: head/worker pods, services, ingress" "Controller"
            rayJobController = container "RayJob Reconciler" "Creates RayClusters and submits Ray jobs" "Controller"
            rayServiceController = container "RayService Reconciler" "Manages Ray Serve deployments with blue-green upgrades" "Controller"
            rayCronJobController = container "RayCronJob Reconciler" "Schedules periodic RayJob creation (alpha)" "Controller"
            authController = container "Authentication Controller" "Injects kube-rbac-proxy sidecars and manages Routes/HTTPRoutes" "Controller (downstream)"
            netpolController = container "NetworkPolicy Controller" "Creates per-RayCluster NetworkPolicies" "Controller (downstream)"
            mtlsController = container "mTLS Controller" "Provisions cert-manager Certificate and Issuer resources" "Controller (downstream)"
            tlsWatcher = container "TLS Profile Watcher" "Watches OpenShift APIServer TLS profile changes" "Controller (downstream)"
            webhooks = container "Admission Webhooks" "Mutating and validating webhooks for Ray CRDs" "HTTPS/9443"
        }

        kubeApiServer = softwareSystem "Kubernetes API Server" "Central API for all cluster resource operations" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for Kubernetes" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute management" "Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External route management for OpenShift" "Platform"
        openshiftConfig = softwareSystem "OpenShift APIServer Config" "Cluster-wide TLS security profile configuration" "Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "OIDC authentication proxy sidecar for Ray dashboards" "Platform"
        batchSchedulers = softwareSystem "Batch Schedulers" "Volcano, YuniKorn, Kai for gang scheduling" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Red Hat OpenShift AI operator managing component lifecycle" "Internal"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed computing orchestration" "Internal"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl" "HTTPS/6443"
        user -> kubeRbacProxy "Accesses Ray dashboard" "HTTPS/443"
        clusterAdmin -> openshiftConfig "Configures cluster TLS security profile"

        # Operator interactions
        kuberay -> kubeApiServer "All resource CRUD operations" "HTTPS/6443, TLS 1.2+, SA token"
        kuberay -> certManager "Provisions mTLS and webhook certificates" "Certificate/Issuer CRDs"
        kuberay -> gatewayAPI "Creates per-cluster HTTPRoutes" "HTTPRoute CRDs"
        kuberay -> openshiftRoutes "Creates dashboard routes" "Route CRDs"
        kuberay -> openshiftConfig "Reads TLS security profile" "HTTPS/6443"
        kuberay -> batchSchedulers "Gang scheduling via PodGroups" "PodGroup CRDs"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        kubeApiServer -> kuberay "Sends admission reviews" "HTTPS/9443"

        # Platform integration
        rhoaiOperator -> kuberay "Deploys via kustomize overlays"
        codeflare -> kuberay "Creates RayCluster resources"

        # Internal container relationships
        manager -> rayClusterController "runs"
        manager -> rayJobController "runs"
        manager -> rayServiceController "runs"
        manager -> rayCronJobController "runs"
        manager -> authController "runs"
        manager -> netpolController "runs"
        manager -> mtlsController "runs"
        manager -> tlsWatcher "runs"
        manager -> webhooks "runs"
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
            element "Platform" {
                background #438dd5
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
