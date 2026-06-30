workspace {
    model {
        client = person "Client" "Application user or API consumer authenticating via Bearer token, x509 cert, or OIDC JWT"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy enforcing Kubernetes RBAC authorization via SubjectAccessReview before forwarding to upstream" {
            listener = container "Secure Listener" "TLS-terminated HTTPS listener on port 8443 with hot-reloadable certificates" "Go net/http"
            authnFilter = container "Authentication Filter" "Validates caller identity via delegated TokenReview, OIDC JWT, or x509 client certificate" "Go Package"
            authzChain = container "Authorization Chain" "Chains hardcoded (metrics), static (config), and SAR (K8s API) authorizers in priority order" "Go Package"
            proxyHandler = container "Proxy Handler" "Builds authorizer attributes and forwards authorized requests to upstream" "Go httputil.ReverseProxy"
            tlsReloader = container "TLS Reloader" "Hot-reloads server TLS certificates at configurable intervals (default 1m)" "Go Package"
            sanitizer = container "Sanitizing Filter" "Masks bearer tokens in klog output to prevent credential leakage" "Go Package"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane providing TokenReview and SubjectAccessReview APIs" "External"
        upstreamApp = softwareSystem "Upstream Application" "Component application container (notebooks, model servers, dashboard) running on localhost" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus metrics collection (prometheus-k8s service account)" "Internal OpenShift"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy sidecar containers" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / Platform Secrets" "Provisions and rotates TLS certificates" "Internal"
        oidcProvider = softwareSystem "OIDC Provider" "External OpenID Connect identity provider for JWT validation" "External"

        # Relationships
        client -> kubeRbacProxy "Sends HTTPS requests" "HTTPS/8443, TLS 1.2+, Bearer/x509/OIDC"
        kubeRbacProxy -> k8sApiServer "Validates tokens and checks authorization" "HTTPS/443, TokenReview + SubjectAccessReview"
        kubeRbacProxy -> upstreamApp "Forwards authorized requests" "HTTP/localhost"
        kubeRbacProxy -> oidcProvider "Retrieves OIDC discovery and JWKS" "HTTPS/443"
        prometheus -> kubeRbacProxy "Scrapes /metrics (hardcoded allow)" "HTTPS/8443, SA Token"
        rhodsOperator -> kubeRbacProxy "Deploys as sidecar container" "Pod spec injection"
        certManager -> kubeRbacProxy "Provides TLS certificates" "kubernetes.io/tls Secret"

        # Container relationships
        listener -> authnFilter "Passes request"
        authnFilter -> authzChain "Authenticated identity"
        authzChain -> proxyHandler "Authorization decision"
        proxyHandler -> upstreamApp "Proxied request" "HTTP/localhost"
        authnFilter -> k8sApiServer "TokenReview" "HTTPS/443"
        authzChain -> k8sApiServer "SubjectAccessReview" "HTTPS/443"
        tlsReloader -> listener "Reloads certificates"
        sanitizer -> listener "Filters log output"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal OpenShift" {
                background #e1d5e7
                color #333333
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
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
