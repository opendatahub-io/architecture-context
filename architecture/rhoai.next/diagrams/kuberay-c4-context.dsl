workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and serving deployments for distributed ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of RayCluster, RayJob, and RayService CRDs and their associated Kubernetes infrastructure for distributed Ray computing" {
            rayClusterCtrl = container "RayCluster Controller" "Manages Ray cluster pod lifecycle, services, ingress, and autoscaler RBAC" "Go (controller-runtime)"
            rayJobCtrl = container "RayJob Controller" "Manages Ray job submission, lifecycle, and deletion policies" "Go (controller-runtime)"
            rayServiceCtrl = container "RayService Controller" "Manages zero-downtime Ray Serve upgrades with active/pending cluster pattern" "Go (controller-runtime)"
            authCtrl = container "Authentication Controller" "Creates Gateway API HTTPRoutes and injects kube-rbac-proxy sidecars for authenticated dashboard access" "Go (controller-runtime)"
            mtlsCtrl = container "mTLS Controller" "Manages cert-manager Issuer and Certificate resources for inter-pod mTLS" "Go (controller-runtime)"
            netpolCtrl = container "NetworkPolicy Controller" "Creates annotation-driven NetworkPolicies for defense-in-depth network isolation" "Go (controller-runtime)"
            webhook = container "Webhook Server" "Validates and mutates RayCluster resources via admission webhooks" "Go (9443/TCP TLS)"
            metrics = container "Metrics Server" "Exposes Prometheus metrics for Ray clusters, jobs, and services" "Go (8080/TCP)"
        }

        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform operator and components" "Internal RHOAI" {
            rhodsOperator = container "rhods-operator" "Deploys KubeRay operator via kustomize manifests" "Go Operator"
            dsgw = container "data-science-gateway" "Platform Gateway resource for external traffic routing to Ray dashboards" "Gateway API"
        }

        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and ReferenceGrant for authenticated ingress" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, auth reviews" "External"
        redis = softwareSystem "Redis" "External state store for GCS fault tolerance" "External"
        volcano = softwareSystem "Volcano" "Gang scheduling for batch workloads" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization proxy sidecar for Ray head pods" "Internal RHOAI"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService via kubectl" "HTTPS/443"
        user -> dsgw "Accesses Ray Dashboard" "HTTPS/443 OIDC"

        # Internal flows
        rayClusterCtrl -> k8sAPI "Manages Pods, Services, Ingress, RBAC" "HTTPS/443"
        rayJobCtrl -> k8sAPI "Creates submitter Jobs, watches status" "HTTPS/443"
        rayServiceCtrl -> k8sAPI "Manages active/pending clusters, updates Service selectors" "HTTPS/443"
        authCtrl -> k8sAPI "Creates HTTPRoutes, ReferenceGrants, injects sidecars" "HTTPS/443"
        mtlsCtrl -> certManager "Creates Issuer and Certificate CRDs" "CRD API"
        netpolCtrl -> k8sAPI "Creates/manages NetworkPolicy resources" "HTTPS/443"

        # Platform integration
        rhodsOperator -> kuberay "Deploys operator via kustomize" "Kustomize"
        dsgw -> kubeRBACProxy "Routes dashboard traffic" "HTTPS/8443"
        kubeRBACProxy -> k8sAPI "TokenReview and SubjectAccessReview" "HTTPS/443"

        # External dependencies
        kuberay -> redis "GCS fault tolerance storage" "TCP/6379"
        kuberay -> volcano "Gang scheduling integration" "Pod annotations"
        kuberay -> certManager "Certificate provisioning" "CRD Create/Watch"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
