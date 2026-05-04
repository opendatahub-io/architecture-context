workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Ray clusters, jobs, and services for distributed ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Manages the lifecycle of Ray clusters, jobs, and services on Kubernetes/OpenShift" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs — creates head/worker pods, services, ingress, RBAC for autoscaler" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Reconciles RayJob CRs — creates ephemeral RayClusters, submits jobs via dashboard API" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Reconciles RayService CRs — manages active/pending clusters for zero-downtime upgrades" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Manages OAuth/OIDC proxy sidecars, HTTPRoutes, ReferenceGrants for authenticated dashboard access" "Go (controller-runtime)"
            mtlsController = container "MTLS Controller" "Manages cert-manager Issuers and Certificates for intra-cluster mTLS communication" "Go (controller-runtime)"
            networkPolicyController = container "NetworkPolicy Controller" "Creates per-cluster NetworkPolicies for head and worker pod network isolation" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating and validating webhooks for RayCluster resources" "Go HTTPS/9443"
        }

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing runtime with head and worker pods" {
            headPod = container "Ray Head Pod" "Runs Ray dashboard, GCS server, and optional auth proxy sidecar" "Python/Ray"
            workerPods = container "Ray Worker Pods" "Execute distributed tasks and Ray Serve applications" "Python/Ray"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS" "External"
        gateway = softwareSystem "data-science-gateway" "Shared platform ingress gateway (Envoy/Gateway API)" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth/OIDC authentication provider" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for batch workloads" "External Optional"
        rhoaiOperator = softwareSystem "RHOAI/ODH Operator" "Platform operator that deploys KubeRay" "Internal RHOAI"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl" "HTTPS/443"
        user -> gateway "Accesses Ray Dashboard" "HTTPS/443 (session cookie)"

        # KubeRay → Platform dependencies
        kuberay -> k8sApi "CRD watches, pod/service/secret CRUD, RBAC operations" "HTTPS/443 SA Token"
        kuberay -> certManager "Issues and rotates mTLS certificates" "Kubernetes API"
        kuberay -> openshiftOAuth "Reads OAuth configuration for proxy setup" "HTTPS/443"

        # Gateway → Ray Cluster
        gateway -> rayCluster "Routes dashboard traffic via HTTPRoute" "HTTPS/8443 (SubjectAccessReview)"

        # KubeRay → Ray Cluster
        kuberay -> rayCluster "Job submission, status polling, Serve config updates" "HTTP/8265"

        # Ray Cluster internal
        headPod -> workerPods "Distributes tasks" "gRPC (mTLS)"

        # Monitoring
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes cluster metrics" "HTTP/8080"

        # Platform deployment
        rhoaiOperator -> kuberay "Deploys via kustomize manifests"

        # Container relationships
        rayClusterController -> k8sApi "Creates pods, services, RBAC"
        rayJobController -> headPod "Submits jobs via dashboard API" "HTTP/8265"
        rayServiceController -> headPod "Manages Serve configuration" "HTTP/8265"
        authController -> gateway "Creates HTTPRoutes in platform namespace"
        mtlsController -> certManager "Creates Issuers and Certificates"
        networkPolicyController -> k8sApi "Creates NetworkPolicies"
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
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
