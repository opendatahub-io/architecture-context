workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for distributed computing workloads"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing the lifecycle of Ray clusters, jobs, and services through custom resources on OpenShift" {
            rayClusterCtrl = container "RayClusterReconciler" "Provisions and manages head/worker pods, services, ingress, and RBAC for RayCluster resources" "Go Controller"
            rayJobCtrl = container "RayJobReconciler" "Creates transient RayClusters, submits Ray jobs, manages lifecycle cleanup" "Go Controller"
            rayServiceCtrl = container "RayServiceReconciler" "Manages zero-downtime upgrades of Ray Serve applications via blue/green transitions" "Go Controller"
            rayCronJobCtrl = container "RayCronJobReconciler" "Schedules recurring RayJob executions on a cron schedule" "Go Controller"
            authCtrl = container "AuthenticationController" "Manages kube-rbac-proxy sidecars, Gateway API HTTPRoutes, OIDC proxy configuration" "Go Controller"
            netPolCtrl = container "NetworkPolicyController" "Creates per-RayCluster NetworkPolicies for network isolation" "Go Controller"
            mtlsCtrl = container "RayClusterMTLSController" "Provisions cert-manager Certificates and Issuers for mTLS" "Go Controller"
            tlsWatcher = container "TLS Profile Watcher" "Monitors OpenShift APIServer TLS profile changes" "Go Controller"
            mutatingWebhook = container "Mutating Webhook" "Enforces secure defaults on RayClusters" "Admission Webhook" "9443/TCP"
            validatingWebhook = container "Validating Webhooks" "Validates RayCluster, RayJob, RayService resources" "Admission Webhook" "9443/TCP"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for Kubernetes" "Internal Platform"
        gatewayApi = softwareSystem "Platform Gateway" "Gateway API for authenticated ingress" "Internal Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "OIDC authentication sidecar for Ray dashboard access" "Internal Platform"
        openShiftConfig = softwareSystem "OpenShift APIServer Config" "Cluster-wide TLS security profile configuration" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        batchSchedulers = softwareSystem "Batch Schedulers" "Gang scheduling via Volcano, YuniKorn, or Kai" "External"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService CRs via kubectl" "HTTPS/6443"
        user -> gatewayApi "Accesses Ray dashboard" "HTTPS/443 OIDC"

        # KubeRay dependencies
        kuberay -> k8sApi "Reconciles CRDs, manages pods/services/secrets/jobs" "HTTPS/6443"
        kuberay -> certManager "Provisions webhook TLS and mTLS certificates" "Certificate/Issuer CRDs"
        kuberay -> gatewayApi "Creates HTTPRoutes for authenticated dashboard access" "HTTPRoute CRDs"
        kuberay -> openShiftConfig "Reads cluster TLS security profile" "HTTPS/6443 read-only"
        kuberay -> batchSchedulers "Gang scheduling via PodGroup CRDs" "HTTPS/6443"

        # Consumers
        prometheus -> kuberay "Scrapes operator and Ray cluster metrics" "HTTPS/8443"
        gatewayApi -> kubeRbacProxy "Routes dashboard requests through auth sidecar" "HTTPS/8443"
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
            element "Internal Platform" {
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
