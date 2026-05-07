workspace {
    model {
        inClusterService = person "In-Cluster Service" "Any service or user within the Kubernetes cluster making API requests to protected components"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar enforcing Kubernetes RBAC authorization via SubjectAccessReview" {
            tlsTermination = container "TLS Termination" "Terminates TLS 1.2+ connections, hot-reloads certificates" "Go crypto/tls + CertReloader"
            authNModule = container "Authentication Module" "Authenticates callers via TokenReview, OIDC JWT, or x509 client certificates" "Go pkg/authn"
            authZModule = container "Authorization Module" "Authorizes via hardcoded rules, static config, and SubjectAccessReview" "Go pkg/authz"
            filterChain = container "Filter Chain" "Middleware pipeline: path filter → authN → authZ → header injection" "Go pkg/filters"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream application" "Go pkg/proxy"
            certReloader = container "TLS Reloader" "Hot-reloads TLS certificates from filesystem at configurable interval" "Go pkg/tls"
            sanitizer = container "Sanitizing Filter" "Masks bearer tokens in klog output to prevent credential leakage" "Go"
        }

        kubeApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane providing TokenReview and SubjectAccessReview APIs" "External"
        upstreamApp = softwareSystem "Upstream Application" "Protected application container running in the same pod (localhost)" "Internal"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy sidecars into component pods" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Cluster monitoring system scraping /metrics endpoints" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for JWT-based authentication (optional)" "External"
        certManager = softwareSystem "cert-manager / Platform TLS" "Certificate provisioning and rotation for TLS" "External"

        # Relationships
        inClusterService -> kubeRbacProxy "Sends HTTPS requests (8443/TCP, TLS 1.2+, Bearer/mTLS/OIDC)"
        kubeRbacProxy -> kubeApiServer "TokenReview + SubjectAccessReview (HTTPS/443, SA Token)" "HTTPS/443"
        kubeRbacProxy -> upstreamApp "Forwards authorized requests (localhost, HTTP/HTTPS/h2c)" "HTTP/localhost"
        kubeRbacProxy -> oidcProvider "Fetches OIDC discovery + JWKS (HTTPS/443, optional)" "HTTPS/443"
        prometheus -> kubeRbacProxy "Scrapes /metrics (HTTPS/8443, hardcoded ALLOW for prometheus-k8s SA)" "HTTPS/8443"
        rhodsOperator -> kubeRbacProxy "Injects as sidecar container into component pods" "Deployment"
        certManager -> kubeRbacProxy "Provisions and rotates TLS certificates (file mount)" "File Mount"

        # Internal container relationships
        filterChain -> authNModule "Delegates authentication"
        filterChain -> authZModule "Delegates authorization"
        filterChain -> reverseProxy "Forwards authorized requests"
        authNModule -> kubeApiServer "TokenReview API call"
        authNModule -> oidcProvider "OIDC discovery + JWKS"
        authZModule -> kubeApiServer "SubjectAccessReview API call"
        certReloader -> tlsTermination "Reloads certificates"
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
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
