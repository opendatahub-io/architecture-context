workspace {
    model {
        user = person "AI Application Client" "Sends text generation and detection requests via REST API"

        guardrailsOrch = softwareSystem "FMS Guardrails Orchestrator" "Rust-based REST API orchestrator coordinating AI text generation with content safety guardrails" {
            guardrailsServer = container "Guardrails API Server" "Main REST API server handling generation and detection requests with optional TLS/mTLS" "Rust (axum)" {
                v1Handlers = component "V1 Task Handlers" "Classification with text generation (unary and streaming)" "axum handlers"
                v2Handlers = component "V2 Detection Handlers" "Content, chat, context, generated text detection" "axum handlers"
                openaiHandlers = component "OpenAI Handlers" "Chat/text completions with guardrails (conditional)" "axum handlers"
                orchestrator = component "Orchestration Engine" "Coordinates detection, chunking, and generation workflows" "Handle<Task> trait"
            }
            healthServer = container "Health Server" "Plaintext HTTP server for health and service info endpoints" "Rust (axum)" {
                tags "Health"
            }
            genClient = container "Generation Client" "Unified gRPC client for TGIS and Caikit NLP backends with retry logic" "Rust (tonic)"
            openaiClient = container "OpenAI Client" "HTTP client for OpenAI-compatible backends" "Rust (reqwest)"
            chunkerClient = container "Chunker Client" "gRPC client for Caikit chunker service" "Rust (tonic)"
            detectorClient = container "Detector Client" "HTTP client for content safety detector services" "Rust (reqwest)"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server - gRPC text generation backend" {
            tags "Internal Platform"
        }
        caikitNlp = softwareSystem "Caikit NLP" "Alternative gRPC text generation backend" {
            tags "Internal Platform"
        }
        caikitChunkers = softwareSystem "Caikit Chunkers" "gRPC text chunking/tokenization service" {
            tags "Internal Platform"
        }
        detectors = softwareSystem "Detector Services" "Content safety detection services (HAP, PII, etc.)" {
            tags "Internal Platform"
        }
        openaiServer = softwareSystem "OpenAI-compatible Server" "vLLM or similar chat/text completions backend" {
            tags "Internal Platform"
        }
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry collector for traces and metrics" {
            tags "Observability"
        }

        # User interactions
        user -> guardrailsOrch "Sends generation/detection requests" "HTTP/HTTPS (8033/TCP)"

        # Internal container relationships
        guardrailsServer -> genClient "Delegates generation" "Internal"
        guardrailsServer -> openaiClient "Delegates OpenAI generation" "Internal"
        guardrailsServer -> chunkerClient "Delegates chunking" "Internal"
        guardrailsServer -> detectorClient "Delegates detection" "Internal"

        # Outbound dependencies
        genClient -> tgis "Generate, GenerateStream, Tokenize, ModelInfo" "gRPC/HTTP2 (8033/TCP)"
        genClient -> caikitNlp "TextGenerationTaskPredict, TokenizationTaskPredict" "gRPC/HTTP2 (8085/TCP)"
        chunkerClient -> caikitChunkers "ChunkerTokenizationTaskPredict, BidiStreaming" "gRPC/HTTP2 (8085/TCP)"
        detectorClient -> detectors "POST /api/v1/text/{contents,chat,context/doc,generation}" "HTTP/HTTPS (8080/TCP)"
        openaiClient -> openaiServer "POST /v1/chat/completions, /v1/completions" "HTTP/HTTPS (8080/TCP)"
        guardrailsOrch -> otlpCollector "Export traces and metrics" "gRPC (4317) or HTTP (4318)"

        # Health checks
        healthServer -> tgis "gRPC health check" "gRPC"
        healthServer -> caikitNlp "gRPC health check" "gRPC"
        healthServer -> caikitChunkers "gRPC health check" "gRPC"
        healthServer -> detectors "HTTP health check" "HTTP (8081/TCP)"
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
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Observability" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Health" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
