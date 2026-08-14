workspace {
    model {
        user = person "End User" "Accesses RHOAI platform services via browser or API client"
        serviceAccount = person "Service Account" "Kubernetes workload authenticating via ServiceAccount token"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authenticating reverse proxy that gates access to upstream services via OAuth2/OIDC, Kubernetes TokenReview, JWT, and basic authentication" {
            preAuthMiddleware = container "Pre-Auth Middleware" "Health checks (/ping, /ready), request logging, Prometheus metrics, HTTPS redirect" "gorilla/mux + justinas/alice"
            authSessionChain = container "Auth Session Chain" "Layered authentication: K8s TokenReview → JWT Bearer → OAuth2/OIDC session → htpasswd basic auth" "Go Middleware Chain"
            upstreamProxy = container "Upstream Proxy" "Forwards authenticated requests to configured upstream with enriched headers (X-Forwarded-User, X-Forwarded-Email)" "HTTP + WebSocket Proxy"
            authEndpoints = container "Auth Endpoints" "OAuth2 sign-in, callback, sign-out, auth-only validation (ext_authz), and userinfo endpoints" "HTTP Handlers"
        }

        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift-native OAuth2/OIDC identity provider with sha256~ token support" "External"
        kubeAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for TokenReview validation" "External"
        redis = softwareSystem "Redis/Valkey" "Optional session state persistence with TLS support" "External"
        upstreamService = softwareSystem "Upstream Service" "RHOAI Dashboard, Model Serving, or other platform service behind the proxy" "Internal RHOAI"

        # User interactions
        user -> kubeAuthProxy "Accesses via browser (OAuth2) or API (Bearer token)" "HTTPS/443 via Route"
        serviceAccount -> kubeAuthProxy "Authenticates via K8s ServiceAccount token" "HTTPS/443 via Route"

        # Internal flows
        preAuthMiddleware -> authSessionChain "Passes non-health requests"
        authSessionChain -> upstreamProxy "Passes authenticated requests"
        authEndpoints -> openshiftOAuth "OAuth2 authorization and token exchange" "HTTPS"

        # External dependencies
        kubeAuthProxy -> openshiftOAuth "Exchanges auth codes for tokens, validates sessions" "HTTPS"
        kubeAuthProxy -> kubeAPI "Validates Bearer tokens via TokenReview API" "HTTPS/6443, TLS 1.2+"
        kubeAuthProxy -> redis "Reads/writes session state" "TCP, Optional TLS"
        kubeAuthProxy -> upstreamService "Forwards authenticated requests with identity headers" "HTTP/WebSocket"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
