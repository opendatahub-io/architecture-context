workspace {
    model {
        user = person "User" "Data scientist or developer accessing RHOAI applications via browser"
        apiClient = person "API Client" "Automated client (MLflow SDK, CI/CD) using service account tokens"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy providing OIDC, OpenShift OAuth, and K8s TokenReview authentication" {
            oauthProxy = container "OAuthProxy" "Core proxy engine with middleware chain: pre-auth, session, headers" "Go (gorilla/mux + alice)"
            tokenReviewValidator = container "TokenReviewValidator" "Validates K8s service account tokens via TokenReview API with singleflight dedup and TTL cache" "Go"
            openShiftProvider = container "OpenShiftProvider" "OpenShift OAuth provider with auto-discovery and custom CA support" "Go"
            oidcProvider = container "OIDCProvider" "Standards-compliant OIDC provider with ID token verification" "Go"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on dedicated bind address" "Go HTTP server"
            mlflowHandler = container "MLflow Auth Handler" "Returns structured JSON errors for unauthenticated MLflow SDK requests" "Go"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview validation" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift built-in OAuth service" "External"
        extOIDC = softwareSystem "External OIDC Provider" "External identity provider (Keycloak, Azure AD, etc.)" "External"
        redis = softwareSystem "Redis / Valkey" "Session storage backend for multi-replica deployments" "External"
        upstream = softwareSystem "Upstream Application" "Protected application (Dashboard, MLflow, Notebook, etc.)" "Internal RHOAI"
        envoy = softwareSystem "Envoy Proxy" "Gateway API ingress proxy using ext_authz" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        user -> kubeAuthProxy "Authenticates via browser OAuth2/OIDC flow" "HTTPS/443"
        apiClient -> kubeAuthProxy "Authenticates via K8s SA Bearer token" "HTTPS/443"
        envoy -> kubeAuthProxy "ext_authz subrequests for auth decisions" "HTTP/4180"

        oauthProxy -> tokenReviewValidator "Validates K8s SA tokens"
        oauthProxy -> openShiftProvider "OpenShift OAuth flows"
        oauthProxy -> oidcProvider "OIDC authentication flows"
        oauthProxy -> mlflowHandler "Delegates MLflow auth-denied responses"

        kubeAuthProxy -> k8sAPI "TokenReview API for SA token validation" "HTTPS/6443"
        kubeAuthProxy -> openshiftOAuth "OAuth2 discovery, authorize, token exchange" "HTTPS/443"
        kubeAuthProxy -> extOIDC "OIDC discovery, token exchange, JWKS" "HTTPS/443"
        kubeAuthProxy -> redis "Session storage (optional)" "TCP/configured"
        kubeAuthProxy -> upstream "Forward authenticated requests with identity headers" "HTTP/configured"
        prometheus -> kubeAuthProxy "Scrapes /metrics endpoint" "HTTP/configured"
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
