workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Ray clusters, jobs, and services for ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing Ray cluster lifecycle, jobs, services, and cron jobs with OpenShift-specific auth, mTLS, and Gateway API integration" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs — creates head/worker pods, services, ingress, RBAC, handles upgrades and GCS fault tolerance" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Reconciles RayJob CRs — creates ephemeral RayClusters, submitter Jobs, monitors job execution via Ray Dashboard API" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Reconciles RayService CRs — manages active/pending clusters, serve application deployment, zero-downtime upgrades via Gateway API" "Go (controller-runtime)"
            rayCronJobController = container "RayCronJob Controller" "Reconciles RayCronJob CRs — creates RayJob instances on cron schedules" "Go (controller-runtime)"
            mtlsController = container "mTLS Controller" "Manages mutual TLS certificate lifecycle via cert-manager for RayClusters with mTLS annotation" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Manages kube-rbac-proxy sidecar injection, HTTPRoute creation, ReferenceGrant management for OIDC authentication" "Go (controller-runtime)"
            networkPolicyController = container "NetworkPolicy Controller" "Creates head and worker NetworkPolicies for RayClusters with secure-trusted-network annotation" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for RayCluster, RayJob, RayService" "Go (9443/TCP HTTPS)"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics for cluster/job/service state" "Go (8080/TCP HTTP+TLS)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD, informer watches, leader election" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS" "External"
        gatewayAPI = softwareSystem "Platform Gateway (Gateway API)" "Centralized ingress with HTTPRoute-based routing and authentication" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "OIDC authentication sidecar enforcing SubjectAccessReview" "Internal RHOAI"
        openshiftAPI = softwareSystem "OpenShift API" "Cluster configuration: TLS security profiles, auth mode detection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        redis = softwareSystem "Redis" "GCS fault tolerance external storage" "External"
        rhodsOperator = softwareSystem "RHODS Operator" "Deploys kuberay-operator via kustomize manifests" "Internal RHOAI"
        rayDashboard = softwareSystem "Ray Dashboard API" "Job submission, status polling, serve config deployment" "Internal Ray"

        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling for Ray cluster pods" "External"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Provides external webhooks for RayCluster validation" "Internal RHOAI"

        user -> kuberay "Creates RayCluster, RayJob, RayService, RayCronJob CRs via kubectl/API"
        rhodsOperator -> kuberay "Deploys operator manifests via kustomize"
        codeflareOperator -> kuberay "External webhooks: mraycluster.ray.openshift.ai, vraycluster.ray.openshift.ai"

        kuberay -> k8sAPI "Resource CRUD, informer watches, leader election" "HTTPS/443"
        kuberay -> certManager "Certificate and Issuer lifecycle management (mTLS)" "HTTPS/443"
        kuberay -> gatewayAPI "Creates HTTPRoutes with cross-namespace backend refs" "Kubernetes API"
        kuberay -> kubeRBACProxy "Injects as sidecar for OIDC auth enforcement" "HTTPS/8443"
        kuberay -> openshiftAPI "TLS security profile resolution, auth mode detection" "HTTPS/443"
        kuberay -> rayDashboard "Job submission, status polling, serve config deployment" "HTTP/8265"
        kuberay -> redis "GCS fault tolerance external storage" "TCP/6379"
        kuberay -> volcanoScheduler "Gang scheduling PodGroups" "Kubernetes API"

        prometheus -> kuberay "Scrapes cluster/job/service metrics" "HTTP+TLS/8080"
        k8sAPI -> kuberay "Admission webhook calls" "HTTPS/9443"
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
            element "Internal Ray" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
