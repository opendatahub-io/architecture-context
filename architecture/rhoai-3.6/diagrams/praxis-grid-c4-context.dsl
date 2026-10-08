workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures grid networks, sites, and inference providers"
        dataScientist = person "Data Scientist" "Sends inference requests through the grid"

        gridOperator = softwareSystem "AGN Operator (praxis-grid)" "Distributed control plane connecting AI inference backends across clusters via SWIM gossip and delta CRDTs" {
            operatorBin = container "AGN Operator" "Kubernetes controllers, SWIM runtime, scoring engine, overlay writer" "Rust Binary"
            enrollmentSvc = container "Enrollment Service" "Site enrollment API, CA/cert provisioning, certificate rotation" "Rust Binary"
            overlaySyncSidecar = container "Overlay-Sync Sidecar" "ConfigMap watcher, validated overlay delivery to gateway" "Rust Binary"
            fleetDashboard = container "Fleet Dashboard" "Fleet map, per-site health, SSE streaming" "Rust (Axum) + React"
            scoringLib = container "Scoring Library" "Strategy-selected scoring: noMetrics, queueDepth, kvCachePressure" "Rust Library"
            certsLib = container "Certs Library" "Certificate generation (rcgen/OpenSSL), mTLS provider trait" "Rust Library"
            swimLib = container "SWIM Library" "SWIM membership protocol with AES-256-GCM encryption" "Rust Library"
            crdtLib = container "CRDT Library" "Delta CRDTs: LWW registers, OR-Sets, G-Counters" "Rust Library"
        }

        praxisGateway = softwareSystem "Praxis AI Gateway" "AI gateway that routes inference requests using the grid overlay" "Internal Platform"
        peerSite = softwareSystem "Peer Site AGN Operator" "Remote site's AGN operator instance for mesh communication" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD management and resource operations" "External"
        postgresql = softwareSystem "PostgreSQL" "Enrollment state storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"
        inferenceBackends = softwareSystem "Inference Backends" "AI model serving (vLLM, llm-d, cloud APIs)" "External"
        mcpServers = softwareSystem "MCP Servers" "Agent tool providers for agentic networking" "External"

        platformAdmin -> gridOperator "Creates GridNetwork, InferenceProvider, AgentToolProvider CRs via kubectl"
        dataScientist -> praxisGateway "Sends inference requests" "HTTPS/8080"

        gridOperator -> praxisGateway "Writes routing overlay ConfigMap; gateway hot-reloads" "Filesystem (ConfigMap)"
        gridOperator -> peerSite "SWIM gossip for state propagation" "UDP/7946 AES-256-GCM"
        gridOperator -> peerSite "Signal polling for provider metrics" "HTTPS/9091 mTLS"
        gridOperator -> kubernetesAPI "CRD watch, Secret/ConfigMap CRUD" "HTTPS/443"
        gridOperator -> postgresql "Enrollment state storage" "TCP/5432 TLS"
        gridOperator -> inferenceBackends "Health probing and metrics scraping" "HTTP/HTTPS"
        gridOperator -> mcpServers "AgentToolProvider probe" "HTTP/HTTPS"
        prometheus -> gridOperator "Scrapes metrics" "HTTP/9090"
        praxisGateway -> peerSite "Cross-site inference forwarding" "HTTPS/8080 mTLS"
        praxisGateway -> inferenceBackends "Proxies inference requests" "HTTP/HTTPS"

        operatorBin -> swimLib "Uses"
        operatorBin -> scoringLib "Uses"
        operatorBin -> certsLib "Uses"
        operatorBin -> crdtLib "Uses"
        overlaySyncSidecar -> kubernetesAPI "Watches ConfigMap" "HTTPS/443"
    }

    views {
        systemContext gridOperator "SystemContext" {
            include *
            autoLayout
        }

        container gridOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
