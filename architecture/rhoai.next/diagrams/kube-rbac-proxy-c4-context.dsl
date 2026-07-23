workspace {
    model {
        user = person "Platform User / Service" "Client requesting access to a protected RHOAI component service"
        sre = person "SRE / Platform Admin" "Monitors platform health via Prometheus metrics"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar that enforces Kubernetes RBAC (TokenReview + SubjectAccessReview) before forwarding requests to upstream applications" {
            tlsListener = container "TLS Listener" "Accepts HTTPS connections on port 8443 with configurable TLS 1.2+ and ALPN (h2, http/1.1)" "Go net/http Server"
            pathFilter = container "Path Filter" "Routes requests based on --allow-paths / --ignore-paths configuration" "Go HTTP Handler"
            authenticationLayer = container "Authentication Layer" "Validates caller identity via TokenReview, X.509 client certs, or OIDC JWT" "Go Middleware (delegating authenticator)"
            authorizationLayer = container "Authorization Layer" "Authorizes requests via SubjectAccessReview with Format1 (simple) or Format2 (path-scoped) config" "Go Middleware (SAR authorizer)"
            hardcodedMetricsAuthz = container "Hardcoded Metrics Authorizer" "Permits openshift-monitoring prometheus-k8s SA to scrape /metrics without SAR" "Go Authorizer"
            certReloader = container "CertReloader" "Hot-reloads TLS serving certificates by polling cert files every 1 minute" "Go Background Goroutine"
            sanitizingFilter = container "SanitizingFilter" "Masks bearer tokens in TokenReview log output to prevent credential leakage" "Go Log Filter"
            upstreamProxy = container "Upstream Proxy" "Reverse proxies authenticated/authorized requests to the application container" "Go httputil.ReverseProxy"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API server for TokenReview and SubjectAccessReview calls" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that injects kube-rbac-proxy sidecars into component pods" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring Prometheus" "Cluster monitoring system that scrapes /metrics endpoints" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for JWT-based authentication (optional)" "External"
        certManager = softwareSystem "cert-manager" "Kubernetes certificate management controller that provisions TLS certificates" "External"
        upstreamApp = softwareSystem "Component Application" "The protected RHOAI component service running in the same pod" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway (Envoy)" "RHOAI ingress gateway that routes traffic via HTTPRoute resources" "Internal RHOAI"

        # Relationships
        user -> platformGateway "Sends requests to RHOAI components" "HTTPS/443"
        platformGateway -> kubeRbacProxy "Routes traffic to component Service" "HTTPS/8443"
        kubeRbacProxy -> k8sApiServer "Validates tokens (TokenReview) and authorizes requests (SubjectAccessReview)" "HTTPS/443"
        kubeRbacProxy -> oidcProvider "Retrieves OIDC discovery and JWKS keys for JWT validation" "HTTPS/443"
        kubeRbacProxy -> upstreamApp "Proxies authenticated/authorized requests" "HTTP/8080 (localhost)"
        prometheus -> kubeRbacProxy "Scrapes /metrics (hardcoded allow for prometheus-k8s SA)" "HTTPS/8443"
        rhodsOperator -> kubeRbacProxy "Injects as sidecar container into component pods" "Pod Spec"
        certManager -> kubeRbacProxy "Provisions and rotates TLS serving certificates" "Kubernetes Secret"
        sre -> prometheus "Views platform metrics and alerts" "HTTPS"

        # Container-level relationships
        tlsListener -> pathFilter "Routes incoming requests"
        pathFilter -> authenticationLayer "Non-ignored paths"
        pathFilter -> upstreamProxy "Ignored paths (bypass auth)"
        authenticationLayer -> authorizationLayer "Authenticated user info"
        authorizationLayer -> upstreamProxy "Authorized requests"
        hardcodedMetricsAuthz -> upstreamProxy "Prometheus /metrics (auto-allowed)"
        certReloader -> tlsListener "Swaps TLS certificates"
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
