workspace {
    model {
        datascientist = person "Data Scientist" "Interacts with RHOAI components via authenticated APIs"
        sre = person "SRE / Platform Admin" "Monitors platform health and metrics"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP/HTTPS reverse proxy enforcing Kubernetes RBAC authorization via SubjectAccessReview before forwarding to upstream services" {
            tlsListener = container "TLS Listener" "Accepts HTTPS connections on port 8443/TCP with configurable TLS 1.2+" "Go net/http"
            delegatingAuthn = container "Delegating Authenticator" "Validates bearer tokens via Kubernetes TokenReview API" "Go Module"
            oidcAuthn = container "OIDC Authenticator" "Validates OIDC JWTs against configured issuer" "Go Module"
            x509Authn = container "X.509 Authenticator" "Verifies client certificates against configured CA" "Go Module"
            sarAuthorizer = container "SAR Authorizer" "Issues SubjectAccessReview to Kubernetes API for RBAC checks" "Go Module"
            staticAuthorizer = container "Static Authorizer" "Pre-SAR check against static user/resource/verb allow-list" "Go Module"
            hardcodedMetricsAuthz = container "Hardcoded Metrics Authorizer" "Unconditionally allows prometheus-k8s SA to GET /metrics" "Go Module"
            certReloader = container "TLS Certificate Reloader" "Hot-reloads TLS certificates from disk on configurable interval" "Go Module"
            tokenSanitizer = container "Token Sanitizing Filter" "Masks bearer tokens in klog output to prevent credential leakage" "Go Module"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Provides TokenReview and SubjectAccessReview APIs for authentication and authorization" "External"
        upstreamApp = softwareSystem "Upstream Application" "The RHOAI component being fronted (e.g., TrustyAI, Model Registry, notebook controller)" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy as a sidecar into component pods" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus instance (prometheus-k8s SA) that scrapes /metrics endpoints" "Internal OpenShift"
        certManager = softwareSystem "cert-manager / Platform TLS" "Provisions and rotates TLS certificates mounted to the proxy" "Internal OpenShift"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for JWT-based authentication (optional)" "External"

        # Relationships
        datascientist -> kubeRbacProxy "Sends authenticated API requests" "HTTPS/8443, Bearer Token / OIDC JWT / X.509"
        sre -> prometheus "Configures monitoring"

        kubeRbacProxy -> k8sApiServer "TokenReview (authn) and SubjectAccessReview (authz)" "HTTPS/443, SA token"
        kubeRbacProxy -> upstreamApp "Forwards pre-authenticated requests" "HTTP/HTTPS/h2c, configurable port"
        kubeRbacProxy -> oidcProvider "Fetches OIDC discovery and JWKS" "HTTPS/443"
        prometheus -> kubeRbacProxy "Scrapes /metrics (hardcoded allow)" "HTTPS/8443, Bearer Token"
        rhodsOperator -> kubeRbacProxy "Injects sidecar container, TLS certs, and auth config" "Deployment spec"
        certManager -> kubeRbacProxy "Provisions TLS serving certificates" "Secret mount"

        # Internal container relationships
        tlsListener -> delegatingAuthn "Routes requests for token auth"
        tlsListener -> oidcAuthn "Routes requests for OIDC auth"
        tlsListener -> x509Authn "Routes requests for cert auth"
        delegatingAuthn -> hardcodedMetricsAuthz "Passes authenticated identity"
        oidcAuthn -> hardcodedMetricsAuthz "Passes authenticated identity"
        x509Authn -> hardcodedMetricsAuthz "Passes authenticated identity"
        hardcodedMetricsAuthz -> staticAuthorizer "Passes non-metrics requests"
        staticAuthorizer -> sarAuthorizer "Passes non-static-allowed requests"
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
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
