workspace {
    model {
        user = person "Platform User / Service" "Any client making authenticated requests to RHOAI component endpoints"
        sre = person "SRE / Platform Admin" "Monitors platform health via Prometheus metrics"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar that enforces Kubernetes RBAC authorization via TokenReview and SubjectAccessReview before forwarding requests to upstream" {
            httpHandler = container "HTTP Handler Pipeline" "Middleware chain: path filter → authentication → authorization → header injection → reverse proxy" "Go HTTP Server"
            authnModule = container "Authentication Module" "Supports delegating (TokenReview), OIDC JWT, and x509 client certificate authentication" "Go Package (pkg/authn)"
            authzModule = container "Authorization Module" "Union authorizer: hardcoded metrics + static config + SubjectAccessReview" "Go Package (pkg/authz)"
            tlsReloader = container "TLS CertReloader" "Hot-reloads TLS certificates from filesystem at configurable interval" "Go Package (pkg/tls)"
            sanitizingFilter = container "Sanitizing Filter" "Masks bearer tokens in klog output to prevent credential leakage" "Go klog Filter"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Authenticates tokens (TokenReview) and authorizes requests (SubjectAccessReview)" "External"
        upstreamApp = softwareSystem "Upstream Application" "RHOAI component container protected by kube-rbac-proxy sidecar (localhost)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus (OpenShift Monitoring)" "Scrapes /metrics endpoints from RHOAI components via kube-rbac-proxy" "Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy sidecars into component deployments" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / Platform TLS" "Provisions and rotates TLS certificates for kube-rbac-proxy" "Platform"
        oidcProvider = softwareSystem "OIDC Identity Provider" "Provides OIDC discovery and JWT signing keys (optional, when --oidc-issuer set)" "External"

        # Relationships
        user -> kubeRbacProxy "Sends authenticated HTTPS requests" "HTTPS/8443, Bearer/mTLS/OIDC JWT"
        sre -> prometheus "Views metrics dashboards"

        kubeRbacProxy -> k8sApiServer "Authenticates and authorizes requests" "HTTPS/443, TokenReview + SubjectAccessReview"
        kubeRbacProxy -> upstreamApp "Forwards authenticated/authorized requests" "HTTP/HTTPS/h2c (localhost)"
        kubeRbacProxy -> oidcProvider "Fetches OIDC discovery and JWKS" "HTTPS/443"

        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443, Bearer Token (hardcoded allow)"
        rhodsOperator -> kubeRbacProxy "Injects sidecar into component pods" "Container injection"
        certManager -> kubeRbacProxy "Provisions TLS certificates" "File mount"

        # Internal relationships
        httpHandler -> authnModule "Delegates authentication"
        httpHandler -> authzModule "Delegates authorization"
        authnModule -> k8sApiServer "TokenReview API calls" "HTTPS/443"
        authzModule -> k8sApiServer "SubjectAccessReview API calls" "HTTPS/443"
        authnModule -> oidcProvider "OIDC discovery + JWKS fetch" "HTTPS/443"
        tlsReloader -> httpHandler "Provides reloaded TLS certificates"
    }

    views {
        systemContext kubeRbacProxy "SystemContext" {
            include *
            autoLayout
            description "kube-rbac-proxy in the RHOAI platform context"
        }

        container kubeRbacProxy "Containers" {
            include *
            autoLayout
            description "Internal structure of kube-rbac-proxy"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
