workspace {
    model {
        datascientist = person "Data Scientist" "Uses ML tools and notebooks protected by kube-auth-proxy"
        apiuser = person "API Client / Automation" "Calls RHOAI APIs with bearer tokens (JWT, sha256~, K8s SA)"
        sre = person "SRE / Platform Admin" "Monitors and configures RHOAI platform"

        kubeauthproxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy for RHOAI. Supports OIDC, OpenShift OAuth, K8s SA token validation, and ext_authz." {
            middlewareChain = container "Middleware Chain" "Layered auth processing: Pre-Auth → Session Loaders → Header Injection" "Go Middleware"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated requests to upstream with injected identity headers" "Go HTTP Proxy"
            oauthEndpoints = container "OAuth2 Endpoints" "Handles /oauth2/start, /callback, /sign_in, /sign_out, /userinfo, /auth" "Go HTTP Handlers"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on a separate port" "Go HTTP Server"
        }

        oidcProvider = softwareSystem "OIDC Provider" "External identity provider (e.g., Keycloak) for OAuth2/OIDC authentication" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Built-in OpenShift OAuth for user authentication" "External"
        k8sAPIServer = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview and resource access" "External"
        openshiftAPI = softwareSystem "OpenShift API" "OpenShift-specific APIs for user info and OAuthAccessToken management" "External"
        upstreamApp = softwareSystem "Upstream Application" "Protected backend service (e.g., JupyterHub, MLflow, Dashboard)" "Internal RHOAI"
        redis = softwareSystem "Redis" "Optional external session store (standalone, Sentinel, or Cluster)" "External"
        envoyGateway = softwareSystem "Envoy Gateway" "RHOAI 3.x Gateway API ingress with ext_authz integration" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI operator that deploys and configures kube-auth-proxy as a sidecar" "Internal RHOAI"

        # User interactions
        datascientist -> kubeauthproxy "Authenticates via browser OAuth2 flow" "HTTPS/443"
        apiuser -> kubeauthproxy "Sends API requests with bearer tokens" "HTTPS/443"
        sre -> prometheus "Monitors proxy metrics" "HTTPS"

        # Envoy integration
        envoyGateway -> kubeauthproxy "Sends ext_authz subrequests to /oauth2/auth" "HTTP(S)/4180 or 443"

        # Upstream
        kubeauthproxy -> upstreamApp "Forwards authenticated requests with X-Forwarded-* headers" "HTTP/HTTPS/Unix"

        # Identity provider interactions
        kubeauthproxy -> oidcProvider "OAuth2 authorization code flow, JWKS, userinfo, token exchange" "HTTPS/443"
        kubeauthproxy -> openshiftOAuth "OAuth2 discovery, authorization code flow, token exchange" "HTTPS/443"

        # Kubernetes interactions
        kubeauthproxy -> k8sAPIServer "TokenReview API for K8s SA token validation" "HTTPS/443"
        kubeauthproxy -> openshiftAPI "User info retrieval, OAuthAccessToken deletion on logout" "HTTPS/443"

        # Session store
        kubeauthproxy -> redis "Session persistence (optional)" "TCP/TLS 6379"

        # Observability
        prometheus -> kubeauthproxy "Scrapes /metrics endpoint" "HTTP(S)"

        # Deployment
        rhodsOperator -> kubeauthproxy "Deploys as sidecar, configures RBAC and secrets" "Kubernetes API"

        # Internal container relationships
        oauthEndpoints -> middlewareChain "Passes requests through auth chain"
        middlewareChain -> reverseProxy "Forwards authenticated requests"
        middlewareChain -> k8sAPIServer "TokenReview validation" "HTTPS/443"
        middlewareChain -> oidcProvider "JWT/OIDC token verification" "HTTPS/443"
        middlewareChain -> openshiftOAuth "sha256~ token verification" "HTTPS/443"
        middlewareChain -> redis "Session load/store" "TCP/TLS 6379"
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
            element "Software System" {
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
            element "Person" {
                shape Person
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
