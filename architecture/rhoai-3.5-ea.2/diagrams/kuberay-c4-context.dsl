workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Ray clusters, jobs, and serve applications on OpenShift"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on Kubernetes/OpenShift with defense-in-depth security" {
            rcController = container "RayCluster Controller" "Reconciles RayCluster CRs, creates head/worker pods, services, autoscaler RBAC" "Go (controller-runtime)"
            rjController = container "RayJob Controller" "Manages RayCluster lifecycle for jobs, submits jobs via Dashboard API or K8s Job" "Go (controller-runtime)"
            rsController = container "RayService Controller" "Manages active/pending clusters for zero-downtime serve upgrades" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Creates HTTPRoute, ReferenceGrant, kube-rbac-proxy sidecar for OIDC auth" "Go (controller-runtime)" "RHOAI Security"
            mtlsController = container "mTLS Controller" "Provisions cert-manager Issuer and Certificate for inter-pod mTLS encryption" "Go (controller-runtime)" "RHOAI Security"
            npController = container "NetworkPolicy Controller" "Creates restrictive NetworkPolicies for head and worker pods" "Go (controller-runtime)" "RHOAI Security"
            mutatingWebhook = container "Mutating Webhook" "Enforces secure-trusted-network annotation, disables Ingress on OpenShift" "Go Admission Webhook" "RHOAI Security"
            validatingWebhook = container "Validating Webhook" "Validates cluster name format and worker group uniqueness" "Go Admission Webhook"
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster with head and worker pods" {
            headPod = container "Ray Head Pod" "GCS server (6379), Dashboard (8265), Client (10001), Serve (8000)" "Ray"
            workerPods = container "Ray Worker Pods" "Distributed task execution" "Ray"
            kubeRbacProxy = container "kube-rbac-proxy" "OIDC auth sidecar (8443/TCP), TokenReview + SubjectAccessReview" "ose-kube-rbac-proxy-rhel9" "Security Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform (6443/TCP HTTPS)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management (Issuer, Certificate CRs)" "External"
        gatewayAPI = softwareSystem "data-science-gateway" "Gateway API ingress (443/TCP HTTPS, TLS terminated)" "Internal Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Cluster authentication/authorization config (config.openshift.io)" "External"
        redis = softwareSystem "External Redis" "GCS fault tolerance storage (6379/TCP)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection (8080/TCP HTTP)" "External"
        volcano = softwareSystem "Volcano / YuniKorn" "Batch gang scheduling for distributed workloads" "External"
        platformOperator = softwareSystem "RHODS / ODH Operator" "Platform operator that deploys and configures KubeRay" "Internal Platform"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata storage" "Internal Platform"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal Platform"

        # External relationships
        user -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl/API"
        user -> gatewayAPI "Accesses Ray Dashboard via OIDC auth (HTTPS/443)"
        platformOperator -> kuberay "Deploys and configures KubeRay operator"

        # KubeRay → external systems
        kuberay -> kubernetes "Manages pods, services, RBAC, CRDs (HTTPS/6443)"
        kuberay -> certManager "Creates Issuer + Certificate for mTLS and webhook TLS"
        kuberay -> openshiftOAuth "Reads auth config for OIDC provider detection (HTTPS/6443)"
        kuberay -> rayCluster "Creates and manages head/worker pods and services"

        # Gateway flow
        gatewayAPI -> kubeRbacProxy "Routes via HTTPRoute to auth sidecar (HTTPS/8443)"
        kubeRbacProxy -> headPod "Forwards authenticated requests to Dashboard (HTTP/8265)"
        kubeRbacProxy -> kubernetes "TokenReview + SubjectAccessReview (HTTPS/6443)"

        # Ray cluster internals
        headPod -> workerPods "Distributes tasks (TCP, mTLS when enabled)"
        headPod -> redis "GCS fault tolerance (TCP/6379)"

        # Internal component relationships
        rcController -> headPod "Creates and manages head pod"
        rcController -> workerPods "Creates and manages worker pods"
        rjController -> headPod "Submits jobs via Dashboard API (HTTP/8265)"
        rsController -> headPod "Deploys serve config via Dashboard API (HTTP/8265)"
        authController -> gatewayAPI "Creates HTTPRoute + ReferenceGrant"
        mtlsController -> certManager "Creates Issuer + Certificate CRs"
        npController -> kubernetes "Creates NetworkPolicy resources"

        # Monitoring
        prometheus -> kuberay "Scrapes operator metrics (HTTP/8080)"

        # Integration points
        dsPipelines -> kuberay "Auto-deploys models via RayService"
        kuberay -> volcano "Gang scheduling via PodGroup CRDs"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "KubeRayContainers" {
            include *
            autoLayout
        }

        container rayCluster "RayClusterContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "RHOAI Security" {
                background #f5a623
                color #ffffff
            }
            element "Security Sidecar" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
