workspace {
    model {
        operator = person "Platform Operator" "Deploys kube-rbac-proxy as sidecar to protect upstream services"
        prometheus = person "Prometheus Scraper" "Collects metrics from protected endpoints"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Kubernetes-aware HTTP reverse proxy sidecar enforcing RBAC authorization via SubjectAccessReview" {
            cli = container "Cobra CLI" "Parses flags, initializes listeners, manages lifecycle" "Go / oklog/run"
            tlsListener = container "TLS Listener" "Accepts HTTPS connections, TLS termination, cert hot-reload" "Go net/http"
            authnFilter = container "Authentication Filter" "OIDC or delegating TokenReview authentication" "Go / pkg/authn"
            authzFilter = container "Authorization Filter" "Union authorizer: hardcoded metrics, static rules, SAR" "Go / pkg/authz"
            reverseProxy = container "Reverse Proxy" "Forwards authorized requests to upstream via localhost" "Go / httputil"
            certReloader = container "Certificate Reloader" "Hot-reloads TLS certificates without restart" "Go / pkg/tls"
            healthEndpoint = container "Health Endpoint" "Serves /healthz on separate proxy endpoints port" "Go net/http"
        }

        upstreamService = softwareSystem "Upstream Service" "Protected application or metrics endpoint (e.g. prometheus-example-app)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for TokenReview and SubjectAccessReview" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for token validation (optional)" "External"

        // External interactions
        prometheus -> kubeRbacProxy "Scrapes metrics" "HTTPS/8443 TLS 1.2+"
        operator -> kubeRbacProxy "Configures via deployment manifests" "kubectl"

        // Internal flows
        cli -> tlsListener "Initializes"
        cli -> healthEndpoint "Initializes"
        tlsListener -> authnFilter "Passes decrypted request"
        authnFilter -> authzFilter "Passes authenticated request"
        authzFilter -> reverseProxy "Passes authorized request"
        certReloader -> tlsListener "Reloads certificates"

        // Egress
        kubeRbacProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443 TLS 1.2+"
        kubeRbacProxy -> upstreamService "Proxies authorized requests" "HTTP/localhost"
        authnFilter -> oidcProvider "Validates OIDC tokens (if configured)" "HTTPS"
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
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}
