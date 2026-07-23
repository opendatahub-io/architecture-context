workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for distributed ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Manages the lifecycle of Ray clusters, jobs, services, and cron jobs on OpenShift / RHOAI" {
            rcController = container "RayCluster Controller" "Creates and reconciles head/worker pods, services, RBAC, coordinates with auth/mTLS/NetworkPolicy controllers" "Go (controller-runtime)"
            rjController = container "RayJob Controller" "Manages job submission lifecycle with K8sJob, HTTP, Sidecar, Interactive modes" "Go (controller-runtime)"
            rsController = container "RayService Controller" "Manages Ray Serve deployment with zero-downtime upgrade strategies including incremental traffic migration" "Go (controller-runtime)"
            rcjController = container "RayCronJob Controller" "Schedules recurring RayJob creation on cron expressions (alpha)" "Go (controller-runtime)"
            npController = container "NetworkPolicy Controller" "Creates per-cluster NetworkPolicies when annotation enabled" "Go (controller-runtime)"
            mtlsController = container "mTLS Controller" "Manages cert-manager Issuers and Certificates for inter-pod mTLS" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Injects kube-rbac-proxy sidecar, creates HTTPRoutes, ReferenceGrants for OIDC/OAuth auth" "Go (controller-runtime)"
            webhooks = container "Admission Webhooks" "Mutating webhook enforces OpenShift secure defaults; validating webhooks for RayCluster, RayJob, RayService" "Go (Kubernetes admission)"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and RBAC" "External"
        openshiftApi = softwareSystem "OpenShift API" "OpenShift cluster configuration (TLS profiles, authentication, OAuth)" "External"
        platformGateway = softwareSystem "Platform Gateway" "Envoy-based gateway for external traffic ingress via Gateway API" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "OIDC/OAuth token validation sidecar injected into Ray head pods" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS between Ray pods" "External"
        rhodsOperator = softwareSystem "RHODS/ODH Operator" "Platform operator that deploys KubeRay with OpenShift configuration overlays" "Internal RHOAI"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Batch scheduling with gang scheduling support for Ray clusters" "External"
        yunikornScheduler = softwareSystem "Yunikorn Scheduler" "Task group annotations for gang scheduling" "External"
        kaiScheduler = softwareSystem "Kai Scheduler" "GPU-aware batch scheduling" "External"
        kueue = softwareSystem "Kueue" "Multi-cluster job queuing via managedBy field" "External"

        user -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl"
        rhodsOperator -> kuberay "Deploys operator with kustomize overlays"
        kuberay -> kubernetesApi "CRD watches, pod/service lifecycle, RBAC, leader election" "HTTPS/6443"
        kuberay -> openshiftApi "Reads TLS security profile, authentication config" "HTTPS/6443"
        kuberay -> platformGateway "Creates HTTPRoutes referencing platform gateway" "Gateway API CRD"
        kuberay -> kubeRbacProxy "Injects sidecar into head pods for dashboard auth" "Sidecar injection"
        kuberay -> certManager "Creates Issuers and Certificates for mTLS" "CRD/6443"
        kuberay -> volcanoScheduler "PodGroup CRDs for gang scheduling" "CRD/6443"
        kuberay -> yunikornScheduler "Task group annotations on pods" "Pod annotations"
        kuberay -> kaiScheduler "GPU-aware batch scheduling" "CRD/6443"
        kuberay -> kueue "managedBy field delegates lifecycle" "CRD field"
        user -> platformGateway "Accesses Ray Dashboard via browser" "HTTPS/443"
        platformGateway -> kubeRbacProxy "Forwards authenticated requests" "HTTPS/8443"
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
