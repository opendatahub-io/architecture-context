workspace {
    model {
        client = person "Client Application" "Sends text generation requests with guardrails detection"

        fmsGuardrails = softwareSystem "FMS Guardrails Orchestrator" "Rust-based REST API orchestrator coordinating AI text generation with content safety guardrails" {
            apiServer = container "REST API Server" "Accepts guardrails requests on port 8033, routes through detection/generation pipeline" "Rust (axum/hyper)" "Service"
            healthServer = container "Health Server" "Health and info endpoints on port 8034" "Rust (axum)" "Service"
            generationClient = container "GenerationClient" "gRPC client abstraction over TGIS and Caikit NLP backends with retry logic" "Rust (tonic)" "Client"
            openAiClient = container "OpenAiClient" "OpenAI-compatible HTTP client for LLM backends" "Rust (reqwest)" "Client"
            detectorClient = container "DetectorClient" "HTTP client calling detector service REST APIs for content analysis" "Rust (reqwest)" "Client"
            chunkerClient = container "ChunkerClient" "gRPC client calling Caikit chunker services for text segmentation" "Rust (tonic)" "Client"
            detectionBatchStream = container "DetectionBatchStream" "Multiplexes parallel detection streams with pluggable batching strategies" "Rust (tokio)" "Processor"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server providing GenerationService gRPC API" "External Backend"
        caikitNlp = softwareSystem "Caikit NLP Service" "NLP service providing text generation via NlpService gRPC API" "External Backend"
        caikitChunker = softwareSystem "Caikit Chunker Service" "Text chunking/tokenization via ChunkersService gRPC API" "External Backend"
        detectorServices = softwareSystem "Detector Service(s)" "Content safety detection services with REST API" "External Backend"
        openAiLlm = softwareSystem "OpenAI-compatible LLM" "LLM backend (e.g., vLLM) providing chat/text completions" "External Backend"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Collects distributed traces and metrics via OTLP" "Infrastructure"

        client -> fmsGuardrails "Sends guardrails requests" "HTTP/HTTPS 8033/TCP, TLS+mTLS optional"

        apiServer -> generationClient "Routes generation requests"
        apiServer -> openAiClient "Routes OpenAI-compatible requests"
        apiServer -> detectorClient "Routes detection requests"
        apiServer -> chunkerClient "Routes chunking requests"
        apiServer -> detectionBatchStream "Coordinates streaming detection"

        generationClient -> tgis "Text generation" "gRPC 8033/TCP, TLS/mTLS"
        generationClient -> caikitNlp "Text generation" "gRPC 8085/TCP, TLS/mTLS"
        chunkerClient -> caikitChunker "Text chunking" "gRPC 8085/TCP, TLS/mTLS"
        detectorClient -> detectorServices "Content detection" "HTTP/HTTPS 8080/TCP, Bearer token"
        openAiClient -> openAiLlm "Chat/text completions" "HTTP/HTTPS 8080/TCP, Bearer token"
        fmsGuardrails -> otelCollector "Traces and metrics" "OTLP gRPC 4317/TCP"
    }

    views {
        systemContext fmsGuardrails "SystemContext" {
            include *
            autoLayout
        }

        container fmsGuardrails "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Backend" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #c7c7c7
                color #333333
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Client" {
                background #6baed6
                color #ffffff
            }
            element "Processor" {
                background #9ecae1
                color #333333
            }
            element "Person" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
