workspace {
    model {
        dataScientist = person "Data Scientist / User" "Accesses RHOAI component endpoints (dashboards, APIs, notebooks)"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform via operator"
        sre = person "SRE / Monitoring" "Monitors platform health and metrics"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar enforcing Kubernetes RBAC authorization via TokenReview and SubjectAccessReview" {
            secureListener = container "Secure Listener" "TLS-terminating HTTPS listener on port 8443" "Go net/http Server"
            authNFilter = container "Authentication Filter" "Authenticates requests via TokenReview, OIDC JWT, or X.509 client certs" "Go Library (pkg/authn)"
            authZFilter = container "Authorization Filter" "Authorizes via hardcoded rules, static config, or SubjectAccessReview" "Go Library (pkg/authz)"
            reverseProxy = container "Reverse Proxy" "Forwards authenticated/authorized requests to upstream application" "Go httputil.ReverseProxy"
            tlsReloader = container "TLS Reloader" "Hot-reloads TLS certificates from disk without restart" "Go Library (pkg/tls)"
            tokenSanitizer = container "Token Sanitizer" "Masks bearer tokens in log output to prevent credential leakage" "Go Library"

            secureListener -> authNFilter "passes request"
            authNFilter -> authZFilter "authenticated identity"
            authZFilter -> reverseProxy "authorized request"
        }

        kubeApiServer = softwareSystem "Kubernetes API Server" "Cluster API server providing TokenReview and SubjectAccessReview APIs" "External"
        oidcProvider = softwareSystem "OIDC Provider" "OpenID Connect identity provider for JWT-based authentication" "External"
        upstreamApp = softwareSystem "Upstream Application" "Component application container running in same pod (e.g., dashboard, notebook controller)" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Cluster monitoring stack scraping /metrics endpoints" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy sidecars into component pods" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / Platform Operator" "Provisions and rotates TLS certificates for the proxy" "External"
        gatewayAPI = softwareSystem "Gateway API (HTTPRoute)" "Platform ingress gateway routing external traffic to component services" "External"

        dataScientist -> gatewayAPI "Accesses RHOAI endpoints" "HTTPS/8443"
        gatewayAPI -> kubeRbacProxy "Routes to component Service" "HTTPS/8443, TLS 1.2+"
        kubeRbacProxy -> kubeApiServer "TokenReview (authn) and SubjectAccessReview (authz)" "HTTPS/443, SA token"
        kubeRbacProxy -> oidcProvider "OIDC discovery and JWKS retrieval (when configured)" "HTTPS/443"
        kubeRbacProxy -> upstreamApp "Proxies authenticated/authorized requests" "HTTP/HTTPS/h2c"
        prometheus -> kubeRbacProxy "Scrapes /metrics (hardcoded allow for prometheus-k8s SA)" "HTTPS/8443"
        rhodsOperator -> kubeRbacProxy "Injects sidecar container into component pod specs" "Deployment spec"
        certManager -> kubeRbacProxy "Provisions TLS certificates (mounted as files)" "File mount"
        sre -> prometheus "Reviews metrics and alerts" "HTTPS"
        platformAdmin -> rhodsOperator "Configures RHOAI platform" "kubectl/oc"
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
                background #6baed6
                color #ffffff
            }
        }
    }
}
