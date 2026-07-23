workspace {
    model {
        datascientist = person "Data Scientist" "Uses RHOAI components for ML workflows"
        sreclient = person "SRE / Platform Admin" "Manages RHOAI platform and operations"
        mlclient = softwareSystem "ML Client" "Programmatic access (e.g., MLflow Python client, SDK scripts)" "External"
        envoy = softwareSystem "Envoy Proxy" "Service mesh sidecar or gateway performing ext_authz checks" "External"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy for RHOAI component sidecars. Supports OIDC, OpenShift OAuth, K8s TokenReview, and ext_authz." {
            router = container "HTTP Router" "gorilla/mux-based router handling OAuth2 endpoints and catch-all proxy" "Go (gorilla/mux)"
            middlewareChain = container "Auth Middleware Chain" "Ordered auth pipeline: K8s Token -> JWT -> OAuth -> Stored Session" "Go (alice middleware)"
            oidcProvider = container "OIDC Provider" "Handles OIDC authorization code flow with PKCE" "Go"
            openshiftProvider = container "OpenShift OAuth Provider" "Handles OpenShift OAuth with auto-detected SA credentials" "Go"
            sessionManager = container "Session Manager" "Cookie (AES-GCM) or Redis-backed session storage with distributed locking" "Go"
            proxyHandler = container "Reverse Proxy" "Forwards authenticated requests to upstream with identity headers" "Go"
            mlflowHandler = container "MLflow Deny Handler" "Returns structured JSON errors for MLflow Python clients" "Go"
        }

        oidcIdP = softwareSystem "OIDC Identity Provider" "External identity provider (Keycloak, Azure AD, etc.)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift's built-in OAuth service for user authentication" "Internal Platform"
        openshiftAPI = softwareSystem "OpenShift API" "User identity and OAuthAccessToken management APIs" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "TokenReview API for ServiceAccount token validation" "Internal Platform"
        redis = softwareSystem "Redis" "Optional distributed session storage (standalone, sentinel, or cluster)" "External"
        upstream = softwareSystem "Upstream Application" "RHOAI component being protected (e.g., MLflow, Dashboard)" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys kube-auth-proxy as a sidecar" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # User interactions
        datascientist -> kubeAuthProxy "Authenticates via browser (OIDC/OAuth redirect)" "HTTPS/443"
        sreclient -> kubeAuthProxy "Authenticates via browser or kubectl" "HTTPS/443"
        mlclient -> kubeAuthProxy "Authenticates via Bearer token (SA token or JWT)" "HTTPS/443"
        envoy -> kubeAuthProxy "ext_authz subrequest to /oauth2/auth" "HTTP(S)/4180"

        # Provider interactions
        kubeAuthProxy -> oidcIdP "OIDC Discovery, PKCE auth flow, JWKS verification" "HTTPS/443"
        kubeAuthProxy -> openshiftOAuth "OAuth discovery, authorization code exchange" "HTTPS/443"
        kubeAuthProxy -> openshiftAPI "User identity lookup, OAuthAccessToken deletion on sign-out" "HTTPS/443"
        kubeAuthProxy -> k8sAPI "TokenReview for SA token validation" "HTTPS/443"
        kubeAuthProxy -> redis "Session read/write/lock (optional)" "TCP(TLS)/6379"
        kubeAuthProxy -> upstream "Proxy authenticated requests with X-Forwarded-* headers" "HTTP/HTTPS"
        kubeAuthProxy -> prometheus "Expose /metrics endpoint" "HTTP(S)"

        # Operator deploys sidecar
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar container in component pods" "Kubernetes API"

        # Internal container relationships
        router -> middlewareChain "Routes requests through auth pipeline"
        middlewareChain -> oidcProvider "Delegates to OIDC for JWT verification"
        middlewareChain -> openshiftProvider "Delegates to OpenShift for OAuth token validation"
        middlewareChain -> sessionManager "Loads/stores sessions"
        middlewareChain -> proxyHandler "Forwards authenticated requests"
        router -> mlflowHandler "Routes MLflow client errors"
    }

    views {
        systemContext kubeAuthProxy "SystemContext" {
            include *
            autoLayout
        }

        container kubeAuthProxy "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
