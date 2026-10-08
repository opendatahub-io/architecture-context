workspace {
    model {
        user = person "User" "Data scientist, developer, or API client authenticating to RHOAI services"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy for RHOAI with OIDC, OpenShift OAuth, and K8s TokenReview support" {
            oauthProxy = container "OAuthProxy Engine" "Core proxy engine managing middleware chains, session stores, and upstream forwarding" "Go Service"
            tokenReviewValidator = container "TokenReviewValidator" "Validates Kubernetes service account tokens with SHA-256 caching and singleflight deduplication" "Go Component"
            oidcProvider = container "OIDC Provider" "OIDC authentication with PKCE and RP-Initiated Logout" "Go Provider"
            openShiftProvider = container "OpenShift Provider" "OpenShift OAuth with auto-discovery via .well-known" "Go Provider"
            sessionStore = container "Session Store" "Cookie-based or Redis-backed session management" "Go Component"
            mlflowHandler = container "MLflow AuthDeny Handler" "Custom JSON error responses for MLflow Python SDK" "Go Handler"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview validation" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift built-in OAuth service for user authentication" "External"
        oidcIdP = softwareSystem "OIDC Identity Provider" "External OIDC provider for user authentication" "External"
        redis = softwareSystem "Redis / Valkey" "External session storage for horizontal scaling" "External"
        upstream = softwareSystem "Upstream Application" "Protected application receiving authenticated requests" "Internal RHOAI"
        envoyProxy = softwareSystem "Envoy Proxy" "Service mesh / Gateway API ingress using ext_authz" "Internal RHOAI"
        mlflowSDK = softwareSystem "MLflow Python SDK" "ML experiment tracking client" "Internal RHOAI"

        # External relationships
        user -> kubeAuthProxy "Authenticates via browser or API client" "HTTPS/443"
        envoyProxy -> kubeAuthProxy "ext_authz check" "HTTP/4180"
        mlflowSDK -> kubeAuthProxy "API requests with auth" "HTTP/4180"

        # Internal relationships
        oauthProxy -> tokenReviewValidator "Validates SA tokens"
        oauthProxy -> oidcProvider "Delegates OIDC auth"
        oauthProxy -> openShiftProvider "Delegates OpenShift OAuth"
        oauthProxy -> sessionStore "Manages sessions"
        oauthProxy -> mlflowHandler "Handles MLflow auth denial"

        # Outbound relationships
        kubeAuthProxy -> k8sAPI "TokenReview API" "HTTPS/6443"
        kubeAuthProxy -> openShiftOAuth "OAuth2 flow (discovery, token exchange, userinfo)" "HTTPS/443"
        kubeAuthProxy -> oidcIdP "OIDC flow (discovery, token exchange, JWKS, userinfo)" "HTTPS/443"
        kubeAuthProxy -> redis "Session storage" "TCP/configurable"
        kubeAuthProxy -> upstream "Forward authenticated requests with identity headers" "HTTP(S)/configurable"
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
