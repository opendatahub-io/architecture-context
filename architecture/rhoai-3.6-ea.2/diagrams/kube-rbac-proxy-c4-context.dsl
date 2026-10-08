workspace {
    model {
        prometheus = person "Prometheus" "OpenShift Monitoring - scrapes metrics endpoints"
        datascientist = person "Data Scientist / Client" "Invokes protected API endpoints"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy enforcing Kubernetes RBAC authentication and authorization as a sidecar" {
            tlsTermination = container "TLS Termination" "Terminates TLS on port 8443, hot-reloads certs via CertReloader" "Go net/http"
            authnFilter = container "Authentication Filter" "Validates identity via TokenReview, OIDC JWT, or Client TLS" "Go middleware"
            authzChain = container "Authorization Chain" "Evaluates hardcoded metrics authorizer, static rules (Format1/Format2), SubjectAccessReview" "Go middleware"
            upstreamProxy = container "Upstream Proxy" "Forwards authenticated/authorized requests to upstream on localhost" "Go httputil.ReverseProxy"
            auditLogger = container "Audit Logger" "OCSF 1.9.0 API Activity events with bounded non-blocking queue" "Go"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Handles TokenReview and SubjectAccessReview delegation" "External"
        oidcProvider = softwareSystem "OIDC Provider" "JWT token validation endpoint" "External"
        upstreamService = softwareSystem "Upstream Service" "Protected service (metrics endpoint, TrustyAI, etc.) on localhost" "Internal"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus service account with hardcoded metrics access" "External"

        prometheus -> kubeRbacProxy "Scrapes metrics" "HTTPS/8443, Bearer Token"
        datascientist -> kubeRbacProxy "Invokes protected APIs" "HTTPS/8443, Bearer Token"

        kubeRbacProxy -> k8sApiServer "Delegates authn/authz" "HTTPS/6443 (TokenReview, SubjectAccessReview)"
        kubeRbacProxy -> oidcProvider "Validates OIDC JWTs" "HTTPS/443"
        kubeRbacProxy -> upstreamService "Proxies authorized requests" "HTTP localhost"
        certManager -> kubeRbacProxy "Provisions TLS certs" "kubernetes.io/tls Secret"
        openshiftMonitoring -> kubeRbacProxy "Hardcoded metrics access" "prometheus-k8s SA"

        tlsTermination -> authnFilter "Decrypted request"
        authnFilter -> authzChain "Authenticated identity"
        authzChain -> upstreamProxy "Authorized request"
        authzChain -> auditLogger "Audit event"
        authnFilter -> k8sApiServer "TokenReview" "HTTPS/6443"
        authnFilter -> oidcProvider "OIDC validation" "HTTPS/443"
        authzChain -> k8sApiServer "SubjectAccessReview" "HTTPS/6443"
        upstreamProxy -> upstreamService "Proxied request" "HTTP localhost"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
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
