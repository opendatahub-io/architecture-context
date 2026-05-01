workspace {
    model {
        browserUser = person "Browser User" "Human user accessing RHOAI platform components via browser"
        serviceClient = person "Service Account Client" "Machine-to-machine client using K8s service account tokens"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant dual-mode authentication/authorization reverse proxy for RHOAI platform components" {
            entrypoint = container "entrypoint" "Mode dispatcher that selects proxy binary based on PROXY_MODE env var" "Go CLI"
            authProxy = container "kube-auth-proxy (auth mode)" "OAuth2/OIDC authentication proxy with session management, cookie handling, and IdP integration" "Go Service" {
                tags "AuthMode"
            }
            rbacProxy = container "kube-rbac-proxy (rbac mode)" "Kubernetes RBAC authorization proxy via SubjectAccessReview for protecting metrics and API endpoints" "Go Service" {
                tags "RBACMode"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview and SubjectAccessReview" {
            tags "ClusterService"
        }
        osOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift native OAuth2 authorization server" {
            tags "ClusterService"
        }
        osUserAPI = softwareSystem "OpenShift User API" "OpenShift user identity service" {
            tags "ClusterService"
        }
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider (Keycloak, DEX)" {
            tags "External"
        }
        redis = softwareSystem "Redis" "Optional session storage backend" {
            tags "External"
        }
        upstreamApp = softwareSystem "Upstream Application" "Protected RHOAI platform component (e.g., Dashboard, Model Registry)" {
            tags "InternalRHOAI"
        }
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys kube-auth-proxy as sidecar" {
            tags "InternalRHOAI"
        }
        envoyGateway = softwareSystem "Envoy / Gateway API" "Ingress layer using ext_authz integration" {
            tags "InternalRHOAI"
        }

        # Person relationships
        browserUser -> kubeAuthProxy "Authenticates via OAuth2/OIDC flow" "HTTP/4180"
        serviceClient -> kubeAuthProxy "Authenticates via Bearer token" "HTTPS/8443"

        # Internal container relationships
        entrypoint -> authProxy "Dispatches (PROXY_MODE=auth)" "os.Exec"
        entrypoint -> rbacProxy "Dispatches (PROXY_MODE=rbac, default)" "os.Exec"

        # Auth mode dependencies
        authProxy -> oidcProvider "OIDC discovery, token exchange, userinfo, logout" "HTTPS/443"
        authProxy -> osOAuth "OAuth2 authorization code flow, token exchange" "HTTPS/443"
        authProxy -> osUserAPI "Retrieve user identity (name, email, groups)" "HTTPS/443"
        authProxy -> k8sAPI "TokenReview for K8s SA token validation" "HTTPS/443"
        authProxy -> redis "Session storage read/write" "TCP/6379"
        authProxy -> upstreamApp "Proxied authenticated requests with GAP-Auth header" "HTTP/HTTPS"

        # RBAC mode dependencies
        rbacProxy -> k8sAPI "TokenReview (authn) + SubjectAccessReview (authz)" "HTTPS/443"
        rbacProxy -> upstreamApp "Proxied authorized requests with x-remote-user header" "HTTP/HTTPS"

        # Operator relationship
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar container, provisions RBAC" "Deployment spec"

        # Envoy integration
        envoyGateway -> authProxy "ext_authz subrequest to /oauth2/auth" "HTTP/4180"
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
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "ClusterService" {
                background #5a9a3e
                color #ffffff
            }
            element "InternalRHOAI" {
                background #7ed321
                color #ffffff
            }
            element "AuthMode" {
                background #4a90e2
                color #ffffff
            }
            element "RBACMode" {
                background #2c6cb0
                color #ffffff
            }
        }
    }
}
