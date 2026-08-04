workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters for distributed ML workloads"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on OpenShift with mTLS, OIDC dashboard access, and Gateway API integration" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs, creates head/worker Pods, Services, and supporting resources" "Go controller-runtime"
            rayJobController = container "RayJob Controller" "Reconciles RayJob CRs, manages Job submission and RayCluster lifecycle" "Go controller-runtime"
            rayServiceController = container "RayService Controller" "Reconciles RayService CRs, manages multi-version serving with blue-green deployment" "Go controller-runtime"
            rayCronJobController = container "RayCronJob Controller" "Reconciles RayCronJob CRs, schedules periodic RayJob creation" "Go controller-runtime"
            authController = container "Authentication Controller" "Injects kube-rbac-proxy sidecar for OIDC dashboard access, manages Gateway API HTTPRoutes and OpenShift Routes" "Go controller-runtime"
            mtlsController = container "mTLS Controller" "Provisions cert-manager Certificate and Issuer resources for inter-node mTLS" "Go controller-runtime"
            networkPolicyController = container "NetworkPolicy Controller" "Creates NetworkPolicy resources to restrict intra-cluster traffic" "Go controller-runtime"
            webhookServer = container "Admission Webhook Server" "Validates and mutates RayCluster, RayJob, and RayService resources" "Go HTTPS"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on :8080" "Go HTTP"
            tlsProfileWatcher = container "TLS Profile Watcher" "Monitors OpenShift APIServer TLS profile and triggers graceful restart on changes" "Go controller-runtime"
        }

        k8sapi = softwareSystem "Kubernetes API Server" "Cluster API for managing all Kubernetes resources" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for Kubernetes" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes-native API for managing network gateways and routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openshiftConfig = softwareSystem "OpenShift Platform Config" "Cluster-wide configuration including TLS security profiles" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "OIDC-based authentication proxy for Ray dashboard access" "Sidecar"

        user -> kuberay "Creates RayCluster, RayJob, RayService, RayCronJob via kubectl"
        kuberay -> k8sapi "Watches CRs, creates/manages Pods, Services, Secrets, Jobs, NetworkPolicies" "HTTPS/6443 TLS 1.2+ ServiceAccount"
        kuberay -> certManager "Creates Certificate and Issuer CRDs for mTLS" "Kubernetes API"
        kuberay -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants for dashboard routing" "Kubernetes API"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        kuberay -> openshiftConfig "Reads TLS security profile for cipher/version alignment" "Kubernetes API"
        kuberay -> kubeRBACProxy "Injects as sidecar into Ray head Pods for OIDC auth" "Container injection"
        user -> kubeRBACProxy "Accesses Ray Dashboard" "HTTPS/8443 OIDC"
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
            element "Sidecar" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
