workspace {
    model {
        user = person "End User / Data Scientist" "Accesses RHOAI platform components via browser or API client"
        sre = person "SRE / Platform Admin" "Monitors and operates RHOAI platform"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication and authorization reverse proxy shipping two binaries (OAuth2/OIDC + RBAC/SAR) in a single container image for securing RHOAI components" {
            entrypoint = container "entrypoint" "Mode selector binary; execs auth or rbac proxy based on PROXY_MODE env var" "Go Binary"
            authProxy = container "kube-auth-proxy" "OAuth2/OIDC authentication proxy with session management, Envoy ext_authz support, and upstream proxying" "Go Service" {
                oauthHandler = component "OAuth2 Handler" "Manages OAuth2/OIDC login flows with PKCE and CSRF protection" "Go"
                sessionManager = component "Session Manager" "Cookie-based or Redis-backed session storage with AES-GCM encryption" "Go"
                middlewareChain = component "Middleware Chain" "Pre-auth → session loading → header injection → upstream proxy" "Go"
                extAuthz = component "ext_authz Endpoint" "/oauth2/auth endpoint returning 202/401 for Envoy integration" "Go"
            }
            rbacProxy = container "kube-rbac-proxy" "RBAC authorization proxy validating tokens via TokenReview and enforcing permissions via SubjectAccessReview" "Go Service" {
                tokenAuth = component "Token Authenticator" "Validates bearer tokens via K8s TokenReview or OIDC JWT verification" "Go"
                sarAuthorizer = component "SAR Authorizer" "Checks Kubernetes RBAC permissions via SubjectAccessReview API" "Go"
                certReloader = component "TLS Cert Reloader" "Hot-reloads TLS certificates without restart" "Go"
                metricsAuth = component "Hardcoded Authorizer" "Allows prometheus-k8s SA to scrape /metrics without SAR check" "Go"
            }
        }

        rhoaiComponent = softwareSystem "RHOAI Component Pod" "Backend application secured by kube-auth-proxy sidecar (e.g., Dashboard, Model Registry)" "Internal RHOAI"
        envoyGateway = softwareSystem "Envoy Proxy / Gateway API" "RHOAI ingress gateway that delegates authentication via ext_authz" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys kube-auth-proxy as a sidecar" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API Server" "Provides TokenReview and SubjectAccessReview APIs" "External"
        oidcProvider = softwareSystem "OIDC Provider (Keycloak)" "Identity provider for OAuth2/OIDC authentication flows" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift-native OAuth authentication and token management" "External"
        redis = softwareSystem "Redis" "Optional distributed session storage backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from openshift-monitoring namespace" "External"

        # User interactions
        user -> envoyGateway "Accesses RHOAI applications" "HTTPS/443"
        user -> kubeAuthProxy "Authenticates via OAuth2 flow or sends bearer token" "HTTPS/8443"
        sre -> prometheus "Views metrics and alerts" "HTTPS"

        # Internal flows
        envoyGateway -> authProxy "Delegates auth via ext_authz" "HTTP/8080"
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar container" "N/A"
        authProxy -> rhoaiComponent "Proxies authenticated requests with identity headers" "HTTP/HTTPS"
        rbacProxy -> rhoaiComponent "Proxies authorized requests with identity headers" "HTTP/HTTPS/H2C"

        # External dependencies
        authProxy -> oidcProvider "Token exchange, JWKS retrieval, OIDC discovery" "HTTPS/443"
        authProxy -> openshiftOAuth "OAuth flow, OAuthAccessToken management" "HTTPS/443"
        authProxy -> k8sAPI "TokenReview for K8s token validation" "HTTPS/443"
        authProxy -> redis "Session storage and retrieval" "TCP/6379"
        rbacProxy -> k8sAPI "TokenReview and SubjectAccessReview" "HTTPS/443"
        rbacProxy -> oidcProvider "JWKS retrieval for JWT validation" "HTTPS/443"
        prometheus -> rbacProxy "Scrapes /metrics endpoint" "HTTPS/8443"

        # Entrypoint routing
        entrypoint -> authProxy "Execs when PROXY_MODE=auth"
        entrypoint -> rbacProxy "Execs when PROXY_MODE=rbac (default)"
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

        component authProxy "AuthProxyComponents" {
            include *
            autoLayout
        }

        component rbacProxy "RBACProxyComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
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
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
        }
    }
}
