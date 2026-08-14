workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for distributed ML workloads"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        kuberay = softwareSystem "KubeRay" "Kubernetes operator managing Ray cluster lifecycle with OIDC/OAuth authentication and mTLS" {
            rayOperator = container "ray-operator" "Multi-controller operator managing RayCluster, RayJob, RayService, RayCronJob CRDs" "Go controller-runtime"
            authController = container "AuthenticationController" "Injects kube-rbac-proxy sidecar, creates HTTPRoute and ReferenceGrant for authenticated dashboard access" "Go Controller"
            networkPolicyController = container "NetworkPolicyController" "Creates per-cluster NetworkPolicy resources for network isolation" "Go Controller"
            mtlsController = container "RayClusterMTLSController" "Manages cert-manager Certificate and Issuer resources for inter-node mTLS" "Go Controller"
            webhookServer = container "Webhook Server" "Validates and mutates RayCluster, RayJob, RayService resources" "HTTPS Admission Webhooks"
            metricsServer = container "Metrics Server" "Prometheus-compatible metrics endpoint" "HTTP :8080"
        }

        kubernetes = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS and webhook TLS" "Internal RHOAI" {
            tags "Internal"
        }

        gatewayAPI = softwareSystem "Gateway API" "Ingress routing for authenticated Ray dashboard access via HTTPRoute" "Internal" {
            tags "Internal"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar injected into Ray head pods; enforces OIDC/OAuth via TokenReview" "Internal" {
            tags "Internal"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI" {
            tags "Internal"
        }

        openshiftConfig = softwareSystem "OpenShift Cluster Config" "Cluster-wide TLS security profile and API server configuration" "External" {
            tags "External"
        }

        # Relationships
        dataScientist -> kuberay "Creates RayCluster, RayJob, RayService CRs" "kubectl / API"
        dataScientist -> gatewayAPI "Accesses Ray Dashboard" "HTTPS/443 Bearer Token"
        platformAdmin -> kuberay "Configures operator settings" "kubectl"

        kuberay -> kubernetes "Watches CRDs, creates Pods, Services, Secrets, NetworkPolicies, Jobs" "HTTPS/6443"
        kuberay -> certManager "Creates Certificate and Issuer CRs for mTLS" "Kubernetes API"
        kuberay -> gatewayAPI "Creates HTTPRoute and ReferenceGrant for dashboard ingress" "Kubernetes API"
        kuberay -> openshiftConfig "Reads cluster-wide TLS security profile" "Kubernetes API"

        gatewayAPI -> kubeRbacProxy "Routes dashboard requests" "HTTPS/8443"
        kubeRbacProxy -> kubernetes "TokenReview + SubjectAccessReview" "HTTPS/6443"

        prometheus -> kuberay "Scrapes metrics" "HTTP/8080"

        rayOperator -> authController "Delegates authentication setup"
        rayOperator -> networkPolicyController "Delegates network isolation"
        rayOperator -> mtlsController "Delegates mTLS certificate management"
        rayOperator -> webhookServer "Admission validation"
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
            element "Internal" {
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
