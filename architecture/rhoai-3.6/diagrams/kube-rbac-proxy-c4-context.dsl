workspace {
    model {
        prometheus = person "Prometheus / Monitoring" "Scrapes metrics from protected endpoints"
        apiConsumer = person "API Consumer" "Calls protected HTTP endpoints on RHOAI components"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "TLS-terminating reverse proxy sidecar that enforces Kubernetes RBAC authentication and authorization via SubjectAccessReview" {
            tlsTerminator = container "TLS Termination" "Terminates TLS 1.2+ connections, FIPS-compliant via strictfipsruntime/OpenSSL" "Go"
            authenticator = container "Authentication Layer" "Validates caller identity via delegated TokenReview, client TLS certificate, or OIDC JWT" "Go"
            authorizer = container "Authorization Chain" "Hardcoded authorizer → Static authorizer → SAR authorizer. Format2 supports path-scoped per-method rules with named captures" "Go"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream with injected identity headers" "Go"
            certReloader = container "Certificate Reloader" "Hot-reloads TLS certificates with configurable polling interval" "Go"
            auditLogger = container "OCSF Audit Logger" "Emits OCSF 1.9.0 AI Activity audit events via bounded non-blocking queue" "Go"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane for TokenReview and SubjectAccessReview" "External"
        upstreamService = softwareSystem "Upstream Service" "Protected HTTP service (e.g. metrics endpoint) running in the same Pod" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Cluster monitoring stack with Prometheus" "External"

        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443 TLS 1.2+ Bearer Token"
        apiConsumer -> kubeRbacProxy "Calls protected endpoints" "HTTPS/8443 TLS 1.2+ Bearer/mTLS/OIDC"
        kubeRbacProxy -> k8sApiServer "TokenReview + SubjectAccessReview" "HTTPS/6443 TLS 1.2+ SA Token"
        kubeRbacProxy -> upstreamService "Forwards authed requests" "HTTP/8081 localhost"
        certManager -> kubeRbacProxy "Provisions TLS cert/key" "kubernetes.io/tls Secret"
        openshiftMonitoring -> kubeRbacProxy "Hardcoded auto-allow for prometheus-k8s SA" "HTTPS/8443"
    }

    views {
        systemContext kubeRbacProxy "SystemContext" {
            include *
            autoLayout
        }

        container kubeRbacProxy "Containers" {
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
