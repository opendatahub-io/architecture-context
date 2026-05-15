workspace {
    model {
        # Actors
        serviceClient = person "Service Client" "In-cluster service or external client making API/metrics requests"
        platformAdmin = person "Platform Admin" "Configures RHOAI components and RBAC policies"

        # Primary system
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP/HTTPS reverse proxy sidecar that enforces Kubernetes RBAC authorization via TokenReview and SubjectAccessReview" {
            secureListener = container "Secure Listener" "TLS-terminated HTTPS listener on port 8443" "Go net/http + crypto/tls"
            authNModule = container "Authentication Module" "Authenticates requests via TokenReview, X.509 client certs, or OIDC JWT" "Go (pkg/authn)"
            authZModule = container "Authorization Module" "Authorizes requests via SubjectAccessReview with Format1/Format2 config; hardcoded allow for Prometheus SA" "Go (pkg/authz)"
            middlewareChain = container "HTTP Middleware Chain" "Composes path filtering, authentication, authorization, and header injection" "Go (pkg/filters)"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream application" "Go net/http/httputil"
            tlsReloader = container "TLS Certificate Reloader" "Hot-reloads TLS certificates from disk on configurable interval" "Go (pkg/tls)"
            logSanitizer = container "Log Sanitizer" "Masks bearer tokens in TokenReview log entries to prevent credential leakage" "Go (cmd/app)"
        }

        # External systems
        k8sApiServer = softwareSystem "Kubernetes API Server" "Provides TokenReview and SubjectAccessReview APIs for authentication and authorization" "External"
        oidcProvider = softwareSystem "OIDC Provider" "Provides OIDC discovery and JWKS endpoints for JWT validation (e.g., Keycloak, Dex)" "External Optional"
        upstreamApp = softwareSystem "Upstream Application" "Application container in the same pod receiving proxied requests (metrics, APIs)" "Internal Pod"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Cluster monitoring that scrapes /metrics endpoints; SA: prometheus-k8s" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy as sidecar and configures RBAC" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Provisions and auto-rotates TLS certificates for the proxy" "External"

        # Relationships - external
        serviceClient -> kubeRbacProxy "Sends API/metrics requests" "HTTPS/8443 TLS 1.2+ (Bearer/mTLS/OIDC)"
        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443 TLS 1.2+ (Bearer Token, hardcoded allow)"
        kubeRbacProxy -> k8sApiServer "Authenticates tokens (TokenReview) and authorizes requests (SubjectAccessReview)" "HTTPS/443 TLS 1.2+ (SA Token)"
        kubeRbacProxy -> oidcProvider "Validates OIDC JWT tokens (discovery + JWKS)" "HTTPS/443 TLS 1.2+"
        kubeRbacProxy -> upstreamApp "Forwards authenticated requests" "HTTP/8080 localhost (no encryption)"
        rhodsOperator -> kubeRbacProxy "Injects as sidecar container, configures authorization rules" "Container Injection"
        certManager -> kubeRbacProxy "Provisions TLS certificates" "File Mount"
        platformAdmin -> rhodsOperator "Configures RHOAI components" "kubectl / OLM"

        # Relationships - internal containers
        secureListener -> middlewareChain "Passes incoming requests"
        middlewareChain -> authNModule "Delegates authentication"
        middlewareChain -> authZModule "Delegates authorization"
        middlewareChain -> reverseProxy "Forwards authorized requests"
        authNModule -> k8sApiServer "TokenReview" "HTTPS/443"
        authNModule -> oidcProvider "OIDC Discovery + JWKS" "HTTPS/443"
        authZModule -> k8sApiServer "SubjectAccessReview" "HTTPS/443"
        reverseProxy -> upstreamApp "Proxies request" "HTTP/8080"
        tlsReloader -> secureListener "Provides hot-reloaded certificates"
    }

    views {
        systemContext kubeRbacProxy "SystemContext" {
            include *
            autoLayout
            description "System context showing kube-rbac-proxy in the RHOAI ecosystem"
        }

        container kubeRbacProxy "Containers" {
            include *
            autoLayout
            description "Internal container view of kube-rbac-proxy components"
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
            element "External Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal Pod" {
                background #27ae60
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            relationship "Relationship" {
                dashed false
            }
        }
    }
}
