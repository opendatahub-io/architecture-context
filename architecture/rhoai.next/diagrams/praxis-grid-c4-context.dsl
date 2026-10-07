workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages grid networks, enrolls sites, monitors fleet health"
        dataScientist = person "Data Scientist" "Deploys and consumes inference models across the grid"

        praxisGrid = softwareSystem "Praxis Grid (AGN)" "Distributed control plane connecting AI inference backends across clusters into a routable mesh" {
            operator = container "grid-operator" "Watches CRDs, runs SWIM membership, propagates CRDT state, scores providers, renders routing overlays" "Rust Operator" "core"
            overlaySyncSidecar = container "overlay-sync" "Validates content-addressed overlay envelopes and atomically writes to shared volume" "Rust Sidecar" "core"
            enrollmentService = container "enrollment" "REST API for site registration, certificate signing, and identity rotation" "Rust Service" "core"
            fleetDashboard = container "fleet-dashboard" "Web UI for fleet-wide visibility across sites" "Rust + React" "optional"
            scoringEngine = container "scoring" "Strategy-selected provider scoring: noMetrics, queueDepth, kvCachePressure" "Rust Library" "library"
            certsLib = container "certs" "Certificate generation, mTLS provider trait, SPIFFE-compatible verifier" "Rust Library" "library"
            swimLib = container "swim" "SWIM membership protocol with AES-256-GCM encryption via foca" "Rust Library" "library"
            crdtLib = container "crdt" "Delta CRDTs (LWW register, OR-Set, G-Counter) for convergent state" "Rust Library" "library"
        }

        praxisGateway = softwareSystem "Praxis AI Gateway" "Data-plane gateway handling request routing, API translation, and mTLS" "Internal"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD watches, ConfigMap writes, Secret reads" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Enrollment state storage" "External"
        inferenceBackends = softwareSystem "Inference Backends" "vLLM, llm-d, cloud APIs (OpenAI, Anthropic, Bedrock, Vertex AI)" "External"
        mcpServers = softwareSystem "MCP Servers" "Agentic tool providers (Model Context Protocol)" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via ServiceMonitor" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Optional certificate issuance bootstrap" "Infrastructure"

        # Relationships
        platformAdmin -> praxisGrid "Creates GridNetwork, enrolls sites, monitors fleet" "kubectl / UI"
        dataScientist -> praxisGrid "Creates InferenceProvider and AgentToolProvider CRDs" "kubectl"

        operator -> kubernetesAPI "Watches CRDs, writes ConfigMaps, reads Secrets" "HTTPS/443"
        operator -> inferenceBackends "Health probes and metrics scraping" "HTTP/HTTPS"
        operator -> mcpServers "AgentToolProvider health probing" "Streamable HTTP"
        operator -> operator "Peer SWIM gossip" "UDP/7946 AES-256-GCM"
        operator -> operator "Peer signals polling" "HTTPS/9091 mTLS"

        overlaySyncSidecar -> kubernetesAPI "Watches ConfigMap" "HTTPS/443"
        praxisGateway -> overlaySyncSidecar "Reads overlay from shared volume" "File I/O"

        enrollmentService -> postgresql "Stores enrollment state" "TCP/5432 TLS"
        enrollmentService -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"

        fleetDashboard -> prometheus "Queries per-site Prometheus" "HTTP/HTTPS"

        praxisGrid -> praxisGateway "Writes routing overlay ConfigMaps" "Kubernetes API"
        praxisGateway -> inferenceBackends "Routes inference requests" "HTTPS mTLS"

        prometheus -> praxisGrid "Scrapes operator metrics" "HTTP/9090"
        certManager -> praxisGrid "Optional certificate bootstrap" "Kubernetes API"
    }

    views {
        systemContext praxisGrid "SystemContext" "Praxis Grid in its ecosystem" {
            include *
            autoLayout
        }

        container praxisGrid "Containers" "Internal structure of Praxis Grid" {
            include *
            autoLayout
        }

        styles {
            element "core" {
                background #4a90e2
                color #ffffff
            }
            element "optional" {
                background #7ed321
                color #ffffff
            }
            element "library" {
                background #b8d4f0
                color #333333
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
