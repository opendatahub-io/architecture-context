workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for ML workloads"
        platformAdmin = person "Platform Admin" "Deploys and configures the KubeRay operator via RHOAI"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on Kubernetes/OpenShift" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs - creates head/worker pods, services, ingress, RBAC" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Reconciles RayJob CRs - creates ephemeral clusters, submits jobs via dashboard API" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Reconciles RayService CRs - manages blue-green deployments for zero-downtime upgrades" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Manages OAuth/OIDC proxy sidecars, HTTPRoutes, ReferenceGrants for authenticated dashboard access" "Go (controller-runtime)"
            mtlsController = container "MTLS Controller" "Manages cert-manager Issuers and Certificates for intra-cluster mTLS" "Go (controller-runtime)"
            networkPolicyController = container "NetworkPolicy Controller" "Creates per-cluster NetworkPolicies for head/worker network isolation" "Go (controller-runtime)"
            webhooks = container "Admission Webhooks" "Mutating: enforces Gateway-only mode, secure-network. Validating: name format, worker uniqueness" "Go (9443/TCP HTTPS)"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for operator and Ray cluster state" "HTTP (8080/TCP)"
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster with head and worker pods running Ray runtime" {
            headPod = container "Ray Head Pod" "Ray head node with dashboard (8265), GCS server (6379), client port (10001), serve proxy (8000)" "Ray Runtime"
            workerPods = container "Ray Worker Pods" "Ray worker nodes for distributed task execution" "Ray Runtime"
            authProxy = container "Auth Proxy Sidecar" "kube-rbac-proxy or OAuth proxy for authenticated dashboard access" "Go (8443/TCP HTTPS)"
        }

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches, resource CRUD, RBAC, admission webhooks" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management - issues per-cluster CA and TLS certificates for mTLS" "External"
        gateway = softwareSystem "data-science-gateway" "Shared platform Envoy gateway for centralized ingress via HTTPRoutes" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth/OIDC configuration for integrated authentication proxy setup" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from operator and Ray clusters" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduling of Ray pods via PodGroup CRD" "External"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Optional coscheduling of Ray pods via PodGroup CRD" "External"
        rhoaiOperator = softwareSystem "RHOAI/ODH Operator" "Deploys KubeRay operator via kustomize manifests" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Peer operator with mutating/validating webhooks on RayCluster resources" "Internal RHOAI"

        # Relationships - User
        user -> kuberay "Creates RayCluster, RayJob, RayService CRs" "kubectl / HTTPS 443"
        user -> rayCluster "Accesses Ray Dashboard" "HTTPS 443 via Gateway"
        platformAdmin -> rhoaiOperator "Deploys KubeRay" "RHOAI Dashboard"

        # Relationships - KubeRay to Platform
        kuberay -> k8sAPI "CRD watches, pod/service CRUD, RBAC management" "HTTPS/443 TLS 1.2+"
        kuberay -> certManager "Creates Issuers and Certificates for mTLS" "Kubernetes API"
        kuberay -> openshiftOAuth "Reads OAuth configuration for proxy setup" "HTTPS/443 TLS 1.2+"
        kuberay -> rayCluster "Creates and manages Ray head/worker pods, submits jobs" "HTTP/8265, HTTP/8000"

        # Relationships - Ingress
        gateway -> rayCluster "Routes authenticated requests to auth proxy" "HTTPS/8443"

        # Relationships - Monitoring
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray cluster metrics" "HTTP/8080"

        # Relationships - Scheduling
        kuberay -> volcano "Creates PodGroups for gang scheduling" "Kubernetes API"
        kuberay -> schedulerPlugins "Creates PodGroups for coscheduling" "Kubernetes API"

        # Relationships - Peer operators
        rhoaiOperator -> kuberay "Deploys via kustomize" "Kubernetes API"
        codeflareOperator -> k8sAPI "Registers webhooks on RayCluster" "HTTPS/443"

        # Internal container relationships
        rayClusterController -> rayJobController "Creates ephemeral RayClusters"
        headPod -> workerPods "Distributes tasks" "gRPC, mTLS"
    }

    views {
        systemContext kuberay "KubeRay-SystemContext" {
            include *
            autoLayout
        }

        container kuberay "KubeRay-Containers" {
            include *
            autoLayout
        }

        container rayCluster "RayCluster-Containers" {
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
