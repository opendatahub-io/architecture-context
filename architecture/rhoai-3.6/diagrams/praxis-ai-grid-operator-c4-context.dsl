workspace {
    model {
        admin = person "Platform Admin" "Manages grid networks, enrolls sites, and configures providers"
        dataScientist = person "Data Scientist / Developer" "Sends inference requests through the grid gateway"

        agn = softwareSystem "Praxis AI Grid Operator (AGN)" "Distributed control plane connecting AI inference backends across clusters into a routable mesh" {
            operator = container "Grid Operator" "Kubernetes controllers for GridNetwork, GridSite, InferenceProvider, AgentToolProvider; SWIM runtime; overlay renderer" "Rust Operator (kube-rs)"
            enrollment = container "Enrollment Service" "Site onboarding with private CA, token minting, certificate issuance" "Rust (Axum)"
            gridGateway = container "Grid Gateway" "Data-plane proxy with AGN routing filters, API translation, credential injection" "Rust (Praxis/Pingora)"
            overlaySync = container "Overlay Sync Sidecar" "Watches ConfigMap, writes overlay to local file for fast gateway reload" "Rust"
            scoringEngine = container "Scoring Engine" "Pluggable provider scoring: noMetrics, queueDepth, kvCachePressure" "Rust Library"
            crdtEngine = container "CRDT Engine" "Last-Writer-Wins registers, OR-Sets, G-Counters for distributed state" "Rust Library"
            swimRuntime = container "SWIM Runtime" "Gossip-based peer discovery via foca with AES-256-GCM packet encryption" "Rust Library (foca)"
            certsLib = container "Certs Library" "Certificate generation (rcgen), mTLS provider trait" "Rust Library"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        postgres = softwareSystem "Postgres" "Enrollment token and state persistence" "External"
        praxisGateway = softwareSystem "Praxis AI Gateway" "Data-plane proxy consuming routing overlay" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        inferenceBackends = softwareSystem "Inference Backends" "vLLM, llm-d, Cloud APIs (OpenAI, Anthropic, Bedrock, Vertex)" "External"
        mcpServers = softwareSystem "MCP Tool Servers" "Agentic tool endpoints (Model Context Protocol)" "External"

        // Relationships
        admin -> enrollment "Enrolls sites, mints tokens" "HTTPS/8443, mTLS"
        dataScientist -> gridGateway "Sends inference requests" "HTTPS, Bearer token"

        operator -> k8sApi "Watches CRDs, writes ConfigMaps, reads Secrets" "HTTPS/443"
        operator -> swimRuntime "Manages peer mesh" ""
        swimRuntime -> swimRuntime "Gossip with remote peers" "UDP/7946, AES-256-GCM"
        operator -> scoringEngine "Scores providers" ""
        operator -> crdtEngine "Propagates state" ""
        operator -> overlaySync "Writes routing overlay ConfigMap" "Kubernetes API"

        enrollment -> postgres "Stores enrollment state" "PostgreSQL/5432, TLS"
        enrollment -> certsLib "Generates certificates" ""

        overlaySync -> gridGateway "Writes overlay file" "Local filesystem"
        gridGateway -> inferenceBackends "Routes inference requests" "HTTPS, injected credentials"
        gridGateway -> gridGateway "Inter-site routing" "HTTPS, mTLS"

        operator -> mcpServers "Probes AgentToolProvider endpoints" "HTTP/HTTPS, rmcp"
        prometheus -> operator "Scrapes metrics" "HTTP/9090"

        praxisGateway -> operator "Consumes routing overlay" "ConfigMap"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
