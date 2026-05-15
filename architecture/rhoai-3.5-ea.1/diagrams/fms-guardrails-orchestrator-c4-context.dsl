workspace {
    model {
        client = person "API Client" "Application or service sending text generation and detection requests"

        guardrailsOrch = softwareSystem "FMS Guardrails Orchestrator" "REST API orchestration server coordinating AI text generation with content safety guardrails" {
            mainApi = container "Main API Server" "Handles all guardrails API endpoints (v1 and v2) with optional TLS/mTLS" "Rust (axum)" "8033/TCP"
            orchEngine = container "Orchestration Engine" "Handler dispatch, detection batching, streaming aggregation via actor pattern" "Rust (tokio)"
            healthServer = container "Health Server" "Liveness and dependency health status" "Rust (axum)" "8034/TCP"
            tlsLayer = container "TLS Layer" "rustls + ring crypto provider, optional mTLS with WebPkiClientVerifier" "rustls 0.23"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server — gRPC-based text generation" "Generation Backend"
        caikitNlp = softwareSystem "caikit-NLP" "Red Hat NLP runtime — gRPC-based text generation and tokenization" "Generation Backend"
        openaiSrv = softwareSystem "OpenAI-compatible Server" "vLLM or similar — HTTP-based chat/text completions" "Generation Backend"

        detectors = softwareSystem "Detector Services" "Content safety detectors (HAP, PII, harmful content) — HTTP REST API" "Safety Service"
        chunkers = softwareSystem "Chunker Services" "caikit-based text chunking/tokenization — gRPC" "Safety Service"

        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection via OTLP" "Observability"

        # Relationships
        client -> guardrailsOrch "Sends text generation and detection requests" "HTTP/HTTPS 8033/TCP, Optional mTLS"

        guardrailsOrch -> tgis "Text generation (Generate, GenerateStream, Tokenize)" "gRPC 8033/TCP, Optional TLS/mTLS"
        guardrailsOrch -> caikitNlp "Text generation, tokenization, classification" "gRPC 8085/TCP, Optional TLS/mTLS"
        guardrailsOrch -> openaiSrv "Chat/text completions, tokenization" "HTTP/HTTPS 8080/TCP, Optional Bearer"
        guardrailsOrch -> detectors "Content safety detection (PII, HAP, etc.)" "HTTP/HTTPS 8080/TCP, Optional Bearer"
        guardrailsOrch -> chunkers "Text chunking and tokenization" "gRPC 8085/TCP, Optional TLS/mTLS"
        guardrailsOrch -> otelCollector "Exports traces and metrics" "OTLP gRPC 4317/TCP or HTTP 4318/TCP"

        # Internal container relationships
        mainApi -> orchEngine "Dispatches requests to handlers"
        mainApi -> tlsLayer "TLS termination and mTLS verification"
        orchEngine -> tgis "gRPC client calls"
        orchEngine -> caikitNlp "gRPC client calls"
        orchEngine -> openaiSrv "HTTP client calls"
        orchEngine -> detectors "HTTP client calls"
        orchEngine -> chunkers "gRPC client calls"
        healthServer -> tgis "gRPC Health.Check"
        healthServer -> caikitNlp "gRPC Health.Check"
        healthServer -> openaiSrv "GET /health"
        healthServer -> detectors "GET /health"
        healthServer -> chunkers "gRPC Health.Check"
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

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Generation Backend" {
                background #999999
                color #ffffff
            }
            element "Safety Service" {
                background #f5a623
                color #333333
            }
            element "Observability" {
                background #7ed321
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
