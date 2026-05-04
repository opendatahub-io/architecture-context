workspace {
    model {
        operator = person "Platform Operator" "Manages RHOAI platform components via rhods-operator"
        developer = person "Developer / Data Scientist" "Accesses protected component endpoints"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy enforcing Kubernetes RBAC authorization via SubjectAccessReview before forwarding to upstream" {
            secureListener = container "Secure Listener" "TLS-terminated HTTPS listener on port 8443" "Go net/http"
            authnModule = container "Authentication Module" "Supports delegating (TokenReview), OIDC JWT, and x509 client certificate authentication" "Go pkg/authn"
            authzModule = container "Authorization Module" "Union authorizer: hardcoded metrics + static + SubjectAccessReview" "Go pkg/authz"
            filterChain = container "Filter Chain" "HTTP middleware: path filter, authn, authz, header injection" "Go pkg/filters"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream application" "Go pkg/proxy"
            tlsReloader = container "TLS CertReloader" "Hot-reloads TLS certificates at configurable intervals" "Go pkg/tls"
            sanitizingFilter = container "Sanitizing Filter" "Masks bearer tokens in klog output to prevent credential leakage" "Go"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Provides TokenReview and SubjectAccessReview APIs for authn/authz" "External"
        upstreamApp = softwareSystem "Upstream Application" "Protected application container running on localhost within the same pod" "Internal"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Scrapes /metrics endpoints with hardcoded authorization" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy as sidecar" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / Platform TLS" "Provisions and rotates TLS certificates" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "Provides OIDC discovery and JWT signing keys (optional)" "External"

        # User interactions
        developer -> kubeRbacProxy "Sends HTTPS requests to protected endpoints" "HTTPS/8443, Bearer/mTLS/OIDC"
        rhodsOperator -> kubeRbacProxy "Injects as sidecar container into component pods" "Container Injection"
        certManager -> kubeRbacProxy "Provisions TLS certificates via file mounts" "File Mount"

        # System interactions
        kubeRbacProxy -> k8sApiServer "TokenReview and SubjectAccessReview API calls" "HTTPS/443, SA Token"
        kubeRbacProxy -> upstreamApp "Forwards authenticated/authorized requests" "HTTP (localhost)"
        kubeRbacProxy -> oidcProvider "Fetches OIDC discovery and JWKS keys" "HTTPS/443"
        prometheus -> kubeRbacProxy "Scrapes /metrics (hardcoded allow)" "HTTPS/8443, Bearer Token"

        # Container interactions
        secureListener -> filterChain "Passes incoming requests through middleware"
        filterChain -> authnModule "Delegates authentication"
        filterChain -> authzModule "Delegates authorization"
        filterChain -> reverseProxy "Forwards after auth succeeds"
        authnModule -> k8sApiServer "TokenReview API" "HTTPS/443"
        authnModule -> oidcProvider "OIDC Discovery + JWKS" "HTTPS/443"
        authzModule -> k8sApiServer "SubjectAccessReview API" "HTTPS/443"
        reverseProxy -> upstreamApp "HTTP proxy to localhost"
        tlsReloader -> secureListener "Hot-reloads certificates"
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
                background #d5e8d4
                color #333333
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
