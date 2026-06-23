workspace {
    model {
        user = person "Application Client" "Service or user sending requests to RHOAI components"
        prometheusUser = person "Prometheus" "OpenShift Monitoring stack (prometheus-k8s SA)"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar that enforces Kubernetes RBAC authorization via SubjectAccessReview before forwarding requests to upstream services" {
            tlsTermination = container "TLS Termination" "Terminates TLS 1.2+ connections, supports configurable cipher suites, HTTP/2, X.509 client certs" "Go net/http + crypto/tls"
            authenticationFilter = container "Authentication Filter" "Authenticates requests via TokenReview delegation, OIDC JWT, or X.509 client certificates" "Go Delegating Authenticator"
            authorizationChain = container "Authorization Chain" "Union authorizer: hardcoded metrics → static rules → SubjectAccessReview" "Go Union Authorizer"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream, injects identity headers" "Go httputil.ReverseProxy"
            certReloader = container "CertReloader" "Hot-reloads TLS certificates from disk at configurable interval (default 1 minute)" "Go polling watcher"
            sanitizingFilter = container "Sanitizing Filter" "Masks tokens in TokenReview log messages to prevent credential leakage" "Go log filter"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane providing TokenReview and SubjectAccessReview APIs" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for JWT-based authentication (optional)" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy as sidecar into component pods" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "RHOAI component container (dashboard, model registry, TrustyAI, notebooks, etc.) listening on localhost" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Kubernetes certificate management controller providing TLS certificates" "External"

        # Relationships
        user -> kubeRbacProxy "Sends authenticated requests" "HTTPS/8443, TLS 1.2+"
        prometheusUser -> kubeRbacProxy "Scrapes metrics" "HTTPS/8443, GET /metrics"

        tlsTermination -> authenticationFilter "Passes decrypted request"
        authenticationFilter -> authorizationChain "Passes authenticated identity"
        authorizationChain -> reverseProxy "Passes authorized request"

        kubeRbacProxy -> k8sApiServer "TokenReview (authn) + SubjectAccessReview (authz)" "HTTPS/443, SA Token"
        kubeRbacProxy -> oidcProvider "Fetches JWKS and OIDC discovery metadata" "HTTPS/443"
        kubeRbacProxy -> upstreamApp "Forwards authorized requests" "HTTP/8081, localhost, no TLS"
        rhodsOperator -> kubeRbacProxy "Injects sidecar container into component Deployments"
        certManager -> kubeRbacProxy "Provisions and rotates TLS certificates"
        certReloader -> tlsTermination "Reloads certificates" "file watch, 1min poll"
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
