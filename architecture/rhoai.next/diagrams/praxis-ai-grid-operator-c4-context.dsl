workspace {
    model {
        gridAdmin = person "Grid Admin" "Manages the AI grid mesh, mints enrollment tokens"
        dataSciUser = person "Client / Data Scientist" "Sends inference requests to AI models"

        agnOperator = softwareSystem "AI Grid Network (AGN) Operator" "Distributed control plane for multi-site AI inference routing" {
            operator = container "Operator" "K8s controllers (GridNetwork, GridSite, InferenceProvider, AgentToolProvider), SWIM runtime, scoring engine, overlay renderer" "Rust Binary" "Primary"
            enrollment = container "Enrollment Service" "mTLS site-token onboarding, CSR signing, certificate rotation" "Rust Binary"
            gridGateway = container "Grid Gateway" "Praxis-based data-plane gateway for inter-site inference traffic with mTLS" "Rust Binary (Pingora)"
            overlaySync = container "Overlay-Sync Sidecar" "Watches routing-overlay ConfigMaps and delivers changes to gateway filesystem" "Rust Binary"
            fleetDashboard = container "Fleet Dashboard" "Optional web UI for fleet map and per-site health" "Rust (Axum + React)"
            scoring = container "Scoring Library" "Strategy-selected scoring engine: noMetrics, queueDepth, kvCachePressure" "Rust Library"
            certs = container "Certs Library" "Certificate generation, mTLS provider, SPIFFE verification" "Rust Library"
            swim = container "SWIM Library" "foca-based membership protocol, AES-256-GCM gossip encryption, CRDT broadcast" "Rust Library"
        }

        peerSite = softwareSystem "Peer Site AGN Operator" "Another site's operator instance in the mesh" "Peer"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches, Secret reads, ConfigMap writes" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Durable enrollment token and certificate state store" "Database"
        certManager = softwareSystem "cert-manager" "Optional CA certificate provisioning" "Infrastructure"
        praxisGateway = softwareSystem "Praxis AI Gateway" "Consumes routing overlay ConfigMaps for request routing" "Internal"
        mcpServers = softwareSystem "MCP Tool Servers" "Agent tool endpoints probed via Model Context Protocol" "External"
        inferenceBackend = softwareSystem "Inference Backend" "Model-serving backends: llm-d, Bedrock, Vertex, Anthropic, OpenAI" "External"

        # External interactions
        gridAdmin -> enrollment "Mints enrollment tokens" "HTTPS/8443 TLS"
        dataSciUser -> gridGateway "Sends inference requests" "HTTPS"

        # Operator internals
        operator -> k8sAPI "Watches CRDs, reads Secrets, writes ConfigMaps" "HTTPS/443 TLS"
        operator -> scoring "Scores provider candidates"
        operator -> swim "SWIM membership protocol"
        operator -> certs "Certificate operations"

        # Enrollment
        enrollment -> postgresql "Stores enrollment state" "TCP/5432"
        enrollment -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443"

        # Peer communication
        operator -> peerSite "SWIM gossip (membership)" "UDP/7946 AES-256-GCM"
        operator -> peerSite "Signals polling (health/metrics)" "HTTPS/9091 mTLS"

        # Data plane
        gridGateway -> peerSite "Inter-site inference routing" "HTTPS mTLS"
        gridGateway -> inferenceBackend "Routes to model backend" "HTTPS"
        overlaySync -> k8sAPI "Watches routing overlay ConfigMap" "HTTPS/443"
        operator -> praxisGateway "Writes routing overlay ConfigMaps" "K8s API"

        # Optional
        operator -> mcpServers "Probes AgentToolProvider endpoints" "HTTPS (rmcp)"
        operator -> certManager "References for CA provisioning" "K8s API"
    }

    views {
        systemContext agnOperator "SystemContext" {
            include *
            autoLayout
        }

        container agnOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Peer" {
                background #e87d4a
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Primary" {
                background #1a5276
                color #ffffff
            }
        }
    }
}
