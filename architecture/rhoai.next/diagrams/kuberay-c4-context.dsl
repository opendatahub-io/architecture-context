workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Ray clusters, submits jobs, and deploys Ray Serve applications"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures operator deployment"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on OpenShift with enterprise security" {
            controller = container "KubeRay Operator Pod" "Reconciles RayCluster, RayJob, RayService CRDs" "Go (controller-runtime v0.22.1)" {
                rcController = component "RayCluster Controller" "Manages head/worker pods, services, and cluster lifecycle"
                rjController = component "RayJob Controller" "Creates clusters for jobs, submits via K8s Job, polls status"
                rsController = component "RayService Controller" "Manages Ray Serve with zero-downtime upgrades"
                authController = component "Authentication Controller" "Injects kube-rbac-proxy sidecar, creates HTTPRoutes and ReferenceGrants"
                mtlsController = component "mTLS Controller" "Creates cert-manager Issuers and Certificates for inter-node mTLS"
                npController = component "NetworkPolicy Controller" "Creates NetworkPolicies for cluster isolation"
            }
            webhook = container "Webhook Server" "Validates and mutates RayCluster resources on admission" "Go (9443/TCP HTTPS)"
            metrics = container "Metrics Endpoint" "Exposes Prometheus metrics" "HTTP (8080/TCP)"
        }

        rayCluster = softwareSystem "Ray Cluster" "User-provisioned Ray cluster with head and worker nodes" {
            headPod = container "Head Pod" "Ray head process with auth sidecar" "Ray v2.x + kube-rbac-proxy"
            workerPods = container "Worker Pods" "Ray worker processes for distributed compute" "Ray v2.x"
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External" {
            apiServer = container "API Server" "REST API for cluster resources" "443/TCP HTTPS"
        }

        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API implementation" "External"
        dsGateway = softwareSystem "data-science-gateway" "Platform ingress gateway for RHOAI" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth/OIDC" "Platform authentication provider" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        redis = softwareSystem "Redis" "External GCS fault tolerance storage" "External"

        codeflare = softwareSystem "CodeFlare Operator" "Manages distributed compute resources, adds webhooks on RayCluster" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and quota management" "Internal RHOAI"
        volcano = softwareSystem "Volcano" "Batch scheduler for gang scheduling" "External"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science resources" "Internal RHOAI"

        # Relationships - User
        user -> kuberay "Creates RayCluster/RayJob/RayService via kubectl" "HTTPS/443"
        user -> dsGateway "Accesses Ray Dashboard via browser" "HTTPS/443 OIDC/OAuth"

        # Relationships - Operator → Kubernetes
        kuberay -> kubernetes "CRUD for pods, services, CRDs, RBAC" "HTTPS/443 ServiceAccount Token"
        kubernetes -> webhook "Admission webhook callbacks" "HTTPS/9443 API server client cert"

        # Relationships - Operator → External
        kuberay -> certManager "Creates Issuers and Certificates for mTLS" "HTTPS/443"
        kuberay -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants" "HTTPS/443"
        kuberay -> openshiftOAuth "Watches auth config for sidecar mode" "HTTPS/443 read-only"

        # Relationships - Ray Cluster
        kuberay -> rayCluster "Creates and manages head/worker pods"
        controller -> headPod "Submits jobs, checks status" "HTTP/8265"
        controller -> headPod "Health checks Ray Serve proxy" "HTTP/8000"
        headPod -> workerPods "Distributed compute, GCS" "TCP/6379,10001 mTLS"

        # Relationships - Ingress
        dsGateway -> headPod "Routes dashboard traffic via HTTPRoute" "HTTPS/8443 TokenReview"

        # Relationships - Integration
        codeflare -> kuberay "Mutating/validating webhooks on RayCluster" "HTTPS/443"
        kueue -> kuberay "Webhooks + ManagedBy field delegation" "HTTPS/443"
        volcano -> kuberay "Gang scheduling via PodGroup injection"
        dashboard -> kuberay "UI management of Ray resources"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray pod metrics" "HTTP/8080"
        rayCluster -> redis "GCS fault tolerance storage" "TCP/6379"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "OperatorContainers" {
            include *
            autoLayout
        }

        component controller "OperatorComponents" {
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
            element "Internal RHOAI" {
                background #7ed321
                color #000000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
