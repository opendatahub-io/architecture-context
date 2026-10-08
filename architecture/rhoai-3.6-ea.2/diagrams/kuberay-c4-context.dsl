workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for distributed computing workloads"
        platformAdmin = person "Platform Admin" "Configures and monitors the KubeRay operator and platform infrastructure"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing Ray cluster lifecycle with OpenShift authentication, mTLS, and network isolation" {
            rayClusterReconciler = container "RayCluster Reconciler" "Reconciles RayCluster CRs into Pods, Services, Ingresses, RBAC resources" "Go Controller"
            rayJobReconciler = container "RayJob Reconciler" "Orchestrates Ray job submission via child RayClusters and Kubernetes Jobs" "Go Controller"
            rayServiceReconciler = container "RayService Reconciler" "Manages blue-green deployment of Ray Serve applications" "Go Controller"
            rayCronJobReconciler = container "RayCronJob Reconciler" "Schedules periodic RayJob creation (feature-gated)" "Go Controller"
            authController = container "Authentication Controller" "Manages kube-rbac-proxy sidecar injection, HTTPRoutes, OAuth configuration" "Go Controller"
            networkPolicyController = container "NetworkPolicy Controller" "Creates per-cluster NetworkPolicies with annotation-based activation" "Go Controller"
            mtlsController = container "mTLS Controller" "Manages cert-manager CA chain and per-node TLS certificates" "Go Controller"
            tlsProfileWatcher = container "TLS Profile Watcher" "Watches OpenShift APIServer for TLS profile changes, triggers graceful restart" "Go Controller"
            webhookServer = container "Admission Webhooks" "Mutating and validating webhooks for Ray CRDs" "Go Webhook Server" "9443/TCP"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics over HTTPS" "Go HTTP Server" "8443/TCP"
        }

        k8sApi = softwareSystem "Kubernetes API" "API server for cluster resource management" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for Kubernetes" "Platform Service"
        gatewayApi = softwareSystem "Gateway API" "Traffic routing via HTTPRoute and Gateway resources" "Platform Service"
        openshiftApiServer = softwareSystem "OpenShift API Server" "Provides cluster-wide TLS security profile configuration" "Platform Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform Service"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "OAuth/OIDC authentication proxy sidecar for Ray head pods" "Platform Service"
        volcano = softwareSystem "Volcano" "Batch scheduler for gang scheduling of Ray worker pods" "Optional"

        rayRuntime = softwareSystem "Ray Head Dashboard" "Ray distributed computing dashboard and API" "Runtime"

        dataScientist -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl/API"
        platformAdmin -> kuberay "Configures operator settings, monitors metrics"

        kuberay -> k8sApi "CRUD operations for Pods, Services, RBAC, CRDs" "HTTPS/6443"
        kuberay -> certManager "Creates Issuer and Certificate resources for mTLS" "Kubernetes API"
        kuberay -> gatewayApi "Creates HTTPRoutes and ReferenceGrants for authenticated access" "Kubernetes API"
        kuberay -> openshiftApiServer "Reads TLS security profile configuration" "Kubernetes API"
        kuberay -> rayRuntime "Submits jobs, polls status via dashboard API" "HTTP+WebSocket/8265"
        kuberay -> kubeRbacProxy "Injects as sidecar into Ray head pods" "Container injection"
        kuberay -> volcano "Creates PodGroups for gang scheduling" "Kubernetes API"

        prometheus -> kuberay "Scrapes operator metrics" "HTTPS/8443"
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
            element "Platform Service" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
