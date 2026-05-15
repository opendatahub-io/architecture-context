workspace {
    model {
        user = person "User / Data Scientist" "Accesses RHOAI platform components via browser"
        serviceClient = person "Service Client" "Internal service or gateway making API calls with K8s SA tokens"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant dual-mode authentication and authorization reverse proxy sidecar for RHOAI platform components" {
            entrypoint = container "entrypoint" "Multiplexer that selects proxy mode based on PROXY_MODE env var" "Go CLI"
            authProxy = container "kube-auth-proxy (auth mode)" "OAuth2/OIDC authentication proxy with session management, PKCE, and multi-method auth chain" "Go HTTP Reverse Proxy" {
                tags "AuthMode"
            }
            rbacProxy = container "kube-rbac-proxy (rbac mode)" "Kubernetes RBAC authorization proxy performing SubjectAccessReview on every request" "Go HTTP Reverse Proxy" {
                tags "RBACMode"
            }
        }

        upstreamApp = softwareSystem "Upstream Application" "RHOAI platform component being protected by the proxy sidecar" {
            tags "Internal RHOAI"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Provides TokenReview, SubjectAccessReview, and OAuthAccessToken APIs" {
            tags "Platform"
        }

        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for OAuth2/OIDC authentication flows" {
            tags "External"
        }

        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift-native OAuth2 authentication server" {
            tags "Platform"
        }

        redis = softwareSystem "Redis" "Optional distributed session storage backend" {
            tags "External"
        }

        rhoaiGateway = softwareSystem "RHOAI Gateway (Envoy)" "API gateway performing ext_authz checks and routing traffic to components" {
            tags "Internal RHOAI"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring system scraping metrics from kube-rbac-proxy" {
            tags "Platform"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys and configures kube-auth-proxy sidecars" {
            tags "Internal RHOAI"
        }

        # Relationships - User flows
        user -> rhoaiGateway "Accesses RHOAI components" "HTTPS/443"
        user -> authProxy "OAuth2/OIDC login flow" "HTTP/4180 or HTTPS/443"
        serviceClient -> rbacProxy "API calls with SA token" "HTTPS/8443"

        # Relationships - Gateway flows
        rhoaiGateway -> authProxy "ext_authz check" "HTTP/4180"
        rhoaiGateway -> rbacProxy "Forward with SA token" "HTTPS/8443"

        # Relationships - Internal
        entrypoint -> authProxy "Dispatches when PROXY_MODE=auth"
        entrypoint -> rbacProxy "Dispatches when PROXY_MODE=rbac (default)"
        authProxy -> upstreamApp "Proxies authenticated requests" "HTTP(S), X-Forwarded-User headers"
        rbacProxy -> upstreamApp "Proxies authorized requests" "HTTP(S)/h2c, x-remote-user headers"

        # Relationships - External dependencies
        authProxy -> k8sAPI "TokenReview, OAuthAccessToken deletion" "HTTPS/443"
        authProxy -> oidcProvider "OIDC discovery, token exchange, JWKS" "HTTPS/443"
        authProxy -> openshiftOAuth "OAuth2 flow, user info" "HTTPS/443"
        authProxy -> redis "Session storage (optional)" "TCP/6379"

        rbacProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        rbacProxy -> oidcProvider "JWKS retrieval (optional)" "HTTPS/443"

        prometheus -> rbacProxy "Scrapes /metrics" "HTTPS/8443"
        rhodsOperator -> kubeAuthProxy "Deploys and configures sidecar" "K8s API"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #666666
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "AuthMode" {
                background #4a90e2
                color #ffffff
            }
            element "RBACMode" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
