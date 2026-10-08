workspace {
    model {
        client = person "Client Application" "Sends text generation and detection requests"
        platformOp = person "Platform Operator" "Configures orchestrator, manages TLS certs and API tokens"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware that coordinates text generation with content safety guardrails" {
            guardrailsServer = container "Guardrails Server" "Primary API server handling detection and generation orchestration" "Rust (axum), Port 8033" {
                headerFilter = component "Header Passthrough" "Filters and forwards configured headers, rewrites X-Forwarded-Access-Token to Bearer" "axum middleware"
                taskHandlers = component "Task Handlers" "Dispatches typed task objects to appropriate handler pipelines" "Rust"
                tlsLayer = component "TLS Layer" "Server TLS and optional mTLS via rustls + ring" "rustls 0.23"
            }
            healthServer = container "Health Server" "Unauthenticated health and info endpoints" "Rust (axum), Port 8034"
        }

        tgis = softwareSystem "TGIS Generation Service" "Text generation via TGIS gRPC API" "Internal Platform"
        caikitNlp = softwareSystem "Caikit-NLP Generation Service" "Text generation via caikit-nlp gRPC API" "Internal Platform"
        openaiSvc = softwareSystem "OpenAI-Compatible Service" "Chat and text completions via OpenAI-compatible API" "Internal Platform"
        detectors = softwareSystem "Detector Services" "Content safety detection (HAP, etc.)" "Internal Platform"
        chunkers = softwareSystem "Chunker Services" "Text segmentation and chunking for detectors" "Internal Platform"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics collection" "Infrastructure"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration and health probing" "Infrastructure"

        client -> orchestrator "Sends generation/detection requests" "HTTP/HTTPS :8033"
        platformOp -> orchestrator "Configures via YAML and env vars"
        kubernetes -> orchestrator "Probes /health and /info" "HTTP :8034"

        orchestrator -> tgis "Text generation requests" "gRPC :8033, TLS optional"
        orchestrator -> caikitNlp "Text generation requests" "gRPC, TLS optional"
        orchestrator -> openaiSvc "Chat/text completions" "HTTP/HTTPS, API token"
        orchestrator -> detectors "Content detection requests" "HTTP/HTTPS :8080, Bearer optional"
        orchestrator -> chunkers "Text chunking requests" "gRPC :8085, TLS optional"
        orchestrator -> otlp "Exports traces and metrics" "gRPC or HTTP"
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

        component guardrailsServer "Components" {
            include *
            autoLayout
        }

        styles {
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
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
