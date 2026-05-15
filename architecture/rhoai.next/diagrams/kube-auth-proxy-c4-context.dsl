workspace {
    model {
        browserUser = person "Browser User" "Data scientist or platform user accessing RHOAI components via browser"
        apiClient = person "API Client" "Automated client or service making API calls to RHOAI components"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "Dual-mode authentication reverse proxy sidecar for RHOAI platform components" {
            entrypoint = container "entrypoint" "Runtime mode selector that dispatches to auth or rbac proxy based on PROXY_MODE env var" "Go Binary"
            authProxy = container "kube-auth-proxy (auth mode)" "OAuth2/OIDC authentication proxy with session management, CSRF protection, multi-layer auth chain" "Go Reverse Proxy" {
                oauthHandler = component "OAuth2 Handler" "Manages OAuth2/OIDC authorization code flow with PKCE" "Go"
                sessionMgr = component "Session Manager" "Cookie-based (AES-CFB + HMAC-SHA256) or Redis-backed session storage" "Go"
                authChain = component "Auth Middleware Chain" "K8s TokenReview → OAuth Bearer → JWT Bearer → Basic Auth → Stored Session" "Go (alice)"
                csrfProtection = component "CSRF Protection" "PKCE code verifier (S256) + OIDC nonce + signed cookie (msgpack + AES)" "Go"
            }
            rbacProxy = container "kube-rbac-proxy (rbac mode)" "Kubernetes RBAC authorization proxy with TokenReview authn and SubjectAccessReview authz" "Go Reverse Proxy" {
                delegatingAuthn = component "Delegating Authenticator" "TokenReview, OIDC JWT, x509 client certificate authentication" "Go"
                authzChain = component "Authorization Chain" "Hardcoded metrics SA → Static YAML rules → SubjectAccessReview (cached)" "Go"
            }
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview, SubjectAccessReview, and OAuthAccessToken management" "External"
        oidcProvider = softwareSystem "OIDC / OpenShift OAuth Server" "Identity provider for user authentication via OAuth2/OIDC flows" "External"
        redis = softwareSystem "Redis" "Optional server-side session storage with distributed locking (standalone, Sentinel, Cluster)" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys kube-auth-proxy as sidecar and configures flags" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "The RHOAI component being protected by the proxy sidecar" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Prometheus" "Cluster monitoring that scrapes /metrics from kube-rbac-proxy" "External"
        envoyExtAuthz = softwareSystem "Envoy (ext_authz)" "Service mesh sidecar using /auth endpoint for external authorization checks" "External"

        # Relationships - Users
        browserUser -> kubeAuthProxy "Authenticates via OAuth2/OIDC flow" "HTTPS/4443 TLS 1.2+"
        apiClient -> kubeAuthProxy "Authenticates via Bearer token or client cert" "HTTPS/8443 TLS 1.2+"

        # Relationships - Internal
        entrypoint -> authProxy "Dispatches when PROXY_MODE=auth" "exec"
        entrypoint -> rbacProxy "Dispatches when PROXY_MODE=rbac (default)" "exec"
        authProxy -> upstreamApp "Proxies authenticated requests" "HTTP/HTTPS, GAP-Auth headers"
        rbacProxy -> upstreamApp "Proxies authorized requests" "HTTP/HTTPS/h2c, auth headers"

        # Relationships - External
        authProxy -> oidcProvider "OIDC discovery, authorization, token exchange, userinfo" "HTTPS/443"
        authProxy -> k8sApiServer "TokenReview for K8s token validation, OAuthAccessToken deletion" "HTTPS/443"
        authProxy -> redis "Session storage read/write/lock" "TCP/6379, TLS optional"
        rbacProxy -> k8sApiServer "TokenReview for authn, SubjectAccessReview for authz" "HTTPS/443"
        prometheus -> rbacProxy "Scrapes /metrics (hardcoded allow for Prometheus SA)" "HTTPS/8443"
        envoyExtAuthz -> authProxy "External authorization check (/auth → 202/401)" "HTTPS/4443"

        # Operator
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar, sets PROXY_MODE and configures auth flags" "Container injection"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
