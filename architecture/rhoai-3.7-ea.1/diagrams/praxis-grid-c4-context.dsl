workspace "praxis-grid (AI Grid Network)" "C4 model for praxis-grid in RHOAI 3.7-ea.1 (Technical Preview)" {
    model {
        admin = person "Platform Admin" "Deployment owner: creates GridNetwork, InferenceProvider, AgentToolProvider, SiteInvite CRs and enrollment tokens"
        client = person "API Client" "Sends inference requests through the edge Praxis gateway"

        agn = softwareSystem "praxis-grid (AGN)" "Federates inference providers across clusters, clouds and external APIs. Publishes routing state for Praxis AI gateways." {
            operator = container "grid-operator" "Reconciles grid.praxis.fast CRs, runs SWIM membership, scores providers, writes routing overlay and serving ConfigMaps, serves metrics and mTLS signals" "Rust, kube-rs (Deployment)"
            overlaySync = container "grid-overlay-sync" "Watches overlay ConfigMap, validates content-addressed envelope, writes it atomically to a shared emptyDir" "Rust sidecar"
            enrollment = container "enrollment" "Site certificate signer: enrollment tokens, CSR signing, rotations. TokenReview + SAR authorization" "Rust HTTPS service, 8443/TCP"
            enrollmentDb = container "Enrollment DB" "Enrollment and CSR records" "PostgreSQL" "Database"
            dashboard = container "fleet-dashboard" "Optional hub UI: fleet map and per-site health" "Rust Axum + React, 8080/TCP"
            gridGateway = container "grid-gateway" "Project-owned Praxis-based data-plane operand using the serving ConfigMap" "Rust"
        }

        peers = softwareSystem "Peer grid-operators" "AGN operators at other sites" "External"
        praxis = softwareSystem "Praxis AI Gateway" "Data plane: intelligent_route and credential_inject filters" "Internal RHOAI"
        llmd = softwareSystem "llm-d EPP" "Inference scheduler exposing queue depth and KV-cache metrics" "Internal RHOAI"
        providers = softwareSystem "Inference Providers" "vLLM backends and external APIs (OpenAI, Anthropic, Bedrock, Vertex)" "External"
        mcp = softwareSystem "MCP Servers" "Agent tool providers" "External"
        k8s = softwareSystem "Kubernetes API" "Cluster control plane" "External"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus via ServiceMonitor" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-CA" "Issues metrics serving certificate" "Internal RHOAI"
        oauthProxy = softwareSystem "oauth-proxy" "Fronts fleet-dashboard with caller identity" "External"

        admin -> k8s "Creates grid.praxis.fast CRs (watched by grid-operator)" "kubectl"
        admin -> enrollment "Mints enrollment tokens" "HTTPS/8443, Bearer → TokenReview + SAR"
        client -> praxis "Inference requests" "HTTPS/443, edge-owned auth"

        operator -> k8s "Watches CRs, writes ConfigMaps/Secrets/EndpointSlices/Leases" "HTTPS/443, SA token"
        operator -> peers "Membership and CRDT state gossip" "SWIM/UDP 7946, AES-256-GCM shared key"
        operator -> peers "Polls site signals and providers" "HTTPS/9091, mTLS SPIFFE"
        operator -> providers "Health, /v1/models discovery, metrics" "HTTP/HTTPS, Bearer from Secret / none"
        operator -> llmd "Scrapes load signals" "HTTPS, TokenRequest bearer"
        operator -> mcp "tools/list discovery" "HTTP/HTTPS"
        operator -> enrollment "Enrolls site, rotates certificate" "HTTPS/8443, enrollment token / site cert"
        enrollment -> enrollmentDb "Stores enrollments" "Postgres/5432, TLS, SCRAM"
        enrollment -> k8s "TokenReview + SubjectAccessReview" "HTTPS/443"
        overlaySync -> k8s "Watches overlay ConfigMap" "HTTPS/443, SA token"
        overlaySync -> praxis "Writes overlay file for hot reload" "shared emptyDir"
        gridGateway -> operator "Reads serving ConfigMap, posts signals" "HTTPS/9091 mTLS"
        praxis -> operator "Ingests request feedback" "HTTPS/9091 mTLS, local gateway cert"
        praxis -> providers "Routed inference with injected credentials" "HTTPS, Bearer via credential_inject"
        monitoring -> operator "Scrapes /metrics" "HTTPS/9090, service-CA TLS"
        serviceCa -> operator "Issues grid-operator-metrics-tls" "Serving-cert annotation"
        oauthProxy -> dashboard "Forwards authenticated callers" "HTTP/8080"
        dashboard -> monitoring "Queries site Prometheus" "HTTP(S)"
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
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
