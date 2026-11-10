workspace "praxis-ai-grid-operator" "AI Grid Network (AGN) multi-site inference routing control plane - RHOAI 3.7-ea.1" {
    model {
        admin = person "Cluster Admin" "Installs AGN and creates GridNetwork / InferenceProvider / AgentToolProvider resources"
        gridAdmin = person "Grid Admin" "Mints and revokes one-time site enrollment tokens"
        client = person "Inference Client" "Sends inference requests to a Praxis AI gateway"

        agn = softwareSystem "AI Grid Network (praxis-ai-grid-operator)" "Discovers sites and providers, gossips state over SWIM/CRDT, scores candidates and publishes versioned routing overlays" {
            operator = container "grid-operator" "Reconcilers, SWIM membership, CRDT store, scoring, routing overlay publisher, signals exporter, leader election, trust material" "Rust / kube-rs" {
                reconcilers = component "Reconcilers" "GridNetwork, GridSite, InferenceProvider, AgentToolProvider" "kube-runtime"
                swim = component "SWIM membership" "foca, AES-256-GCM, optional P-256 signed state" "Rust"
                crdt = component "CRDT store" "Delta CRDT provider and site state" "Rust"
                scoring = component "Scoring engine" "noMetrics, queueDepth, kvCachePressure" "Rust"
                publisher = component "Overlay publisher" "Content-addressed routing overlay ConfigMaps" "Rust"
                signals = component "Signals exporter" "/v1/site/signals on 9091/TCP, mTLS + pins" "axum"
                metrics = component "Metrics/health listener" "/metrics, /healthz, /readyz on 9090/TCP" "axum"
            }
            enrollment = container "grid-enrollment" "Optional site-identity bootstrap service and Grid CA signer" "Rust / axum, 8443/TCP"
            overlaySync = container "grid-overlay-sync" "Sidecar: watches overlay ConfigMap, validates envelope, writes file to shared emptyDir" "Rust"
            gridGateway = container "grid-gateway" "Project-owned data-plane gateway operand" "Rust / Praxis 0.8 / Pingora"
            dashboard = container "fleet-dashboard" "Optional fleet view (not built by Konflux)" "Rust / axum"
        }

        k8s = softwareSystem "Kubernetes API Server" "CRDs, ConfigMaps, Secrets, Leases, EndpointSlices, TokenReview/SAR" "External"
        peers = softwareSystem "Peer Site Operators" "grid-operator instances at other sites" "External"
        praxisGateway = softwareSystem "Praxis AI Gateway" "Consumes routing overlays and routes inference requests (praxis-proxy/ai)" "Internal ODH"
        llmd = softwareSystem "llm-d / Inference Providers" "Model backends; source of queueDepth / kvCachePressure signals" "Internal ODH"
        mcp = softwareSystem "MCP Servers" "Agent tool endpoints discovered via tools/list" "External"
        rhods = softwareSystem "rhods-operator / opendatahub-operator" "Vendors deploy/operator via Kustomize and params.env" "Internal ODH"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus scrape via ServiceMonitor" "Internal ODH"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues grid-operator-metrics-tls" "Internal ODH"
        postgres = softwareSystem "PostgreSQL" "Optional enrollment store (may be shared with MaaS)" "External"
        backends = softwareSystem "Private Inference Backends / External APIs" "Final hop for routed inference requests" "External"

        admin -> k8s "Creates grid.praxis.fast CRs" "HTTPS/6443"
        gridAdmin -> enrollment "Mints/revokes enrollment tokens" "HTTPS/8443 Bearer (TokenReview + SAR)"
        client -> praxisGateway "Inference requests" "HTTPS, API key / JWT"

        operator -> k8s "Watches CRDs; writes overlays, Secrets, Leases, EndpointSlices" "HTTPS/6443 SA token"
        operator -> peers "SWIM gossip + CRDT state" "UDP/7946 AES-256-GCM"
        operator -> peers "Collects remote signals" "HTTPS/9091 mTLS"
        peers -> operator "Collects signals" "HTTPS/9091 mTLS + pins"
        operator -> llmd "Health, /metrics, /v1/models" "HTTP/HTTPS"
        operator -> mcp "tools/list discovery" "MCP Streamable HTTP"
        operator -> enrollment "Enrolls (CSR) and rotates site certificate" "HTTPS/8443 token / mTLS"
        operator -> gridGateway "Patches Deployment mounts; probes metrics" "K8s API / HTTPS"
        operator -> praxisGateway "Probes and scrapes gateway metrics" "HTTPS, metrics-scraper SA token"
        enrollment -> k8s "TokenReview, SubjectAccessReview, invite Secrets" "HTTPS/6443"
        enrollment -> postgres "Token and enrollment store" "Postgres/5432 TLS verify-full"
        overlaySync -> k8s "Watches routing overlay ConfigMap" "HTTPS/6443"
        overlaySync -> praxisGateway "Delivers overlay file" "shared emptyDir"
        gridGateway -> operator "Reads peer signals" "HTTPS/9091 mTLS"
        praxisGateway -> peers "Gateway-to-gateway routing to provider site" "HTTPS mTLS (Grid CA)"
        praxisGateway -> backends "Routes requests with injected credentials" "HTTP/HTTPS"
        rhods -> operator "Deploys via Kustomize" "params.env"
        monitoring -> operator "Scrapes /metrics" "HTTPS/9090 service-ca TLS"
        serviceCa -> operator "Issues metrics serving cert" "Annotation"
    }

    views {
        systemContext agn "SystemContext" {
            include *
            autoLayout
        }

        container agn "Containers" {
            include *
            autoLayout
        }

        component operator "OperatorComponents" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
        }
    }
}
