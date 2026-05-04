workspace {
    model {
        client = person "API Client" "Application or user sending text generation or detection requests"
        k8sAdmin = person "Platform Operator" "Deploys and configures the orchestrator via rhods-operator"

        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware coordinating text generation with content safety detection via multiple upstream services" {
            guardrailsServer = container "Guardrails Server" "Handles all API requests, orchestrates detection pipeline, manages streaming responses" "Rust (axum + tokio), 8033/TCP"
            healthServer = container "Health Server" "Provides liveness and readiness probe endpoints" "Rust (axum), 8034/TCP"
            generationClient = container "GenerationClient" "Abstraction layer wrapping TGIS or NLP backends with unified interface" "Rust (tonic gRPC)"
            detectorClient = container "DetectorClient" "HTTP client for content safety detector services with retry logic" "Rust (reqwest)"
            chunkerClient = container "ChunkerClient" "gRPC client for text chunking services (unary + bidirectional streaming)" "Rust (tonic gRPC)"
            openaiClient = container "OpenAIClient" "HTTP client for OpenAI-compatible generation endpoints" "Rust (reqwest)"
            tlsLayer = container "TLS Layer" "Configurable TLS/mTLS via rustls with ring crypto backend" "rustls 0.23.36"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server for model serving" "Internal Platform"
        caikitNlp = softwareSystem "Caikit NLP" "NLP generation, tokenization, and classification backend" "Internal Platform"
        caikitChunker = softwareSystem "Caikit Chunkers" "Text chunking service for sentence-level segmentation" "Internal Platform"
        detectorServices = softwareSystem "Detector Services" "Content safety detectors (HAP, PII, etc.)" "Internal Platform"
        openaiVllm = softwareSystem "OpenAI / vLLM" "OpenAI-compatible completion endpoints" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metric collection" "Infrastructure"

        # Relationships - External
        client -> guardrailsOrchestrator "Sends generation/detection requests" "HTTP/HTTPS 8033/TCP"
        k8sAdmin -> guardrailsOrchestrator "Deploys and configures" "YAML config + env vars"

        # Relationships - Internal containers
        guardrailsServer -> generationClient "Routes generation requests"
        guardrailsServer -> detectorClient "Routes detection requests"
        guardrailsServer -> chunkerClient "Routes chunking requests"
        guardrailsServer -> openaiClient "Routes OpenAI-format requests"
        guardrailsServer -> tlsLayer "TLS termination and client certs"

        # Relationships - Upstream
        generationClient -> tgis "Generate, GenerateStream, Tokenize RPCs" "gRPC 8033/TCP, Optional TLS"
        generationClient -> caikitNlp "TextGeneration, Tokenization RPCs" "gRPC 8085/TCP, Optional TLS"
        chunkerClient -> caikitChunker "ChunkerTokenization RPCs (unary + bidi streaming)" "gRPC 8085/TCP, Optional TLS"
        detectorClient -> detectorServices "POST /api/v1/text/* detection endpoints" "HTTP/HTTPS 8080/TCP, Optional Bearer"
        openaiClient -> openaiVllm "POST /v1/chat/completions, /v1/completions" "HTTP/HTTPS 8080/TCP, Optional Bearer"
        guardrailsServer -> otlpCollector "Export traces and metrics" "gRPC 4317/TCP or HTTP 4318/TCP"
    }

    views {
        systemContext guardrailsOrchestrator "SystemContext" {
            include *
            autoLayout
        }

        container guardrailsOrchestrator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
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
        }
    }
}
