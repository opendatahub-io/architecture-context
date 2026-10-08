workspace {
    model {
        user = person "User / Data Scientist" "Accesses RHOAI applications via browser or CLI"
        mlflowClient = person "MLflow Python SDK" "Programmatic client accessing MLflow APIs"
        envoyProxy = softwareSystem "Envoy Proxy" "Service mesh sidecar for ext_authz integration" "External"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy for ODH/RHOAI" {
            oauthProxy = container "OAuthProxy" "Central engine orchestrating middleware chains, session management, and upstream proxying" "Go Service"
            tokenReviewValidator = container "TokenReviewValidator" "Validates K8s service account tokens via TokenReview API with singleflight dedup and TTL cache" "Go Module"
            openShiftProvider = container "OpenShiftProvider" "Handles OpenShift OAuth with auto-discovery, token lifecycle, and user info enrichment" "Go Module"
            oidcProvider = container "OIDCProvider" "Handles standard OIDC authentication with JWT verification" "Go Module"
            redisSessionStore = container "Redis SessionStore" "Optional external session storage for multi-replica deployments" "Go Module"
            metricsServer = container "Metrics Server" "Separate HTTP/HTTPS server exposing Prometheus metrics" "Go Service"
            mlflowAuthDeny = container "MLflow AuthDeny Handler" "Returns structured JSON error responses for MLflow SDK clients" "Go Module"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for TokenReview and resource access" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift built-in OAuth2 identity provider" "External"
        oidcProviderExt = softwareSystem "OIDC Provider" "External OIDC identity provider" "External"
        redis = softwareSystem "Redis / Valkey" "External session storage backend" "External"
        upstreamApp = softwareSystem "Upstream Application" "Protected RHOAI application receiving authenticated requests" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        user -> kubeAuthProxy "Authenticates via browser OAuth flow or Bearer token" "HTTPS/443"
        mlflowClient -> kubeAuthProxy "API requests with Bearer token or session cookie" "HTTPS/443"
        envoyProxy -> kubeAuthProxy "ext_authz subrequest to /oauth2/auth" "HTTP/4180"

        # Internal interactions
        oauthProxy -> tokenReviewValidator "Validates K8s SA tokens"
        oauthProxy -> openShiftProvider "Delegates OpenShift OAuth flows"
        oauthProxy -> oidcProvider "Delegates OIDC flows"
        oauthProxy -> redisSessionStore "Stores/retrieves sessions"
        oauthProxy -> mlflowAuthDeny "Routes denied MLflow requests"

        # External interactions
        kubeAuthProxy -> kubernetesAPI "TokenReview API for SA token validation" "HTTPS/6443"
        kubeAuthProxy -> openShiftOAuth "OAuth discovery, token redemption, user info" "HTTPS/6443"
        kubeAuthProxy -> oidcProviderExt "OIDC discovery, code redemption, JWK fetching" "HTTPS/443"
        kubeAuthProxy -> redis "Session storage and retrieval" "TCP/TLS"
        kubeAuthProxy -> upstreamApp "Forwards authenticated requests with identity headers" "HTTP/HTTPS"
        prometheus -> kubeAuthProxy "Scrapes /metrics endpoint" "HTTP"
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
