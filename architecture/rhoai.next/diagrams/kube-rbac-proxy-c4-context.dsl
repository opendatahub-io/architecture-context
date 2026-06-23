workspace {
    model {
        # People
        user = person "Platform User" "Data scientist, developer, or admin accessing RHOAI components"
        sre = person "SRE / Platform Admin" "Monitors and manages RHOAI platform"

        # Main system
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy enforcing Kubernetes RBAC authentication and authorization via TokenReview/SubjectAccessReview" {
            tlsListener = container "TLS Listener" "Accepts HTTPS connections on 8443/TCP, terminates TLS 1.2+" "Go net/http + crypto/tls"
            delegatingAuthn = container "Delegating Authenticator" "Authenticates bearer tokens via Kubernetes TokenReview API" "Go pkg/authn"
            oidcAuthn = container "OIDC Authenticator" "Validates OIDC JWT tokens against configured issuer" "Go pkg/authn (coreos/go-oidc)"
            x509Authn = container "X.509 Authenticator" "Validates client certificates against configured CA" "Go pkg/authn"
            hardcodedAuthz = container "Hardcoded Metrics Authorizer" "Allows prometheus-k8s SA to GET /metrics without SAR" "Go pkg/hardcodedauthorizer"
            staticAuthz = container "Static Authorizer" "Authorizes against pre-configured static rules" "Go pkg/authz"
            sarAuthz = container "SAR Authorizer" "Authorizes via Kubernetes SubjectAccessReview API" "Go pkg/authz"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream" "Go net/http/httputil"
            certReloader = container "TLS Certificate Reloader" "Hot-reloads TLS certificates from disk" "Go pkg/tls"
            logSanitizer = container "Log Sanitizer" "Masks bearer tokens in log output" "Go cmd/app"
        }

        # External systems
        k8sApiServer = softwareSystem "Kubernetes API Server" "Authenticates tokens (TokenReview) and authorizes requests (SubjectAccessReview)" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "Provides OIDC discovery and JWKS for JWT validation" "External"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates" "External"

        # Internal platform systems
        rhodsOperator = softwareSystem "rhods-operator" "Injects kube-rbac-proxy as sidecar in component pods" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream Application" "Component application container (notebook, model server, dashboard)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes /metrics endpoint for monitoring" "Internal OpenShift"

        # Relationships - User interactions
        user -> kubeRbacProxy "Sends authenticated requests to RHOAI components" "HTTPS/8443, Bearer/OIDC/X.509"
        sre -> prometheus "Monitors RHOAI component metrics"

        # Relationships - External
        kubeRbacProxy -> k8sApiServer "Authenticates tokens (TokenReview) and authorizes requests (SubjectAccessReview)" "HTTPS/443, SA Token"
        kubeRbacProxy -> oidcProvider "Fetches OIDC discovery and JWKS (when configured)" "HTTPS/443"
        certManager -> kubeRbacProxy "Provisions TLS certificates" "File mount"

        # Relationships - Internal
        rhodsOperator -> kubeRbacProxy "Injects as sidecar container in component pods" "Pod spec injection"
        kubeRbacProxy -> upstreamApp "Proxies authorized requests" "HTTP/8081, localhost"
        prometheus -> kubeRbacProxy "Scrapes /metrics (hardcoded allow)" "HTTPS/8443, SA Token"

        # Container relationships
        tlsListener -> delegatingAuthn "Passes request for authentication"
        tlsListener -> oidcAuthn "Passes request for OIDC authentication"
        tlsListener -> x509Authn "Passes request for X.509 authentication"
        delegatingAuthn -> k8sApiServer "Creates TokenReview" "HTTPS/443"
        oidcAuthn -> oidcProvider "Fetches JWKS" "HTTPS/443"
        delegatingAuthn -> hardcodedAuthz "Passes authenticated identity"
        oidcAuthn -> hardcodedAuthz "Passes authenticated identity"
        x509Authn -> hardcodedAuthz "Passes authenticated identity"
        hardcodedAuthz -> staticAuthz "Chains to next authorizer"
        staticAuthz -> sarAuthz "Chains to next authorizer"
        sarAuthz -> k8sApiServer "Creates SubjectAccessReview" "HTTPS/443"
        sarAuthz -> reverseProxy "Passes authorized request"
        hardcodedAuthz -> reverseProxy "Fast-path for prometheus-k8s"
        reverseProxy -> upstreamApp "Proxies request" "HTTP/8081"
        certReloader -> tlsListener "Reloads TLS certificates"
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
                background #ee0000
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
