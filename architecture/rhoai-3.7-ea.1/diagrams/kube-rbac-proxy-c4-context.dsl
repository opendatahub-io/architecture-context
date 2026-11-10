workspace "kube-rbac-proxy (RHOAI 3.7-ea.1)" "Authenticating/authorizing reverse-proxy sidecar" {
    model {
        user = person "User / Data Scientist" "Reaches protected workloads (notebooks, model servers, TrustyAI) via Gateway API HTTPRoutes"
        serviceClient = person "In-cluster Service Client" "Calls protected endpoints with a ServiceAccount token or client certificate"

        krp = softwareSystem "kube-rbac-proxy" "Sidecar reverse proxy that authenticates (TokenReview / OIDC / x509) and authorizes (SubjectAccessReview) requests before forwarding them to one upstream. Image odh-kube-rbac-proxy-rhel9, v0.21.1." {
            proxy = container "kube-rbac-proxy" "TLS-terminating filter chain: allow-paths, ignore-paths, timeouts, authentication, authorization, auth headers, reverse proxy" "Go (Cobra CLI), sidecar container, 8443/TCP"
            authn = container "pkg/authn" "Delegating authenticator (TokenReview + client CA, anonymous disabled) and OIDC JWT authenticator" "Go package"
            authz = container "pkg/authz" "Union authorizer (hardcoded metrics, static, SAR) with Format1/Format2 attribute templating" "Go package"
            audit = container "pkg/audit" "OCSF 1.9.0 API Activity events, AI Operation profile, async to stdout" "Go package"
            tlsReload = container "pkg/tls" "Certificate hot-reload and curve-preference validation" "Go package"

            proxy -> authn "Authenticates callers"
            proxy -> authz "Authorizes attribute sets"
            proxy -> audit "Emits audit events (metadata profile)"
            tlsReload -> proxy "Supplies serving certificate"
        }

        upstream = softwareSystem "Protected Upstream Application" "Workload container in the same pod (usually 8080/TCP localhost)" "Internal RHOAI"
        operators = softwareSystem "RHOAI Component Operators" "rhods-operator, odh-notebook-controller, KServe, TrustyAI: inject the sidecar and pass cluster TLS profile flags" "Internal RHOAI"
        gateway = softwareSystem "Gateway API data-science-gateway" "HTTPRoutes route external traffic to the sidecar Service:8443" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Prometheus" "openshift-monitoring:prometheus-k8s; scrapes /metrics via the hardcoded authorizer" "OpenShift"
        serviceCA = softwareSystem "OpenShift service-ca" "Issues serving certificates mounted by consumers" "OpenShift"
        k8s = softwareSystem "Kubernetes API Server" "TokenReview and SubjectAccessReview" "External"
        oidc = softwareSystem "OIDC Provider" "Optional JWT issuer (discovery and JWKS)" "External"
        logs = softwareSystem "Log Collection" "Collects OCSF audit events from stdout" "External"

        user -> gateway "HTTPS requests with bearer token" "HTTPS/443"
        gateway -> krp "Routes to sidecar" "HTTPS/8443, TLS 1.2+"
        serviceClient -> krp "Calls protected API" "HTTPS/8443, Bearer or x509"
        prometheus -> krp "Scrapes /metrics" "HTTPS/8443, Bearer SA token"
        operators -> krp "Injects sidecar, mounts certs and config, projects TLS profile"
        serviceCA -> krp "Provides serving cert (hot-reloaded)"

        krp -> k8s "TokenReview, SubjectAccessReview" "HTTPS/6443, SA token"
        krp -> oidc "Fetches discovery and JWKS (optional)" "HTTPS/443"
        krp -> upstream "Forwards allowed requests with optional x-remote-user/x-remote-groups" "HTTP/8080 localhost (or HTTPS/mTLS/h2c)"
        krp -> logs "Writes OCSF audit events" "stdout"

        proxy -> upstream "Forwards allowed requests" "HTTP/8080 localhost"
        authn -> k8s "TokenReview" "HTTPS/6443"
        authn -> oidc "JWKS" "HTTPS/443"
        authz -> k8s "SubjectAccessReview" "HTTPS/6443"
        audit -> logs "OCSF JSON" "stdout"
        gateway -> proxy "Routes to sidecar" "HTTPS/8443"
        serviceClient -> proxy "Calls protected API" "HTTPS/8443"
        prometheus -> proxy "Scrapes /metrics" "HTTPS/8443"
    }

    views {
        systemContext krp "SystemContext" {
            include *
            autoLayout
        }

        container krp "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6aa9f0
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "OpenShift" {
                background #f5a623
                color #000000
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
