workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates Ray clusters, submits jobs, and deploys serving workloads"
        platformAdmin = person "Platform Admin" "Deploys and configures the KubeRay operator via RHOAI"

        // Primary System
        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle, jobs, and serving workloads on OpenShift with integrated security" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs — creates head/worker Pods, Services, autoscaler RBAC" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Reconciles RayJob CRs — creates transient RayClusters and K8s Job submitters" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Reconciles RayService CRs — manages zero-downtime upgrades for Serve workloads" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Creates HTTPRoutes, ReferenceGrants, kube-rbac-proxy ConfigMaps for dashboard auth" "Go (controller-runtime)" "OpenShift-specific"
            npController = container "NetworkPolicy Controller" "Creates per-cluster head and worker NetworkPolicies for pod isolation" "Go (controller-runtime)" "OpenShift-specific"
            mtlsController = container "mTLS Controller" "Manages cert-manager Issuers and Certificates for intra-cluster mTLS" "Go (controller-runtime)" "OpenShift-specific"
            webhookServer = container "Webhook Server" "Mutating + validating admission webhooks for RayCluster resources" "Go (9443/TCP HTTPS)"
        }

        // Internal ODH/RHOAI Components
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and manages KubeRay operator lifecycle" "Internal ODH"
        gateway = softwareSystem "data-science-gateway" "Platform Gateway (Gateway API) for centralized ingress and TLS termination" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection platform" "Internal ODH"

        // External Dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane for resource management" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate lifecycle management" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for mTLS and traffic management" "External"

        // Ray Runtime (managed resources)
        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster (head + workers) managed by KubeRay" "Managed"

        // Relationships - People
        dataScientist -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl/UI"
        dataScientist -> gateway "Accesses Ray Dashboard via HTTPS/443 (OIDC/OAuth)" "HTTPS/443 TLS 1.3"
        platformAdmin -> rhoaiOperator "Configures KubeRay deployment"

        // Relationships - KubeRay to external
        kuberay -> k8sAPI "CRUD operations on Pods, Services, HTTPRoutes, NetworkPolicies, Secrets" "HTTPS/443 TLS 1.2+"
        kuberay -> certManager "Creates Issuers and Certificates for mTLS PKI" "CRD API"
        kuberay -> rayCluster "Creates and manages head/worker Pods, monitors dashboard" "HTTP/8265, TCP/6379"
        kuberay -> gateway "Creates HTTPRoutes in platform namespace for dashboard access" "CRD API"

        // Relationships - Internal
        rhoaiOperator -> kuberay "Deploys via kustomize manifests"
        gateway -> rayCluster "Routes dashboard traffic to kube-rbac-proxy sidecar" "HTTPS/8443"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayCluster "Scrapes Ray cluster metrics" "HTTP/8080"

        // Internal container relationships
        rayClusterController -> k8sAPI "Creates Pods, Services, RBAC" "HTTPS/443"
        rayJobController -> rayCluster "Submits jobs via Dashboard REST API" "HTTP/8265"
        rayServiceController -> rayCluster "Manages Serve applications via Dashboard API" "HTTP/8265"
        authController -> k8sAPI "Creates HTTPRoutes, ReferenceGrants, ConfigMaps" "HTTPS/443"
        npController -> k8sAPI "Creates NetworkPolicies" "HTTPS/443"
        mtlsController -> certManager "Creates Issuers and Certificates" "CRD API"
        rayClusterController -> authController "Waits for AuthenticationReady condition" "Internal"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Managed" {
                background #f5a623
                color #ffffff
            }
            element "OpenShift-specific" {
                background #e67e22
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
