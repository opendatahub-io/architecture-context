workspace {
    model {
        browserUser = person "Browser User" "Human user authenticating via OAuth2/OIDC for RHOAI platform access"
        serviceClient = person "Service Account Client" "Machine client using K8s SA tokens or certificates for API access"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant dual-mode authentication/authorization reverse proxy for RHOAI platform components" {
            entrypoint = container "entrypoint" "Mode dispatcher selecting auth or rbac proxy based on PROXY_MODE env" "Go CLI"
            authProxy = container "kube-auth-proxy" "OAuth2/OIDC authentication proxy with session management, cookie handling, and IdP integration" "Go Service" {
                tags "AuthMode"
            }
            rbacProxy = container "kube-rbac-proxy" "Kubernetes RBAC authorization proxy via SubjectAccessReview" "Go Service" {
                tags "RBACMode"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Provides TokenReview, SubjectAccessReview, and OpenShift API endpoints" "Platform" {
            tags "Internal"
        }
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider (Keycloak, DEX) for OIDC authentication flows" "External" {
            tags "External"
        }
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift-native OAuth2 authorization server for cluster users" "Platform" {
            tags "Internal"
        }
        redis = softwareSystem "Redis" "Optional session storage backend (alternative to cookie-based sessions)" "External" {
            tags "External"
        }
        upstreamApp = softwareSystem "Upstream Application" "Protected RHOAI platform component receiving authenticated traffic" "Internal RHOAI" {
            tags "Internal"
        }
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys kube-auth-proxy as sidecar container" "Internal RHOAI" {
            tags "Internal"
        }
        envoyGateway = softwareSystem "Envoy / Gateway API" "Ingress layer using ext_authz for external authorization" "Platform" {
            tags "Internal"
        }

        # Person relationships
        browserUser -> kubeAuthProxy "Authenticates via OAuth2/OIDC browser flow" "HTTP/4180"
        serviceClient -> kubeAuthProxy "Authenticates via Bearer token or client cert" "HTTPS/8443"

        # System relationships
        kubeAuthProxy -> k8sAPI "TokenReview and SubjectAccessReview" "HTTPS/443 TLS 1.2+"
        kubeAuthProxy -> oidcProvider "OIDC discovery, token exchange, refresh" "HTTPS/443 TLS 1.2+"
        kubeAuthProxy -> openshiftOAuth "OAuth2 authorization code flow" "HTTPS/443 TLS 1.2+"
        kubeAuthProxy -> redis "Session storage (optional)" "TCP/6379"
        kubeAuthProxy -> upstreamApp "Proxies authenticated requests with identity headers" "HTTP/HTTPS configurable"
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar container in component pods"
        envoyGateway -> kubeAuthProxy "ext_authz subrequest to /oauth2/auth" "HTTP/4180"

        # Container relationships
        entrypoint -> authProxy "Exec (PROXY_MODE=auth)"
        entrypoint -> rbacProxy "Exec (PROXY_MODE=rbac, default)"
        authProxy -> k8sAPI "TokenReview API" "HTTPS/443"
        authProxy -> oidcProvider "OIDC flows" "HTTPS/443"
        authProxy -> openshiftOAuth "OAuth2 flows" "HTTPS/443"
        authProxy -> redis "Session read/write" "TCP/6379"
        authProxy -> upstreamApp "Proxied requests" "HTTP/HTTPS"
        rbacProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        rbacProxy -> upstreamApp "Proxied requests" "HTTP/HTTPS"
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
            element "Internal" {
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
