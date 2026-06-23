workspace {
    model {
        datascientist = person "Data Scientist" "Uses browser to access RHOAI platform services"
        mlEngineer = person "ML Engineer" "Uses CLI/API with bearer tokens to access RHOAI services"
        serviceAccount = person "Service Account" "Kubernetes service account accessing RHOAI services programmatically"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant reverse proxy providing OIDC and OpenShift OAuth authentication for upstream RHOAI services" {
            httpServer = container "HTTP/HTTPS Server" "Listens on 4180/TCP (HTTP) or 443/TCP (HTTPS) with configurable TLS 1.2+" "Go net/http"
            oauthProxy = container "OAuthProxy Core" "Routes requests through authentication middleware chain, manages OAuth flows" "Go"
            sessionChain = container "Session Chain" "Layered middleware: K8s TokenReview → Bearer Token → Stored Session" "Go middleware"
            oidcProvider = container "OIDC Provider Handler" "Handles OIDC discovery, token exchange, JWT verification via JWKS" "Go (coreos/go-oidc)"
            openshiftProvider = container "OpenShift Provider Handler" "Handles OpenShift OAuth flow, endpoint auto-discovery, User API enrichment" "Go"
            authDenyHandler = container "Auth Deny Handler" "Protocol-aware error responses including MLflow SDK JSON errors" "Go"
            metricsServer = container "Metrics Server" "Prometheus metrics exposition" "Go (prometheus/client_golang)"
        }

        oidcIdP = softwareSystem "OIDC Identity Provider" "External OIDC provider (Keycloak, DEX) for user authentication" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift-native OAuth2 server for cluster authentication" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview validation and OAuth endpoint discovery" "External"
        openshiftUserAPI = softwareSystem "OpenShift User API" "Provides user info enrichment (username, email, groups)" "External"
        openshiftTokenAPI = softwareSystem "OpenShift OAuthAccessToken API" "Manages OAuth access token lifecycle (deletion on sign-out)" "External"
        upstreamService = softwareSystem "Upstream Application Service" "RHOAI platform component receiving authenticated requests" "Internal RHOAI"
        envoyProxy = softwareSystem "Envoy Proxy" "Service mesh proxy using ext_authz for external authorization" "Internal RHOAI"
        redis = softwareSystem "Redis" "Optional session state persistence for multi-replica deployments" "External"

        # User interactions
        datascientist -> kubeAuthProxy "Authenticates via browser OAuth2/OIDC flow" "HTTPS/443"
        mlEngineer -> kubeAuthProxy "Authenticates via bearer token (JWT, sha256~ token)" "HTTPS/443"
        serviceAccount -> kubeAuthProxy "Authenticates via K8s service account token" "HTTPS/443"

        # Envoy integration
        envoyProxy -> kubeAuthProxy "ext_authz subrequest to /oauth2/auth" "HTTP/4180"

        # Proxy → Identity Providers
        kubeAuthProxy -> oidcIdP "OIDC discovery, token exchange, JWKS retrieval, token refresh" "HTTPS/443"
        kubeAuthProxy -> openshiftOAuth "OAuth endpoint discovery, authorization code exchange" "HTTPS/443"

        # Proxy → Kubernetes APIs
        kubeAuthProxy -> k8sAPI "TokenReview validation for K8s SA tokens" "HTTPS/443"
        kubeAuthProxy -> openshiftUserAPI "User info enrichment via /apis/user.openshift.io/v1/users/~" "HTTPS/443"
        kubeAuthProxy -> openshiftTokenAPI "OAuthAccessToken deletion on sign-out" "HTTPS/443"

        # Proxy → Upstream
        kubeAuthProxy -> upstreamService "Forward authenticated requests with identity headers" "HTTP/HTTPS"

        # Proxy → Redis
        kubeAuthProxy -> redis "Session storage and retrieval (optional)" "Redis/6379"
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
                background #5b9bd5
                color #ffffff
            }
        }
    }
}
