workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and serving applications on OpenShift"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing lifecycle of Ray clusters, jobs, and serving applications via CRDs" {
            rayClusterCtrl = container "RayCluster Controller" "Manages pod/service lifecycle for Ray clusters" "Go (controller-runtime)"
            rayJobCtrl = container "RayJob Controller" "Submits and tracks Ray jobs with retry logic" "Go (controller-runtime)"
            rayServiceCtrl = container "RayService Controller" "Zero-downtime serving upgrades via dual-cluster model" "Go (controller-runtime)"
            authCtrl = container "Authentication Controller" "OIDC proxy injection and HTTPRoute management" "Go (controller-runtime)"
            netPolCtrl = container "NetworkPolicy Controller" "Pod network isolation enforcement" "Go (controller-runtime)"
            mTLSCtrl = container "mTLS Controller" "cert-manager certificate chain management" "Go (controller-runtime)"
            webhook = container "Admission Webhooks" "Mutating and validating webhooks for RayCluster resources" "Go (controller-runtime)" "9443/TCP HTTPS"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint for operator control plane" "Go" "8080/TCP HTTP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate issuance and rotation" "External"
        platformGateway = softwareSystem "Platform Gateway" "Centralized ingress gateway (data-science-gateway) with OIDC enforcement" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "OIDC authentication proxy sidecar for Ray head pods" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via PodMonitor and alerting via PrometheusRule" "External"
        redis = softwareSystem "Redis" "External state store for Ray GCS fault tolerance" "External"
        s3 = softwareSystem "Object Storage" "Model artifact and data storage for Ray workloads" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth API" "OAuth server configuration for OIDC proxy setup" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys KubeRay via kustomize manifests" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Provides external webhooks for RayCluster resources" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload delegation via managedBy field on Ray CRs" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling support via PodGroup CR" "External"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService via kubectl" "HTTPS/443"
        user -> platformGateway "Accesses Ray Dashboard" "HTTPS/443 OIDC"

        # KubeRay to dependencies
        kuberay -> k8sAPI "CRUD on pods, services, CRDs, RBAC, secrets" "HTTPS/443"
        kuberay -> certManager "Creates Issuer and Certificate CRs for mTLS" "HTTPS/443"
        kuberay -> platformGateway "Creates HTTPRoutes for Ray dashboard access" "Gateway API"
        kuberay -> kubeRBACProxy "Injects sidecar into Ray head pods" "Container image"
        kuberay -> openshiftOAuth "Reads OAuth configuration for OIDC setup" "HTTPS/443"
        kuberay -> redis "GCS fault tolerance state storage" "TCP/6379"

        # Platform interactions
        rhodsOperator -> kuberay "Deploys via kustomize manifests" "Kustomize"
        codeflareOperator -> kuberay "External webhooks on RayCluster" "Admission Webhook"
        kueue -> kuberay "Workload delegation" "managedBy field"
        kuberay -> volcano "Gang scheduling via PodGroup CR" "K8s API"

        # Observability
        prometheus -> kuberay "Scrapes operator and Ray metrics" "HTTP/8080 PodMonitor"
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
