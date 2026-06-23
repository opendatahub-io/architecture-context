workspace {
    model {
        // Users / Actors
        datascientist = person "Data Scientist" "Accesses RHOAI components via browser"
        mlflowclient = person "MLflow SDK Client" "Programmatic ML experiment tracking via Python SDK"
        k8sclient = person "K8s Service Account" "Automated workloads authenticating via SA tokens"

        // Main system
        kubeauthproxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy supporting OIDC and OpenShift OAuth for RHOAI component sidecars" {
            middlewareChain = container "Middleware Chain" "Request processing pipeline: logging, health, metrics, HTTPS redirect" "Go (justinas/alice)"
            sessionLoader = container "Session Loader" "Loads sessions from K8s SA tokens, JWT/OAuth bearers, basic auth, or stored cookies" "Go Middleware"
            oidcProvider = container "OIDC Provider" "Standard OIDC authentication with discovery, JWKS verification, PKCE, and token refresh" "Go Module (pkg/providers/oidc/)"
            openshiftProvider = container "OpenShift OAuth Provider" "OpenShift-native OAuth2 with auto-discovery and OAuthAccessToken cleanup" "Go Module (providers/openshift.go)"
            k8sTokenReview = container "K8s TokenReview Validator" "Validates Kubernetes service account tokens via TokenReview API" "Go Module (pkg/authentication/k8s/)"
            cookieStore = container "Cookie Session Store" "Client-side encrypted sessions using AES-GCM + HMAC with auto cookie splitting" "Go Module (pkg/sessions/cookie/)"
            redisStore = container "Redis Session Store" "Server-side session persistence with distributed lock for token refresh" "Go Module (pkg/sessions/redis/)"
            upstreamProxy = container "Upstream Proxy" "HTTP/HTTPS/Unix/WebSocket reverse proxy with identity header injection" "Go Module (pkg/upstream/)"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint (requests_total, in_flight, response_duration)" "Go Module (pkg/middleware/)"
            mlflowHandler = container "MLflow Auth Denied Handler" "Custom JSON error responses for MLflow Python SDK authentication failures" "Go Module (pkg/authdeny/)"
        }

        // Internal RHOAI systems
        rhodsOperator = softwareSystem "rhods-operator" "Deploys kube-auth-proxy as sidecar in RHOAI component pods" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "Protected RHOAI component (e.g., Dashboard, MLflow, Notebook)" "Internal RHOAI"
        envoy = softwareSystem "Envoy (Service Mesh)" "Istio/OSSM sidecar performing ext_authz checks against kube-auth-proxy" "Internal RHOAI"

        // External systems
        oidcIdP = softwareSystem "OIDC Identity Provider" "External OIDC-compliant identity provider (e.g., Keycloak, Azure AD, Okta)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift cluster-internal OAuth2 server" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for TokenReview and user info" "External"
        redis = softwareSystem "Redis" "Optional server-side session store (standalone, Sentinel, or Cluster)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        // Relationships - Users to system
        datascientist -> kubeauthproxy "Authenticates via browser (OIDC/OpenShift OAuth)" "HTTPS/4180"
        mlflowclient -> kubeauthproxy "Authenticates via Python SDK (Bearer token)" "HTTP/4180"
        k8sclient -> kubeauthproxy "Authenticates via SA bearer token" "HTTP/4180"

        // Relationships - Internal
        rhodsOperator -> kubeauthproxy "Deploys as sidecar container with configuration"
        envoy -> kubeauthproxy "ext_authz subrequest to /oauth2/auth" "HTTP/4180"
        kubeauthproxy -> upstreamApp "Proxies authenticated requests with identity headers" "HTTP/configurable"

        // Relationships - External
        kubeauthproxy -> oidcIdP "OIDC discovery, authorization, token exchange, userinfo, logout" "HTTPS/443"
        kubeauthproxy -> openshiftOAuth "OAuth discovery, authorization, token exchange" "HTTPS/443"
        kubeauthproxy -> k8sAPI "TokenReview, user info, OAuthAccessToken cleanup" "HTTPS/443"
        kubeauthproxy -> redis "Session persistence and distributed locking" "Redis/6379"
        prometheus -> kubeauthproxy "Scrapes metrics" "HTTP/configurable"

        // Container relationships
        middlewareChain -> sessionLoader "Passes request through pipeline"
        sessionLoader -> oidcProvider "Delegates OIDC authentication"
        sessionLoader -> openshiftProvider "Delegates OpenShift OAuth authentication"
        sessionLoader -> k8sTokenReview "Validates K8s SA tokens"
        oidcProvider -> cookieStore "Stores/retrieves sessions"
        oidcProvider -> redisStore "Stores/retrieves sessions"
        openshiftProvider -> cookieStore "Stores/retrieves sessions"
        openshiftProvider -> redisStore "Stores/retrieves sessions"
        sessionLoader -> upstreamProxy "Forwards authenticated requests"
        upstreamProxy -> upstreamApp "Proxied request with X-Forwarded-* headers"
        mlflowHandler -> mlflowclient "Returns JSON error with guidance" "HTTP/4180"

        // External container relationships
        oidcProvider -> oidcIdP "OIDC flows" "HTTPS/443 TLS 1.2+"
        openshiftProvider -> openshiftOAuth "OAuth flows" "HTTPS/443 TLS 1.2+"
        k8sTokenReview -> k8sAPI "POST /api/v1/tokenreviews" "HTTPS/443 TLS 1.2+"
        openshiftProvider -> k8sAPI "User info + token cleanup" "HTTPS/443 TLS 1.2+"
        redisStore -> redis "Session R/W + distributed lock" "Redis/6379"
        metricsServer -> prometheus "Metrics exposition" "HTTP/configurable"
    }

    views {
        systemContext kubeauthproxy "SystemContext" {
            include *
            autoLayout
        }

        container kubeauthproxy "Containers" {
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
