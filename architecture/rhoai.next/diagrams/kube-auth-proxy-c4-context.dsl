workspace {
    model {
        datascientist = person "Data Scientist" "Accesses RHOAI components via browser or API"
        sre = person "SRE / Platform Admin" "Monitors and manages the RHOAI platform"
        serviceaccount = person "Service Account" "Automated Kubernetes workload accessing protected endpoints"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication and authorization reverse proxy for RHOAI" {
            entrypoint = container "entrypoint" "Runtime binary selector, dispatches to auth or rbac mode based on PROXY_MODE" "Go CLI"
            authProxy = container "kube-auth-proxy" "Authentication proxy supporting OIDC, OpenShift OAuth, JWT bearer, K8s SA token validation, and session management" "Go Service, Port 4180/TCP"
            rbacProxy = container "kube-rbac-proxy" "Authorization proxy using TokenReview and SubjectAccessReview for RBAC enforcement" "Go Service, Port 8443/TCP"
            sessionManager = container "Session Manager" "Cookie-based (AES-CFB + HMAC-SHA256) or Redis-based (AES-GCM + ticket system) session storage" "Go Library"
        }

        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for OIDC authentication (BYOIDC)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift platform built-in OAuth authentication" "External"
        k8sApiServer = softwareSystem "Kubernetes API Server" "TokenReview (authn) and SubjectAccessReview (authz)" "External"
        redis = softwareSystem "Redis" "Optional distributed session storage (standalone, Sentinel, or Cluster)" "External"
        envoyProxy = softwareSystem "Envoy Proxy" "Gateway API data plane, uses ext_authz for auth decisions" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator, deploys kube-auth-proxy as sidecar" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "RHOAI component (e.g., Dashboard, Model Registry) protected by auth proxy" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Monitoring system, scrapes metrics from kube-rbac-proxy" "External"

        # User interactions
        datascientist -> kubeAuthProxy "Authenticates via OIDC/OAuth login flow" "HTTPS/443"
        sre -> kubeAuthProxy "Accesses metrics and monitoring endpoints" "HTTPS/8443"
        serviceaccount -> kubeAuthProxy "Authenticates via Bearer token (K8s SA or JWT)" "HTTPS/8443"

        # Internal container relationships
        entrypoint -> authProxy "Delegates when PROXY_MODE=auth"
        entrypoint -> rbacProxy "Delegates when PROXY_MODE=rbac (default)"
        authProxy -> sessionManager "Manages user sessions"

        # External dependencies
        authProxy -> oidcProvider "Token exchange, JWKS verification, end_session" "HTTPS/443, TLS 1.2+, OAuth2 client creds"
        authProxy -> openshiftOAuth "Token exchange, user info, token deletion" "HTTPS/443, TLS 1.2+, OAuth2 client creds"
        authProxy -> k8sApiServer "TokenReview for K8s SA token validation" "HTTPS/443, TLS 1.2+, SA token"
        authProxy -> redis "Store/retrieve sessions" "Redis/6379, Optional TLS"
        authProxy -> upstreamApp "Forward authenticated requests with identity headers" "HTTP/HTTPS, configurable"

        rbacProxy -> k8sApiServer "TokenReview (authn) + SubjectAccessReview (authz)" "HTTPS/443, TLS 1.2+, SA token"
        rbacProxy -> upstreamApp "Forward authorized requests with x-remote-user/groups headers" "HTTP/HTTPS/h2c"

        # Integration points
        envoyProxy -> authProxy "ext_authz subrequest to /oauth2/auth" "HTTP/4180"
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar in component pods" "Sidecar injection"
        prometheus -> rbacProxy "Scrapes /metrics (hardcoded allow for prometheus-k8s SA)" "HTTPS/8443"

        sessionManager -> redis "Persist sessions with distributed locking" "Redis/6379"
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
                background #4a90e2
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
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
