workspace {
    model {
        # People
        platformAdmin = person "Platform Admin" "Configures RHOAI platform components and RBAC policies"
        prometheusOperator = person "Prometheus Operator" "Manages monitoring stack in openshift-monitoring namespace"

        # The kube-rbac-proxy system
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar that enforces Kubernetes RBAC authorization via TokenReview and SubjectAccessReview before forwarding requests to upstream services" {
            tlsListener = container "TLS Listener" "Accepts HTTPS connections on port 8443 with TLS 1.2+ and HTTP/2 ALPN" "Go net/http + crypto/tls"
            certReloader = container "CertReloader" "Hot-reloads TLS certificates from disk without restart" "Go pkg/tls"
            pathFilter = container "Path Filter" "Matches requests against --ignore-paths patterns to bypass auth" "Go pkg/filters"
            authnFilter = container "AuthN Filter" "Authenticates requests via delegating TokenReview, OIDC JWT, or X.509 client certificates" "Go pkg/authn + k8s.io/apiserver"
            authzChain = container "AuthZ Chain" "Authorizes requests via hardcoded metrics authorizer, static allow-list, then SAR authorizer" "Go pkg/authz + pkg/hardcodedauthorizer"
            reverseProxy = container "Reverse Proxy" "Forwards authorized requests to upstream application on localhost" "Go net/http/httputil"
        }

        # External systems
        k8sApiServer = softwareSystem "Kubernetes API Server" "Validates tokens (TokenReview) and checks RBAC permissions (SubjectAccessReview)" "External"
        upstreamApp = softwareSystem "Upstream Application" "Application container (metrics, API endpoints) running in the same pod on localhost port 8080/8081" "Internal Pod"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for JWT-based authentication (optional)" "External"
        certManager = softwareSystem "cert-manager / Platform Operator" "Provisions and rotates TLS certificates for the proxy" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy as a sidecar into component pods" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API (HTTPRoute)" "Routes external traffic through the platform Gateway to kube-rbac-proxy" "Internal Platform"
        prometheus = softwareSystem "Prometheus (openshift-monitoring)" "Scrapes /metrics endpoint with hardcoded authorization bypass for prometheus-k8s SA" "Internal Platform"

        # Relationships - External to kube-rbac-proxy
        platformAdmin -> kubeRbacProxy "Configures authorization policies (Format1/Format2)" "YAML config"
        rhodsOperator -> kubeRbacProxy "Injects as sidecar container" "Deployment spec"
        gatewayAPI -> kubeRbacProxy "Routes traffic to" "HTTPS/8443"
        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443, hardcoded allow"
        certManager -> kubeRbacProxy "Provisions TLS certificates" "kubernetes.io/tls Secret"

        # Relationships - kube-rbac-proxy to external
        kubeRbacProxy -> k8sApiServer "Authenticates tokens and checks RBAC permissions" "HTTPS/443, TokenReview + SubjectAccessReview"
        kubeRbacProxy -> upstreamApp "Forwards authorized requests" "HTTP/8080, localhost"
        kubeRbacProxy -> oidcProvider "Retrieves OIDC discovery and JWKS keys" "HTTPS/443"

        # Internal relationships
        tlsListener -> pathFilter "Passes requests"
        pathFilter -> authnFilter "Unmatched paths"
        pathFilter -> reverseProxy "Matched paths (bypass auth)"
        authnFilter -> authzChain "Authenticated identity"
        authzChain -> reverseProxy "Authorized requests"
        certReloader -> tlsListener "Reloads certificates"
        authnFilter -> k8sApiServer "TokenReview" "HTTPS/443"
        authnFilter -> oidcProvider "OIDC verification" "HTTPS/443"
        authzChain -> k8sApiServer "SubjectAccessReview" "HTTPS/443"
        reverseProxy -> upstreamApp "Proxied request" "HTTP/8080 localhost"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Internal Pod" {
                background #4caf50
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
