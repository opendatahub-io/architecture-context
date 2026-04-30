workspace {
    model {
        # People
        datascientist = person "Data Scientist" "Accesses RHOAI component endpoints (dashboards, APIs)"
        sre = person "SRE / Platform Admin" "Monitors and manages RHOAI platform components"

        # Primary System
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar enforcing Kubernetes RBAC authn/authz via TokenReview and SubjectAccessReview" {
            secureListener = container "Secure Listener" "Accepts HTTPS connections on 8443/TCP with configurable TLS 1.2+" "Go net/http Server"
            delegatingAuth = container "Delegating Authenticator" "Authenticates bearer tokens via Kubernetes TokenReview API (2-min cache)" "Go Library (pkg/authn)"
            oidcAuth = container "OIDC Authenticator" "Validates OIDC JWT tokens against external issuer JWKS" "Go Library (pkg/authn)"
            x509Auth = container "X.509 Authenticator" "Validates client TLS certificates against CA bundle" "Go Library (pkg/authn)"
            hardcodedAuthz = container "Hardcoded Metrics Authorizer" "Auto-allows prometheus-k8s SA to GET /metrics" "Go Library (pkg/hardcodedauthorizer)"
            staticAuthz = container "Static Authorizer" "Matches requests against config file rules without API calls" "Go Library (pkg/authz)"
            sarAuthz = container "SAR Authorizer" "Authorizes via SubjectAccessReview API (allow 5-min / deny 30-sec cache)" "Go Library (pkg/authz)"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream application" "Go httputil.ReverseProxy"
            tlsReloader = container "TLS Certificate Reloader" "Hot-reloads server TLS certificates from disk (1-min poll)" "Go Library (pkg/tls)"
            tokenSanitizer = container "Token Sanitization Filter" "Masks bearer tokens in klog output to prevent credential leakage" "Go Filter (cmd/app)"
        }

        # External Systems
        k8sApiServer = softwareSystem "Kubernetes API Server" "Provides TokenReview and SubjectAccessReview APIs for authentication and authorization" "External"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Scrapes /metrics endpoints from RHOAI components" "External"
        oidcIssuer = softwareSystem "OIDC Issuer" "External OpenID Connect identity provider for JWT-based authentication" "External"
        upstreamApp = softwareSystem "Upstream Application" "The actual RHOAI component (dashboard, model registry, etc.) running in the same pod" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy sidecar into component pods" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for the proxy's secure listener" "External"
        platformGateway = softwareSystem "Platform Gateway" "Gateway API-based ingress routing HTTPRoute traffic to component services" "External"

        # Relationships - People
        datascientist -> kubeRbacProxy "Accesses component endpoints via" "HTTPS/8443, Bearer Token or OIDC JWT"
        sre -> prometheus "Monitors via"

        # Relationships - Primary flows
        kubeRbacProxy -> k8sApiServer "Authenticates tokens via TokenReview" "HTTPS/443, SA token"
        kubeRbacProxy -> k8sApiServer "Authorizes requests via SubjectAccessReview" "HTTPS/443, SA token"
        kubeRbacProxy -> upstreamApp "Proxies authenticated requests to" "HTTP/HTTPS/h2c, configurable"
        kubeRbacProxy -> oidcIssuer "Retrieves JWKS for JWT validation" "HTTPS/443, public endpoint"

        # Relationships - Supporting flows
        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443, Bearer Token (hardcoded allow)"
        platformGateway -> kubeRbacProxy "Routes external traffic to" "HTTPS/8443, TLS 1.2+"
        rhodsOperator -> kubeRbacProxy "Injects sidecar container into pod specs"
        certManager -> kubeRbacProxy "Provisions TLS cert/key pair"

        # Container-level relationships
        secureListener -> delegatingAuth "Passes request for token authentication"
        secureListener -> oidcAuth "Passes request for OIDC authentication"
        secureListener -> x509Auth "Passes request for certificate authentication"
        delegatingAuth -> hardcodedAuthz "Passes authenticated identity"
        oidcAuth -> hardcodedAuthz "Passes authenticated identity"
        x509Auth -> hardcodedAuthz "Passes authenticated identity"
        hardcodedAuthz -> staticAuthz "Chains to static rules"
        staticAuthz -> sarAuthz "Chains to SAR check"
        sarAuthz -> reverseProxy "Authorized request"
        hardcodedAuthz -> reverseProxy "Auto-allowed (prometheus-k8s)"
        delegatingAuth -> k8sApiServer "POST TokenReview" "HTTPS/443"
        oidcAuth -> oidcIssuer "GET JWKS" "HTTPS/443"
        sarAuthz -> k8sApiServer "POST SubjectAccessReview" "HTTPS/443"
        reverseProxy -> upstreamApp "Forward request" "HTTP/HTTPS/h2c"
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
                shape person
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
