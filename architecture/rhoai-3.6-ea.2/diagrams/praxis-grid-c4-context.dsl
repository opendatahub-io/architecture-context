workspace {
    model {
        admin = person "Platform Admin" "Manages Grid networks, enrolls sites, and configures inference providers"
        datascientist = person "Data Scientist" "Sends inference requests through the gateway"

        praxisGrid = softwareSystem "Praxis Grid (AGN)" "Distributed control plane connecting AI inference backends across clusters into a routable mesh" {
            operator = container "Grid Operator" "Watches GridNetwork, GridSite, InferenceProvider, AgentToolProvider CRDs; runs SWIM runtime; renders routing overlay ConfigMaps" "Rust Operator" "Primary"
            scoringEngine = container "Scoring Engine" "Pluggable provider selection: noMetrics, queueDepth, kvCachePressure strategies" "Rust Library"
            swimRuntime = container "SWIM Runtime" "Membership discovery and CRDT state replication via foca with AES-256-GCM encryption" "Rust Library"
            crdtEngine = container "CRDT Engine" "Delta CRDTs (LWW registers, OR-Sets, G-Counters) for distributed state" "Rust Library"
            certsMgr = container "Certificate Manager" "mTLS certificate lifecycle, SPIFFE-aware verification, rcgen/OpenSSL dual backend" "Rust Library"
            overlaySyncSidecar = container "Overlay Sync Sidecar" "Watches ConfigMap changes, writes routing overlay to gateway filesystem" "Rust Sidecar"
            enrollmentServer = container "Enrollment Server" "Site registration with token-based auth, certificate issuance, identity rotation" "Rust Service"
            fleetDashboard = container "Fleet Dashboard" "Fleet map and per-site health UI" "Rust (Axum) + React" "Optional"
        }

        praxisGateway = softwareSystem "Praxis AI Gateway" "Request-path AI gateway that hot-reloads routing overlays from ConfigMaps" "Internal"
        peerSiteOperator = softwareSystem "Peer Site Operator" "Grid operator instance at another cluster/site" "Internal"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD watches, Secret/ConfigMap management" "External"
        postgresql = softwareSystem "PostgreSQL" "Enrollment state persistence" "External"
        certManager = softwareSystem "cert-manager" "Optional certificate issuance integration" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor" "External"
        providerBackends = softwareSystem "Provider Backends" "AI inference backends (OpenAI, Anthropic, Bedrock, Vertex AI, llm-d)" "External"
        mcpServers = softwareSystem "MCP Tool Servers" "Model Context Protocol tool server endpoints" "External"

        # Admin interactions
        admin -> praxisGrid "Creates GridNetwork, enrolls sites, registers providers via kubectl" "HTTPS/443"
        admin -> enrollmentServer "Mints enrollment tokens" "HTTPS mTLS"

        # Data scientist interactions
        datascientist -> praxisGateway "Sends inference requests" "HTTPS"

        # Internal container relationships
        operator -> scoringEngine "Scores providers"
        operator -> swimRuntime "Manages membership"
        swimRuntime -> crdtEngine "Replicates state"
        operator -> certsMgr "Manages certificates"
        operator -> kubernetesAPI "Watches CRDs, writes ConfigMaps/Secrets" "HTTPS/443"
        overlaySyncSidecar -> kubernetesAPI "Watches ConfigMap changes" "HTTPS/443"
        overlaySyncSidecar -> praxisGateway "Writes overlay to filesystem" "Local file"

        # Cross-site communication
        swimRuntime -> peerSiteOperator "SWIM gossip and CRDT replication" "UDP/7946 AES-256-GCM"
        operator -> peerSiteOperator "Cross-site signals polling" "TCP/9091 mTLS"

        # External dependencies
        enrollmentServer -> postgresql "Persists enrollment state" "TCP/5432 TLS"
        operator -> providerBackends "Health probing" "HTTP(S) TLS 1.2+"
        operator -> mcpServers "AgentToolProvider probing" "Streamable HTTP/TLS"
        praxisGrid -> certManager "Optional cert integration"
        praxisGrid -> prometheusOp "Metrics via ServiceMonitor" "HTTP(S)/9090"

        # Gateway integration
        praxisGrid -> praxisGateway "Routing overlay via ConfigMap" "Kubernetes API"
        praxisGateway -> peerSiteOperator "Cross-site request routing" "HTTPS/443 mTLS"
    }

    views {
        systemContext praxisGrid "SystemContext" {
            include *
            autoLayout
        }

        container praxisGrid "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #82b366
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
