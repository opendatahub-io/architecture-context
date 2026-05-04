workspace {
    model {
        user = person "Data Scientist / Platform User" "Accesses RHOAI components via browser or API"
        prometheus = person "Prometheus" "OpenShift monitoring service account" "Service Account"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication and authorization reverse proxy for RHOAI components" {
            entrypoint = container "entrypoint" "Runtime binary selector - dispatches to auth or rbac mode based on PROXY_MODE" "Go CLI"
            authProxy = container "kube-auth-proxy" "Authentication proxy supporting OIDC and OpenShift OAuth, with session management and upstream proxying" "Go Service" {
                oauthHandler = component "OAuth2 Handler" "Handles /oauth2/* endpoints (sign_in, start, callback, sign_out, userinfo, auth)" "HTTP Handler"
                sessionManager = component "Session Manager" "Cookie-based or Redis-based session storage with AES encryption" "Middleware"
                middlewareChain = component "Middleware Chain" "Request processing: scope -> health -> metrics -> session -> headers -> proxy" "alice middleware"
                upstreamProxy = component "Upstream Proxy" "Reverse proxy to upstream application with header injection" "HTTP Reverse Proxy"
            }
            rbacProxy = container "kube-rbac-proxy" "Kubernetes RBAC authorization proxy using SubjectAccessReview for access control" "Go Service" {
                tokenReviewAuth = component "TokenReview Authenticator" "Validates bearer tokens via Kubernetes TokenReview API" "Authenticator"
                sarAuthorizer = component "SAR Authorizer" "SubjectAccessReview-based authorization with caching (5m pos, 30s neg)" "Authorizer"
                hardcodedAuth = component "Hardcoded Authorizer" "Allows Prometheus SA to GET /metrics without SAR" "Authorizer"
                staticAuth = component "Static Authorizer" "Pattern-based authorization rules from YAML config" "Authorizer"
            }
        }

        oidcProvider = softwareSystem "OIDC Provider" "External identity provider (Keycloak, Azure AD, etc.)" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift's built-in OAuth authentication system" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview and SubjectAccessReview" "External"
        redis = softwareSystem "Redis" "Optional distributed session storage (Standalone/Sentinel/Cluster)" "External"
        envoyGateway = softwareSystem "Envoy Gateway" "Gateway API data plane for ingress traffic routing" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys kube-auth-proxy as sidecar" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "RHOAI component (Dashboard, Notebook, etc.) being protected" "Internal RHOAI"

        # User interactions
        user -> kubeAuthProxy "Authenticates via browser (OIDC/OAuth) or API (Bearer/SA token)"
        prometheus -> kubeAuthProxy "Scrapes /metrics endpoint (hardcoded allow)" "HTTPS/8443"

        # Entrypoint dispatch
        entrypoint -> authProxy "Dispatches when PROXY_MODE=auth"
        entrypoint -> rbacProxy "Dispatches when PROXY_MODE=rbac (default)"

        # Auth mode dependencies
        authProxy -> oidcProvider "OIDC token exchange, JWKS verification, end_session" "HTTPS/443"
        authProxy -> openshiftOAuth "OAuth token exchange, user info" "HTTPS/443"
        authProxy -> k8sAPI "TokenReview for K8s SA token validation" "HTTPS/443"
        authProxy -> redis "Session storage and retrieval" "Redis/6379"
        authProxy -> upstreamApp "Proxies authenticated requests with injected headers" "HTTP/HTTPS"

        # RBAC mode dependencies
        rbacProxy -> k8sAPI "TokenReview (authn) and SubjectAccessReview (authz)" "HTTPS/443"
        rbacProxy -> upstreamApp "Proxies authorized requests with identity headers" "HTTP/HTTPS/h2c"

        # External integrations
        envoyGateway -> authProxy "ext_authz subrequests for Gateway API traffic" "HTTP/4180"
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar container in component pods" "K8s API"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Service Account" {
                shape Robot
            }
        }
    }
}
