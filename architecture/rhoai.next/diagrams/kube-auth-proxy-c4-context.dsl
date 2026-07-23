workspace {
    model {
        user = person "End User" "Data scientist or developer accessing RHOAI components via browser or CLI"
        serviceAccount = person "Service Account" "Kubernetes service account authenticating via token"
        envoyGateway = softwareSystem "Envoy Gateway" "RHOAI 3.x Gateway API ingress controller" "External"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy for OIDC and OpenShift OAuth" {
            proxyService = container "kube-auth-proxy" "Authentication proxy with middleware chain architecture" "Go Service" {
                preAuthChain = component "Pre-Auth Chain" "Scope injection, HTTPS redirect, health checks, logging, metrics" "Go middleware"
                sessionChain = component "Session Chain" "K8s TokenReview → OAuth Bearer → JWT Bearer → Basic Auth → Stored Session" "Go middleware"
                headersChain = component "Headers Chain" "Injects X-Forwarded-User/Email/Access-Token headers" "Go middleware"
                extAuthzHandler = component "ext_authz Handler" "Returns 202/401/403 for Envoy external authorization" "Go handler"
                mlflowDenyHandler = component "MLflow Auth Deny" "Returns structured JSON errors for MLflow Python SDK" "Go handler"
            }
            oidcProvider = container "OIDC Provider Module" "Standards-compliant OIDC authentication with JWT validation, PKCE" "Go module"
            openshiftProvider = container "OpenShift Provider Module" "OpenShift OAuth with auto-discovery and sha256~ token support" "Go module"
            cookieStore = container "Cookie Session Store" "Client-side sessions with AES-CFB encryption, HMAC signing, 4KB auto-split" "Go module"
            redisStore = container "Redis Session Store" "Server-side sessions with per-session AES-GCM encryption, ticket-based" "Go module"
            k8sTokenReview = container "K8s TokenReview Validator" "Validates Kubernetes service account tokens via TokenReview API" "Go module"
        }

        oidcExternal = softwareSystem "OIDC Provider" "External OpenID Connect identity provider" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift internal OAuth service with auto-discovery" "External"
        k8sApiServer = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        upstreamApp = softwareSystem "Upstream Application" "Backend RHOAI component receiving authenticated requests" "Internal RHOAI"
        redis = softwareSystem "Redis" "Optional server-side session storage (Standalone/Sentinel/Cluster)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        mlflowSDK = softwareSystem "MLflow Python SDK" "ML experiment tracking client" "External"

        # User interactions
        user -> kubeAuthProxy "Authenticates via browser (OIDC/OAuth) or CLI (Bearer token)"
        serviceAccount -> kubeAuthProxy "Authenticates via Kubernetes SA token"
        envoyGateway -> kubeAuthProxy "ext_authz subrequest on /oauth2/auth" "HTTP/4180"

        # Proxy to external
        kubeAuthProxy -> oidcExternal "OIDC discovery, token exchange, userinfo, JWKS" "HTTPS/443"
        kubeAuthProxy -> openshiftOAuth "OAuth discovery, authorization, token exchange" "HTTPS/443"
        kubeAuthProxy -> k8sApiServer "TokenReview API, OpenShift User API" "HTTPS/443"
        kubeAuthProxy -> upstreamApp "Forwards authenticated requests with identity headers" "HTTP/HTTPS"
        kubeAuthProxy -> redis "Session storage (optional)" "TCP/6379"
        kubeAuthProxy -> mlflowSDK "Structured JSON auth errors" "HTTP/4180"
        prometheus -> kubeAuthProxy "Scrapes metrics" "HTTP/8090"

        # Internal container relationships
        proxyService -> oidcProvider "Delegates OIDC auth flows"
        proxyService -> openshiftProvider "Delegates OpenShift auth flows"
        proxyService -> cookieStore "Reads/writes session cookies"
        proxyService -> redisStore "Reads/writes Redis session tickets"
        proxyService -> k8sTokenReview "Validates SA tokens"
        redisStore -> redis "Stores encrypted session data" "TCP/6379"
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

        component proxyService "Components" {
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
                shape Person
                background #08427b
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
