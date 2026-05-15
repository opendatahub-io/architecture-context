workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for distributed computing"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on Kubernetes/OpenShift" {
            rcController = container "RayCluster Controller" "Manages RayCluster CR lifecycle: creates head/worker pods, services, autoscaling" "Go (controller-runtime)"
            rjController = container "RayJob Controller" "Manages RayJob CR lifecycle: creates clusters, submits jobs, tracks completion" "Go (controller-runtime)"
            rsController = container "RayService Controller" "Manages RayService CR lifecycle: zero-downtime serve app upgrades" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Creates HTTPRoutes, ReferenceGrants, kube-rbac-proxy configs for OIDC auth" "Go (controller-runtime)"
            mtlsController = container "mTLS Controller" "Creates cert-manager Issuers and Certificates for inter-node mTLS" "Go (controller-runtime)"
            npController = container "NetworkPolicy Controller" "Creates NetworkPolicies for pod-level network isolation" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating/validating admission webhooks for RayCluster enforcement" "Go (controller-runtime)" "9443/TCP HTTPS"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics for cluster/job/service operations" "Go" "8080/TCP HTTP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate lifecycle management" "External"
        gateway = softwareSystem "Platform Gateway" "data-science-gateway (Envoy) for centralized ingress with TLS termination" "Internal RHOAI"
        openShiftOAuth = softwareSystem "OpenShift OAuth/OIDC" "Identity provider for user authentication" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        redis = softwareSystem "Redis" "Optional external GCS fault tolerance storage for Ray state" "External"
        volcano = softwareSystem "Volcano Scheduler" "Batch scheduling with gang scheduling support" "External"
        yunikorn = softwareSystem "YuniKorn Scheduler" "Apache YuniKorn for gang scheduling via annotations" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Kubernetes scheduler plugins for gang scheduling" "External"
        kueue = softwareSystem "Kueue" "Multi-cluster workload management via managedBy field" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys and configures KubeRay" "Internal RHOAI"

        # Relationships
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl" "HTTPS/443"
        user -> gateway "Accesses Ray Dashboard via browser" "HTTPS/443, OIDC"

        kuberay -> k8sAPI "CRUD for pods, services, RBAC, CRDs, secrets" "HTTPS/443, SA Token"
        kuberay -> certManager "Creates Issuers and Certificates for mTLS" "HTTPS/443, SA Token"
        kuberay -> openShiftOAuth "Reads auth/OAuth config for auth mode detection" "HTTPS/443, SA Token"
        kuberay -> gateway "Creates HTTPRoutes for dashboard access" "HTTPS/443, SA Token"
        kuberay -> redis "Optional: GCS fault tolerance storage" "TCP/6379, Optional TLS"
        kuberay -> volcano "Creates PodGroups for gang scheduling" "HTTPS/443, SA Token"
        kuberay -> schedulerPlugins "Creates PodGroups for gang scheduling" "HTTPS/443, SA Token"

        gateway -> kuberay "Proxies dashboard requests via kube-rbac-proxy" "HTTPS/8443, OIDC"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        rhodsOperator -> kuberay "Deploys via kustomize openshift overlay" "Deployment"

        # Container relationships
        rcController -> k8sAPI "Creates pods, services" "HTTPS/443"
        rjController -> rcController "Creates RayCluster for job" ""
        rsController -> rcController "Manages RayCluster for service" ""
        authController -> k8sAPI "Creates HTTPRoute, ReferenceGrant" "HTTPS/443"
        mtlsController -> certManager "Creates Issuer, Certificate" "HTTPS/443"
        npController -> k8sAPI "Creates NetworkPolicy" "HTTPS/443"
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
