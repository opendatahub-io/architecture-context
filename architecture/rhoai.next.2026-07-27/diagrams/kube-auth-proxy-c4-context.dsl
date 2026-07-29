workspace {
    model {
        user = person "End User" "Human user accessing protected services via browser"
        serviceClient = person "Service Account Client" "Automated client using Kubernetes SA token"

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "OAuth2/OIDC authentication reverse proxy for Kubernetes, enforcing access control in front of upstream services" {
            proxy = container "kube-auth-proxy" "Reverse proxy that intercepts HTTP requests and enforces authentication via OpenShift OAuth, OIDC, or Kubernetes TokenReview" "Go Binary" "Primary"
            sessionManager = container "Session Manager" "Manages encrypted cookie-based sessions with optional Redis persistence" "Go Package"
        }

        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift identity provider for OAuth2 authentication flows" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External OpenID Connect identity provider" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview validation and resource operations" "External"
        redis = softwareSystem "Redis / Valkey" "Session persistence store supporting standalone, Sentinel, and Cluster modes" "External"
        upstreamService = softwareSystem "Upstream Service" "Backend application receiving pre-authenticated requests" "Internal"
        openshiftRoute = softwareSystem "OpenShift Route" "Ingress with TLS edge termination" "Infrastructure"

        user -> openshiftRoute "Accesses protected application" "HTTPS/443 TLS 1.2+"
        serviceClient -> openshiftRoute "Calls API with SA token" "HTTPS/443 Bearer Token"
        openshiftRoute -> kubeAuthProxy "Forwards traffic after TLS termination" "HTTP/80 -> 4180"

        proxy -> openshiftOAuth "OAuth2 authorization + token exchange" "HTTPS"
        proxy -> oidcProvider "OIDC authentication flow" "HTTPS"
        proxy -> kubernetesAPI "TokenReview API for SA token validation" "HTTPS/6443 TLS 1.2+"
        proxy -> redis "Session persistence and distributed locking" "TCP (optional TLS)"
        proxy -> upstreamService "Forwards authenticated requests with identity headers" "HTTP/8080"

        sessionManager -> redis "Stores/retrieves encrypted session data" "TCP"
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
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}
