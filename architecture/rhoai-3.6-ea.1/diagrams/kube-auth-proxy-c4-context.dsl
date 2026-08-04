workspace {
    model {
        user = person "End User" "Data scientist or developer accessing RHOAI services via browser or API"
        serviceClient = person "Service Client" "Automated system using Kubernetes ServiceAccount tokens for programmatic access"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "FIPS-compliant authentication reverse proxy that enforces OAuth2/OIDC and K8s ServiceAccount token authentication before forwarding requests to upstream backends" {
            appServer = container "Application Server" "HTTP server handling auth endpoints and proxying" "Go :4180" "Component"
            authChain = container "Authentication Middleware" "Layered auth: K8s TokenReview → JWT/OAuth → Basic Auth → Cookie Session" "Go Middleware" "Component"
            upstreamProxy = container "Upstream Proxy Handler" "Forwards authenticated requests with injected identity headers" "Go Handler" "Component"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "Go HTTP" "Component"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for TokenReview validation and resource operations" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift identity provider for user authentication" "External"
        redis = softwareSystem "Redis/Valkey" "Optional session persistence store for horizontal scaling" "External"
        upstreamService = softwareSystem "Upstream Backend Service" "RHOAI service protected by kube-auth-proxy" "Internal RHOAI"

        # User interactions
        user -> kubeAuthProxy "Accesses protected services via browser" "HTTPS/443"
        serviceClient -> kubeAuthProxy "Sends requests with SA bearer token" "HTTPS/443"

        # Internal container interactions
        appServer -> authChain "Passes requests through auth middleware"
        authChain -> upstreamProxy "Forwards authenticated requests"

        # External dependencies
        kubeAuthProxy -> kubernetesAPI "TokenReview validation, OAuthAccessToken deletion" "HTTPS/6443"
        kubeAuthProxy -> openshiftOAuth "OAuth2 authorize/token exchange" "HTTPS/6443"
        kubeAuthProxy -> redis "Session storage and retrieval" "TCP/6379 TLS"
        kubeAuthProxy -> upstreamService "Proxies authenticated requests with identity headers" "HTTP/8080"
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
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
