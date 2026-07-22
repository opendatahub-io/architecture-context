workspace {
    model {
        datascientist = person "Data Scientist" "Uses notebooks and ML tools that are protected by auth proxy"
        apiClient = person "API Client" "Service or CLI making authenticated API calls (e.g., MLflow Python client)"
        k8sWorkload = person "K8s Workload" "In-cluster pod using ServiceAccount token for service-to-service auth"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy providing OIDC and OpenShift OAuth for RHOAI platform components" {
            proxyServer = container "Proxy Server" "Reverse proxy handling authentication flows, session management, and request forwarding" "Go HTTP Server (4180/TCP, 8443/TCP)"
            oidcModule = container "OIDC Provider Module" "Handles OpenID Connect flows with PKCE, JWT verification, JWKS caching" "Go Module"
            openshiftModule = container "OpenShift OAuth Module" "Handles OpenShift-native OAuth with SA auto-detection" "Go Module"
            k8sTokenValidator = container "K8s TokenReview Validator" "Validates Kubernetes SA tokens via TokenReview API" "Go Module"
            sessionCookie = container "Cookie Session Store" "Client-side sessions with CFB/GCM encryption, cookie splitting" "Go Module"
            sessionRedis = container "Redis Session Store" "Server-side sessions supporting Standalone, Sentinel, Cluster topologies" "Go Module"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint for request instrumentation" "Go HTTP Server"
            mlflowHandler = container "MLflow Auth Deny Handler" "Custom 401 handler returning JSON error guidance for MLflow clients" "Go Middleware"
        }

        oidcProvider = softwareSystem "OIDC Provider" "External identity provider (Keycloak, Dex, etc.)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift built-in OAuth service for user authentication" "External"
        openshiftUserAPI = softwareSystem "OpenShift User API" "OpenShift API for user identity validation" "External"
        k8sAPIServer = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview validation" "External"
        redis = softwareSystem "Redis" "Optional distributed session storage (standalone, Sentinel, cluster)" "External"
        envoyProxy = softwareSystem "Envoy Proxy" "RHOAI 3.x Gateway API ingress proxy using ext_authz" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "Backend service receiving proxied authenticated requests" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI operator that injects kube-auth-proxy as sidecar" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Controller that injects kube-auth-proxy sidecar for notebook pods" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        datascientist -> kubeAuthProxy "Authenticates via browser (OIDC/OpenShift OAuth)" "HTTPS/4180,8443"
        apiClient -> kubeAuthProxy "Sends API requests with Bearer token or Basic auth" "HTTPS/4180,8443"
        k8sWorkload -> kubeAuthProxy "Sends requests with SA Bearer token" "HTTP(S)/4180,8443"
        envoyProxy -> kubeAuthProxy "ext_authz check requests" "HTTP(S)/4180,8443"

        # Internal container relationships
        proxyServer -> oidcModule "Delegates OIDC authentication"
        proxyServer -> openshiftModule "Delegates OpenShift OAuth authentication"
        proxyServer -> k8sTokenValidator "Delegates K8s SA token validation"
        proxyServer -> sessionCookie "Stores/retrieves cookie sessions"
        proxyServer -> sessionRedis "Stores/retrieves Redis sessions"

        # Egress
        kubeAuthProxy -> oidcProvider "OIDC discovery, token exchange, JWKS, userinfo" "HTTPS/443"
        kubeAuthProxy -> openshiftOAuth "OAuth authorization, token exchange" "HTTPS/443"
        kubeAuthProxy -> openshiftUserAPI "User identity validation" "HTTPS/443"
        kubeAuthProxy -> k8sAPIServer "TokenReview API" "HTTPS/443"
        kubeAuthProxy -> redis "Session storage (optional)" "TCP-TLS/6379"
        kubeAuthProxy -> upstreamApp "Proxied authenticated requests with identity headers" "HTTP(S)/configurable"
        prometheus -> kubeAuthProxy "Scrapes metrics" "HTTP(S)/configurable"

        # Deployment
        rhodsOperator -> kubeAuthProxy "Injects as sidecar container" "Deployment"
        notebookController -> kubeAuthProxy "Injects as sidecar for notebooks" "Deployment"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
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
