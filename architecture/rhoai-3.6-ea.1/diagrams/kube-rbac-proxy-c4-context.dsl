workspace {
    model {
        client = person "Service Consumer" "Application or user making authenticated requests to protected services"
        operator = person "Platform Operator" "Configures RBAC policies and deploys kube-rbac-proxy sidecars"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Kubernetes-aware reverse proxy sidecar that performs TLS termination, authentication (OIDC/TokenReview), and authorization (SubjectAccessReview)" {
            secureListener = container "Secure Listener" "TLS-secured HTTPS listener accepting client requests" "Go net/http, crypto/tls" "8443/TCP"
            handlerChain = container "Handler Chain" "Composable middleware: WithAllowPaths → WithAuthentication → WithAuthorization → WithAuthHeaders" "Go HTTP handlers"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated requests to upstream service on localhost" "Go httputil.ReverseProxy"
            healthEndpoint = container "ProxyEndpoints Listener" "Serves /healthz for liveness/readiness probes without authentication" "Go net/http"
            tlsManager = container "TLS Manager" "Manages TLS certificates with hot-reloading, configurable min version and cipher suites" "Go crypto/tls"
        }

        upstreamService = softwareSystem "Upstream Service" "The application being protected, listening on localhost:8080" "Internal"
        k8sApiServer = softwareSystem "Kubernetes API Server" "Provides TokenReview and SubjectAccessReview APIs for authentication and authorization" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for OIDC token validation (when configured)" "External"

        # Relationships
        client -> kubeRbacProxy "Sends HTTPS requests with Bearer token" "HTTPS/8443, TLS 1.2+"
        operator -> kubeRbacProxy "Configures via CLI flags and RBAC policies" "kubectl"

        secureListener -> handlerChain "Passes incoming requests"
        handlerChain -> reverseProxy "Forwards authenticated requests"
        reverseProxy -> upstreamService "Proxies to upstream" "HTTP/8080, localhost"

        handlerChain -> k8sApiServer "TokenReview (authentication)" "HTTPS/6443, SA token"
        handlerChain -> k8sApiServer "SubjectAccessReview (authorization)" "HTTPS/6443, SA token"
        handlerChain -> oidcProvider "Validates OIDC tokens (when configured)" "HTTPS"

        tlsManager -> secureListener "Provides TLS configuration"
        tlsManager -> healthEndpoint "Provides TLS configuration"
    }

    views {
        systemContext kubeRbacProxy "SystemContext" {
            include *
            autoLayout
        }

        container kubeRbacProxy "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
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
