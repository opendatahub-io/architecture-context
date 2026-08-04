workspace {
    model {
        apiConsumer = person "API Consumer" "Application or user sending inference requests through the guardrails pipeline"
        platformOperator = person "Platform Operator" "Configures TLS, secrets, and deployment of the orchestrator"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Rust-based guardrails orchestration service that intercepts LLM inference requests and applies configurable content detection" {
            guardrailsServer = container "Guardrails Server" "Handles guardrails API requests on port 8033, orchestrates fan-out to downstream services" "Rust (axum)" {
                tags "Primary"
            }
            healthServer = container "Health Server" "Serves health and info endpoints on port 8034 without authentication" "Rust (axum)" {
                tags "Secondary"
            }
            grpcClient = container "gRPC Client" "Communicates with TGIS and Chunker services via tonic gRPC" "Rust (tonic)" {
                tags "Client"
            }
            restClient = container "REST Client" "Communicates with Detector services via reqwest HTTP client" "Rust (reqwest)" {
                tags "Client"
            }
            tlsLayer = container "TLS Layer" "Optional TLS and mTLS using rustls with ring crypto provider (NOT FIPS-validated)" "Rust (rustls + ring)" {
                tags "Security"
            }
        }

        tgis = softwareSystem "TGIS Generation Service" "Text Generation Inference Server for LLM text generation" "External Service" {
            tags "Downstream"
        }
        chunkerServices = softwareSystem "Chunker Services" "Text segmentation services accessed via gRPC" "External Service" {
            tags "Downstream"
        }
        detectorServices = softwareSystem "Detector Services" "Content analysis and detection services accessed via REST" "External Service" {
            tags "Downstream"
        }
        detectorHealthServices = softwareSystem "Detector Health Services" "Health endpoints for detector services" "External Service" {
            tags "Downstream"
        }
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry collector for traces and metrics" "External Service" {
            tags "Observability"
        }

        # Relationships
        apiConsumer -> orchestrator "Sends inference/detection requests" "HTTP/HTTPS :8033, TLS 1.2+ optional"
        platformOperator -> orchestrator "Configures TLS certs, secrets, YAML config"

        guardrailsServer -> grpcClient "Delegates gRPC calls"
        guardrailsServer -> restClient "Delegates REST calls"
        guardrailsServer -> tlsLayer "Terminates TLS"
        healthServer -> restClient "Probes downstream health"

        orchestrator -> tgis "Sends generation requests" "gRPC :8033, no encryption"
        orchestrator -> chunkerServices "Sends chunking requests" "gRPC :8085, TLS optional"
        orchestrator -> detectorServices "Sends detection requests" "REST :8080, TLS optional, Bearer optional"
        orchestrator -> detectorHealthServices "Probes health" "REST :8081, no encryption"
        orchestrator -> otlpCollector "Exports traces and metrics" "OTLP gRPC/HTTP"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Downstream" {
                background #999999
                color #ffffff
            }
            element "Observability" {
                background #8b5cf6
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
            }
            element "Secondary" {
                background #7ed321
            }
            element "Client" {
                background #f5a623
            }
            element "Security" {
                background #e8544f
            }
        }
    }
}
