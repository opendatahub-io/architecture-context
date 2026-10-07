workspace {
    model {
        prometheus = person "Prometheus / Monitoring Agent" "Scrapes metrics from instrumented services"
        operator = person "Platform Operator" "Configures RBAC policies and proxy settings"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "TLS-terminating reverse proxy sidecar that enforces Kubernetes RBAC authorization via SubjectAccessReview" {
            tlsTermination = container "TLS Termination" "Terminates TLS 1.2+ with CertReloader hot-reload" "Go / crypto/tls"
            authnChain = container "Authentication Chain" "Delegating TokenReview, OIDC JWT, X509 client certs" "Go / k8s.io/apiserver"
            authzChain = container "Authorization Chain" "Hardcoded, Static, and SAR authorizers (union)" "Go / k8s.io/apiserver"
            auditLogger = container "Audit Logger" "Structured JSON audit logging at metadata level" "Go"
            reverseProxy = container "Reverse Proxy" "httputil.ReverseProxy forwarding to upstream" "Go / net/http"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane for authentication and authorization" "External"
        upstreamService = softwareSystem "Upstream Service" "Protected service (e.g., metrics endpoint) on localhost" "Internal"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Platform monitoring stack with Prometheus" "External"

        # Relationships
        prometheus -> kubeRbacProxy "Scrapes metrics" "HTTPS/8443, TLS 1.2+, Bearer Token"
        operator -> kubeRbacProxy "Configures authorization rules" "ConfigMap / CLI flags"
        openshiftMonitoring -> kubeRbacProxy "Scrapes /metrics (hardcoded allow)" "HTTPS/8443, TLS 1.2+"

        kubeRbacProxy -> k8sApiServer "TokenReview + SubjectAccessReview" "HTTPS/6443, SA Token"
        kubeRbacProxy -> upstreamService "Forwards authorized requests" "HTTP localhost"
        certManager -> kubeRbacProxy "Provisions TLS certificates" "kubernetes.io/tls Secret"

        # Container relationships
        tlsTermination -> authnChain "Decrypted request"
        authnChain -> authzChain "Authenticated identity"
        authnChain -> k8sApiServer "TokenReview" "HTTPS/6443"
        authzChain -> auditLogger "Authorization decision"
        authzChain -> k8sApiServer "SubjectAccessReview" "HTTPS/6443"
        auditLogger -> reverseProxy "Authorized request"
        reverseProxy -> upstreamService "Proxy request" "HTTP localhost"
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
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5b9bd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
