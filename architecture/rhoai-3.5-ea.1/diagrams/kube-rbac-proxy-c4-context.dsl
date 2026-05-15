workspace {
    model {
        prometheus = person "Prometheus" "OpenShift Monitoring Prometheus (prometheus-k8s SA) scrapes metrics"
        datascientist = person "Data Scientist" "Accesses RHOAI component APIs and dashboards"
        platformadmin = person "Platform Admin" "Manages RHOAI platform via kubectl/oc"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "HTTP reverse proxy sidecar performing Kubernetes RBAC authn/authz via TokenReview and SubjectAccessReview" {
            proxyServer = container "Proxy Server" "HTTPS reverse proxy with layered filter chain: PathFilter → AuthN → AuthZ → HeaderInjection" "Go HTTP Server"
            certReloader = container "CertReloader" "Polls TLS certificate files for changes and hot-reloads without restart" "Go Goroutine"
            hardcodedAuthorizer = container "Hardcoded Metrics Authorizer" "Unconditionally allows prometheus-k8s SA to GET /metrics" "Go Authorizer"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane: authentication (TokenReview) and authorization (SubjectAccessReview) delegation" "External"
        upstreamApp = softwareSystem "Upstream Application" "The actual service container (metrics endpoint, API server, web UI) running in the same Pod" "Internal"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for JWT-based authentication (optional)" "External"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for the proxy HTTPS listener" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys kube-rbac-proxy as sidecar in component Pods" "Internal RHOAI"

        # Relationships
        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443, Bearer Token (hardcoded allow)"
        datascientist -> kubeRbacProxy "Accesses component APIs" "HTTPS/8443, Bearer Token"
        platformadmin -> kubeRbacProxy "Accesses component endpoints" "HTTPS/8443, Bearer Token / mTLS"

        kubeRbacProxy -> k8sApiServer "Delegates authentication" "HTTPS/443, POST tokenreviews"
        kubeRbacProxy -> k8sApiServer "Delegates authorization" "HTTPS/443, POST subjectaccessreviews"
        kubeRbacProxy -> upstreamApp "Forwards authorized requests" "HTTP/8081, localhost, x-remote-user headers"
        kubeRbacProxy -> oidcProvider "Fetches OIDC discovery and JWKS" "HTTPS/443 (optional)"

        certManager -> kubeRbacProxy "Provisions TLS certificates" "Kubernetes Secret mount"
        rhodsOperator -> kubeRbacProxy "Deploys as sidecar container" "Pod spec injection"

        # Container relationships
        proxyServer -> certReloader "Uses reloaded TLS certs"
        proxyServer -> hardcodedAuthorizer "Checks metrics bypass"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #4a90e2
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
