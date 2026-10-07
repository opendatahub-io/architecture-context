workspace {
    model {
        client = person "API Consumer" "Sends text generation and detection requests to the orchestrator"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Rust-based REST API orchestrator coordinating AI text generation with content safety guardrails" {
            guardrailsServer = container "Guardrails Server" "HTTP/HTTPS API server handling v1, v2, and OpenAI-compatible endpoints" "Rust (axum)" {
                tags "Internal"
            }
            healthServer = container "Health Server" "Separate HTTP listener for health and info endpoints" "Rust (axum)" {
                tags "Internal"
            }
            orchestratorCore = container "Orchestrator Core" "Task-based dispatch engine coordinating detectors, chunkers, and generators" "Rust" {
                tags "Internal"
            }
            tlsLayer = container "TLS Layer" "Named TLS config system with rustls+ring provider, optional server TLS and mTLS" "Rust (rustls)" {
                tags "Internal"
            }
        }

        tgis = softwareSystem "TGIS Generation Service" "Text generation via TGIS or caikit-nlp gRPC API" {
            tags "External Downstream"
        }
        chunker = softwareSystem "Chunker Services" "Text chunking (sentence splitting) for detector input preparation" {
            tags "External Downstream"
        }
        detector = softwareSystem "Detector Services" "Content safety detection (HAP, toxicity, etc.) via REST API" {
            tags "External Downstream"
        }
        openaiSvc = softwareSystem "OpenAI-Compatible Service" "Chat and text completions via OpenAI API format" {
            tags "External Downstream"
        }
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics collection" {
            tags "Observability"
        }
        kubernetes = softwareSystem "Kubernetes Platform" "Container orchestration, health probes, secret management" {
            tags "Platform"
        }

        client -> orchestrator "Sends generation/detection requests" "HTTP/HTTPS 8033/TCP"
        kubernetes -> orchestrator "Health probes" "HTTP 8034/TCP"

        orchestrator -> tgis "Text generation requests" "gRPC 8033/TCP"
        orchestrator -> chunker "Text chunking requests" "gRPC 8085/TCP"
        orchestrator -> detector "Content safety detection" "HTTP/HTTPS 8080/TCP"
        orchestrator -> openaiSvc "Chat/text completions" "HTTP/HTTPS configurable"
        orchestrator -> otlp "Traces and metrics export" "gRPC/HTTP configurable"

        guardrailsServer -> orchestratorCore "Dispatches typed tasks"
        orchestratorCore -> tlsLayer "Uses for downstream TLS"
        healthServer -> orchestratorCore "Queries client health status"
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
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External Downstream" {
                background #999999
                color #ffffff
            }
            element "Observability" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
