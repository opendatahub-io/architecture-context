workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on Kubernetes/OpenShift" {
            rayClusterCtrl = container "RayCluster Controller" "Reconciles RayCluster CRs — creates head/worker pods, services, ingress, RBAC" "Go (controller-runtime)"
            rayJobCtrl = container "RayJob Controller" "Reconciles RayJob CRs — creates ephemeral clusters, submits jobs" "Go (controller-runtime)"
            rayServiceCtrl = container "RayService Controller" "Reconciles RayService CRs — manages blue-green upgrades" "Go (controller-runtime)"
            authCtrl = container "Authentication Controller" "Manages OAuth/OIDC proxy sidecars, HTTPRoutes, ReferenceGrants" "Go (controller-runtime)"
            mtlsCtrl = container "MTLS Controller" "Manages cert-manager Issuers and Certificates for intra-cluster mTLS" "Go (controller-runtime)"
            netpolCtrl = container "NetworkPolicy Controller" "Creates per-cluster NetworkPolicies for network isolation" "Go (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Defaults RayCluster annotations on OpenShift" "Go (9443/TCP HTTPS)"
            validatingWebhook = container "Validating Webhook" "Validates RayCluster name format and worker group uniqueness" "Go (9443/TCP HTTPS)"
        }

        rayRuntime = softwareSystem "Ray Runtime" "Head and worker pods running distributed ML workloads" {
            rayHead = container "Ray Head Pod" "Dashboard (8265), GCS (6379), Client (10001), Serve (8000)" "Ray >= 2.0"
            rayWorkers = container "Ray Worker Pods" "Distributed task execution" "Ray >= 2.0"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS" "External"
        gateway = softwareSystem "data-science-gateway" "Shared platform ingress gateway (Envoy)" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth/OIDC authentication configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        rhoaiOperator = softwareSystem "RHOAI/ODH Operator" "Deploys KubeRay operator via kustomize manifests" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRD" "External"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Coscheduling via PodGroup" "External"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl" "HTTPS/443"
        user -> gateway "Accesses Ray Dashboard" "HTTPS/443"

        # KubeRay → Platform dependencies
        kuberay -> k8sApi "CRD watches, pod/service/secret CRUD, RBAC operations" "HTTPS/443"
        kuberay -> certManager "Issues and rotates mTLS certificates" "Kubernetes API"
        kuberay -> openshiftOAuth "Reads OAuth configuration for proxy setup" "HTTPS/443"

        # KubeRay → Ray runtime
        kuberay -> rayRuntime "Creates head/worker pods, submits jobs, manages Serve config" "HTTP/8265, HTTP/8000"

        # Gateway integration
        gateway -> rayRuntime "Routes dashboard traffic via HTTPRoute" "HTTPS/8443"

        # Monitoring
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        prometheus -> rayRuntime "Scrapes Ray cluster metrics" "HTTP/8080"

        # Deployment
        rhoaiOperator -> kuberay "Deploys via kustomize manifests"

        # Batch scheduling (optional)
        kuberay -> volcano "Gang scheduling via PodGroup CRD" "Kubernetes API"
        kuberay -> schedulerPlugins "Coscheduling via PodGroup" "Kubernetes API"

        # Internal Ray communication
        rayHead -> rayWorkers "Distributes tasks" "gRPC/TCP, mTLS"
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

        container rayRuntime "RayRuntimeContainers" {
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
