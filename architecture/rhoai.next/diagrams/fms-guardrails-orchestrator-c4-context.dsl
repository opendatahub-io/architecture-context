workspace {
    model {
        client = person "API Consumer" "Application or user sending text generation requests with content safety requirements"
        platformAdmin = person "Platform Administrator" "Manages deployment and configuration via rhods-operator"

        guardrailsOrch = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware that orchestrates text generation with content safety detection across multiple downstream services" {
            guardrailsServer = container "Guardrails API Server" "Handles all detection and generation requests with optional TLS/mTLS" "Rust (axum)" {
                tags "Primary"
                router = component "axum Router" "HTTP routing for v1 and v2 API endpoints" "axum 0.8.8"
                orchestrator = component "Orchestrator" "Coordinates detection and generation workflows" "Rust"
                clientMap = component "ClientMap" "Type-erased container holding generation, detector, chunker, and OpenAI clients" "Rust"
                tlsLayer = component "TLS Layer" "rustls with ring crypto backend for TLS 1.2+ / mTLS" "rustls 0.23.36"
            }
            healthServer = container "Health Server" "Reports service health and downstream status over plaintext HTTP" "Rust (axum)" {
                tags "Health"
            }
            otelIntegration = container "OpenTelemetry Integration" "Distributed tracing and metrics with OTLP export" "opentelemetry 0.31.0" {
                tags "Infrastructure"
            }
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server - primary gRPC generation backend" {
            tags "Internal Platform"
        }
        caikitNlp = softwareSystem "caikit-nlp" "Alternative gRPC generation backend via caikit NLP service" {
            tags "Internal Platform"
        }
        chunkers = softwareSystem "caikit Chunkers" "Text chunking service for detection pipelines via gRPC" {
            tags "Internal Platform"
        }
        detectors = softwareSystem "Detector Services" "Content safety detection services exposing REST APIs" {
            tags "Internal Platform"
        }
        openaiServer = softwareSystem "OpenAI-compatible Server" "vLLM or similar server providing OpenAI-compatible chat/text completions" {
            tags "Internal Platform"
        }
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry Collector for traces and metrics aggregation" {
            tags "External"
        }
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that creates deployment, service, and ingress resources" {
            tags "Internal Platform"
        }

        # Relationships - System Context
        client -> guardrailsOrch "Sends generation and detection requests" "HTTP/HTTPS 8033/TCP"
        platformAdmin -> rhodsOperator "Configures and deploys"
        rhodsOperator -> guardrailsOrch "Deploys and manages" "Kubernetes resources"

        guardrailsOrch -> tgis "Text generation and tokenization" "gRPC/HTTP2 8033/TCP, Optional TLS/mTLS"
        guardrailsOrch -> caikitNlp "Alternative text generation" "gRPC/HTTP2 8085/TCP, Optional TLS/mTLS"
        guardrailsOrch -> chunkers "Text chunking for detectors" "gRPC/HTTP2 8085/TCP, Optional TLS/mTLS"
        guardrailsOrch -> detectors "Content safety detection" "HTTP/HTTPS 8080/TCP, Optional TLS/mTLS"
        guardrailsOrch -> openaiServer "Chat/text completions" "HTTP/HTTPS 8080/TCP, Optional TLS, Bearer token"
        guardrailsOrch -> otlpCollector "Exports traces and metrics" "gRPC 4317/TCP or HTTP 4318/TCP"

        # Relationships - Container level
        client -> guardrailsServer "POST /api/v1/*, /api/v2/*" "HTTP/HTTPS 8033/TCP, Optional TLS/mTLS"
        client -> healthServer "GET /health, /info" "HTTP 8034/TCP (plaintext)"

        guardrailsServer -> tgis "Generate, GenerateStream, Tokenize, ModelInfo" "gRPC/HTTP2 8033/TCP"
        guardrailsServer -> caikitNlp "TextGenerationTaskPredict, TokenizationTaskPredict" "gRPC/HTTP2 8085/TCP"
        guardrailsServer -> chunkers "ChunkerTokenizationTaskPredict" "gRPC/HTTP2 8085/TCP"
        guardrailsServer -> detectors "/api/v1/text/contents, /chat, /context/doc, /generation" "HTTP/HTTPS 8080/TCP"
        guardrailsServer -> openaiServer "/v1/chat/completions, /v1/completions, /tokenize" "HTTP/HTTPS 8080/TCP"
        otelIntegration -> otlpCollector "OTLP export" "gRPC 4317/TCP or HTTP 4318/TCP"
    }

    views {
        systemContext guardrailsOrch "SystemContext" {
            include *
            autoLayout
        }

        container guardrailsOrch "Containers" {
            include *
            autoLayout
        }

        component guardrailsServer "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
            }
            element "Health" {
                background #7ed321
            }
            element "Infrastructure" {
                background #bd10e0
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
        }
    }
}
