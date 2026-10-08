workspace {
    model {
        client = person "API Client" "Application or user sending text generation/detection requests"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Rust-based middleware that coordinates AI text generation with content safety guardrails" {
            guardrailsServer = container "Guardrails Server" "Primary API server serving detection and generation endpoints" "Rust (axum)" {
                tags "Primary"
            }
            healthServer = container "Health Server" "Lightweight health/info server for probes" "Rust (axum)" {
                tags "Health"
            }
            orchestratorCore = container "Orchestrator Core" "Fan-out coordinator dispatching tasks to detectors, chunkers, and generation backends" "Rust"
            clientMap = container "Client Map" "Dynamic client registry with trait-object downcasting for heterogeneous service types" "Rust"
            tlsLayer = container "TLS Layer" "rustls with ring crypto provider (NOT FIPS-validated)" "Rust (rustls)"
        }

        tgis = softwareSystem "TGIS Generation Service" "Text generation via gRPC BatchedGenerationRequest API" "Internal Platform"
        caikitNlp = softwareSystem "Caikit NLP Service" "Text generation via caikit-nlp gRPC API (alternative to TGIS)" "Internal Platform"
        openaiService = softwareSystem "OpenAI-compatible Service" "Chat and text completions via OpenAI-compatible HTTP API" "Internal Platform"
        detectors = softwareSystem "Detector Services" "Content safety detection services (contents, chat, context-doc, generation)" "Internal Platform"
        chunkers = softwareSystem "Chunker Services" "Text chunking services for breaking input into detector-sized pieces" "Internal Platform"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics collector" "External"

        # Relationships
        client -> orchestrator "Sends detection/generation requests" "HTTP/HTTPS 8033/TCP"
        client -> orchestrator "Health checks" "HTTP 8034/TCP"

        orchestrator -> tgis "Text generation requests with retry" "gRPC 8033/TCP TLS (optional)"
        orchestrator -> caikitNlp "Text generation requests with retry" "gRPC TLS (optional)"
        orchestrator -> openaiService "Chat/text completions" "HTTP/HTTPS TLS (optional)"
        orchestrator -> detectors "Content safety detection" "HTTP/HTTPS 8080/TCP TLS (optional)"
        orchestrator -> chunkers "Text chunking" "gRPC 8085/TCP TLS (optional)"
        orchestrator -> otlp "Traces and metrics" "gRPC/HTTP"

        # Container-level relationships
        guardrailsServer -> orchestratorCore "Routes tasks"
        orchestratorCore -> clientMap "Dispatches to clients"
        guardrailsServer -> tlsLayer "TLS termination"
    }

    views {
        systemContext orchestrator "SystemContext" {
            include *
            autoLayout
        }

        container orchestrator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Health" {
                background #6baed6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
