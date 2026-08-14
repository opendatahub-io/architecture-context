workspace {
    model {
        serviceConsumer = person "Service Consumer" "Client accessing a protected Kubernetes service endpoint"
        clusterAdmin = person "Cluster Admin" "Configures RBAC and authorization policies"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "TLS-terminating authentication and authorization reverse proxy sidecar for Kubernetes services" {
            tlsTerminator = container "TLS Terminator" "Accepts HTTPS connections, terminates TLS, manages certificates" "Go crypto/tls"
            authenticationHandler = container "Authentication Handler" "Validates client identity via OIDC or Kubernetes TokenReview" "Go HTTP Handler"
            authorizationChain = container "Authorization Chain" "Union authorizer: hardcoded metrics + static rules + SubjectAccessReview" "Go HTTP Handler"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream service" "Go httputil.ReverseProxy"
            healthEndpoint = container "Health Endpoint" "Exposes /healthz for liveness probing on dedicated port" "Go HTTP Handler"
        }

        upstreamService = softwareSystem "Upstream Service" "Co-located application container serving business logic on localhost" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for TokenReview, SubjectAccessReview, and resource operations" "External"
        ocpMonitoring = softwareSystem "OpenShift Monitoring" "Platform monitoring stack that scrapes metrics endpoints" "External"

        # Relationships
        serviceConsumer -> kubeRbacProxy "Sends HTTPS requests with Bearer token" "HTTPS/8443, TLS 1.2+"
        clusterAdmin -> k8sAPI "Configures ClusterRoles and bindings" "HTTPS/6443"

        tlsTerminator -> authenticationHandler "Passes decrypted request"
        authenticationHandler -> authorizationChain "Passes authenticated request with user info"
        authorizationChain -> reverseProxy "Passes authorized request with auth headers"
        reverseProxy -> upstreamService "Forwards request" "HTTP/8080, localhost"

        authenticationHandler -> k8sAPI "TokenReview (delegating auth)" "HTTPS/6443, SA token"
        authorizationChain -> k8sAPI "SubjectAccessReview" "HTTPS/6443, SA token"

        ocpMonitoring -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #fff2cc
                color #333333
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
