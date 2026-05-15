workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models, accesses RHOAI services"
        sre = person "SRE / Platform Admin" "Manages RHOAI platform, monitors components"
        servicepod = person "Service / Pod" "Internal service making API calls with K8s SA tokens"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant dual-mode authentication/authorization reverse proxy sidecar for RHOAI" {
            entrypoint = container "entrypoint" "Runtime mode selector dispatching to auth or RBAC proxy" "Go Binary"
            authProxy = container "kube-auth-proxy" "OIDC/OpenShift OAuth authentication proxy with session management" "Go Service" {
                authChain = component "Authentication Chain" "Multi-tier authn: K8s TokenReview, OpenShift OAuth, JWT, Basic Auth, Sessions" "Go Middleware"
                sessionMgmt = component "Session Manager" "Cookie (AES-CFB/GCM encrypted) or Redis-backed sessions" "Go Service"
                oauthFlow = component "OAuth2 Flow Handler" "Handles /oauth2/* endpoints for sign-in, callback, sign-out" "Go HTTP Handler"
                upstreamProxy = component "Upstream Proxy" "Reverse proxy to upstream with identity header injection" "Go HTTP Handler"
            }
            rbacProxy = container "kube-rbac-proxy" "Kubernetes RBAC authorization proxy using SubjectAccessReview" "Go Service" {
                delegatingAuthn = component "Delegating Authenticator" "Token validation via K8s API TokenReview" "Go Middleware"
                unionAuthz = component "Union Authorizer" "3-tier: hardcoded Prometheus SA, static rules, SAR" "Go Middleware"
                rbacUpstream = component "Upstream Proxy" "Reverse proxy to upstream after authorization" "Go HTTP Handler"
            }
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Core cluster API for authentication and authorization" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift-native OAuth2 provider for cluster SSO" "External"
        openshiftUserAPI = softwareSystem "OpenShift User API" "User metadata enrichment (name, email, groups)" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External OpenID Connect identity provider (e.g., Keycloak, Azure AD)" "External"
        redis = softwareSystem "Redis" "Optional server-side session storage with distributed locking" "External"
        rhoaiComponents = softwareSystem "RHOAI Component Services" "Upstream services protected by the proxy sidecar" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Cluster monitoring and metrics collection" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys and configures the sidecar" "Internal RHOAI"
        envoy = softwareSystem "Envoy / Service Mesh" "Service mesh with ext_authz integration" "External"

        # Person interactions
        datascientist -> kubeAuthProxy "Authenticates via OIDC/OAuth to access RHOAI services" "HTTPS/4180"
        sre -> prometheus "Monitors proxy metrics"
        servicepod -> kubeAuthProxy "Authenticates with K8s SA token" "HTTPS/8443"

        # Internal flows
        entrypoint -> authProxy "Dispatches (PROXY_MODE=auth)"
        entrypoint -> rbacProxy "Dispatches (PROXY_MODE=rbac, default)"

        # Auth mode dependencies
        authProxy -> oidcProvider "OIDC discovery, JWKS, token exchange" "HTTPS/443"
        authProxy -> openshiftOAuth "OAuth discovery, token exchange" "HTTPS/443"
        authProxy -> openshiftUserAPI "User info enrichment, token revocation" "HTTPS/443"
        authProxy -> k8sApi "TokenReview for K8s SA tokens" "HTTPS/443"
        authProxy -> redis "Session storage and distributed locking" "TCP/6379"
        authProxy -> rhoaiComponents "Forward authenticated requests with identity headers" "HTTP/HTTPS"

        # RBAC mode dependencies
        rbacProxy -> k8sApi "TokenReview (authn) + SubjectAccessReview (authz)" "HTTPS/443"
        rbacProxy -> rhoaiComponents "Forward authorized requests" "HTTP/HTTPS/H2C"

        # Monitoring
        prometheus -> rbacProxy "Scrape metrics (hardcoded SA allowlist)" "HTTPS"

        # Deployment
        rhodsOperator -> kubeAuthProxy "Deploys as sidecar, configures RBAC and secrets"

        # ext_authz
        envoy -> authProxy "External authorization check via /oauth2/auth" "HTTP/4180"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
