workspace {
    model {
        user = person "User / Data Scientist" "Accesses RHOAI components via browser or API client"
        prometheus = person "Prometheus" "Scrapes metrics from RHOAI components" "Service Account"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication and authorization reverse proxy for RHOAI" {
            entrypoint = container "entrypoint" "Runtime binary selector, dispatches to auth or rbac mode based on PROXY_MODE" "Go CLI"
            authProxy = container "kube-auth-proxy" "Authentication proxy supporting OIDC, OpenShift OAuth, JWT Bearer, K8s SA tokens. Session management via cookie or Redis." "Go Service" "4180/TCP HTTP, 443/TCP HTTPS"
            rbacProxy = container "kube-rbac-proxy" "Authorization proxy using TokenReview + SubjectAccessReview. Union authorizer with caching." "Go Service" "8443/TCP HTTPS"
        }

        oidcProvider = softwareSystem "OIDC Provider" "External OpenID Connect identity provider (Keycloak, Azure AD, etc.)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift platform built-in OAuth2 authentication" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "TokenReview, SubjectAccessReview, OAuthAccessToken management" "External"
        redis = softwareSystem "Redis" "Optional distributed session storage (Standalone, Sentinel, or Cluster)" "External"
        envoyProxy = softwareSystem "Envoy Gateway" "Gateway API data plane, uses ext_authz for authentication decisions" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys kube-auth-proxy as sidecar containers" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "RHOAI component (Dashboard, Model Registry, etc.) protected by the proxy" "Internal RHOAI"

        # User interactions
        user -> kubeAuthProxy "Authenticates via OIDC/OAuth flow or Bearer token" "HTTPS/443, HTTP/4180"
        user -> envoyProxy "Accesses RHOAI applications" "HTTPS/443"

        # Internal flows
        envoyProxy -> authProxy "ext_authz subrequest to validate authentication" "HTTP/4180"
        entrypoint -> authProxy "Dispatches when PROXY_MODE=auth" "Process exec"
        entrypoint -> rbacProxy "Dispatches when PROXY_MODE=rbac (default)" "Process exec"
        authProxy -> upstreamApp "Forwards authenticated requests with identity headers" "HTTP/HTTPS"
        rbacProxy -> upstreamApp "Forwards authorized requests with identity headers" "HTTP/HTTPS/h2c"

        # External dependencies
        authProxy -> oidcProvider "OAuth2 authorization, token exchange, JWKS verification" "HTTPS/443"
        authProxy -> openshiftOAuth "OpenShift OAuth2 token exchange, user info" "HTTPS/443"
        authProxy -> k8sAPI "TokenReview for K8s SA token validation, OAuthAccessToken deletion" "HTTPS/443"
        authProxy -> redis "Store/retrieve encrypted sessions (AES-GCM)" "Redis/6379"
        rbacProxy -> k8sAPI "TokenReview (authentication) and SubjectAccessReview (authorization)" "HTTPS/443"

        # Operator deploys
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar container in component pods" "Kubernetes API"

        # Prometheus scraping
        prometheus -> rbacProxy "Scrapes /metrics (hardcoded allow for prometheus-k8s SA)" "HTTPS/8443"
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
            element "Service Account" {
                shape robot
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
