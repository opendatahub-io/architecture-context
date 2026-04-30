workspace {
    model {
        user = person "API Consumer" "Application or service sending text generation requests with safety guardrails"
        platformOp = person "Platform Operator" "Deploys and configures the orchestrator and downstream services"

        fmsGuardrails = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware that coordinates AI text generation with content safety guardrails" {
            apiServer = container "API Server" "Handles guardrails API requests (v1 + v2), orchestrates detection and generation workflows" "Rust (Axum + Tokio)" "8033/TCP"
            healthServer = container "Health Server" "Provides liveness (/health) and readiness (/info) endpoints, probes downstream services" "Rust (Axum)" "8034/TCP"
            orchestrationEngine = container "Orchestration Engine" "Coordinates parallel detector calls, manages streaming fan-out, applies threshold policies" "Rust (Tokio async)"
            tgisClient = container "TGIS Client" "gRPC client for Text Generation Inference Server" "Rust (tonic + ginepro)"
            nlpClient = container "Caikit NLP Client" "gRPC client for Caikit NLP text generation" "Rust (tonic)"
            chunkerClient = container "Chunker Client" "gRPC client for text tokenization/chunking" "Rust (tonic)"
            detectorClient = container "Detector Client" "HTTP client for content safety detection services" "Rust (reqwest)"
            openaiClient = container "OpenAI Client" "HTTP client for OpenAI-compatible APIs (vLLM)" "Rust (reqwest + eventsource-stream)"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server - gRPC-based LLM serving" "External Platform"
        caikitNlp = softwareSystem "Caikit NLP" "Caikit runtime NLP service for text generation and classification" "External Platform"
        chunkerService = softwareSystem "Chunker Service" "Caikit Chunkers service for text tokenization" "External Platform"
        detectorService = softwareSystem "Detector Service(s)" "Content safety detection services (HAP, toxicity, profanity, etc.)" "External Platform"
        vllm = softwareSystem "OpenAI-compatible API (vLLM)" "vLLM or other OpenAI-compatible LLM serving endpoint" "External Platform"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Collects distributed traces and metrics via OTLP" "External Infrastructure"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing health probes" "External Infrastructure"

        # User interactions
        user -> fmsGuardrails "Sends text generation and detection requests" "HTTP/HTTPS 8033/TCP"
        kubernetes -> fmsGuardrails "Sends health probes" "HTTP/HTTPS 8034/TCP"
        platformOp -> fmsGuardrails "Configures via config.yaml, CLI args, and env vars"

        # Internal container relationships
        apiServer -> orchestrationEngine "Delegates request processing"
        orchestrationEngine -> tgisClient "Sends generation requests"
        orchestrationEngine -> nlpClient "Sends generation requests"
        orchestrationEngine -> chunkerClient "Sends chunking requests"
        orchestrationEngine -> detectorClient "Sends detection requests"
        orchestrationEngine -> openaiClient "Sends completion requests"

        # External dependencies
        fmsGuardrails -> tgis "Text generation (Generate, GenerateStream, Tokenize, ModelInfo)" "gRPC/8033 mTLS optional"
        fmsGuardrails -> caikitNlp "Text generation and tokenization" "gRPC/8085 mTLS optional"
        fmsGuardrails -> chunkerService "Text chunking and tokenization" "gRPC/8085 mTLS optional"
        fmsGuardrails -> detectorService "Content detection (HAP, toxicity, chat, context)" "HTTP/8080 TLS optional"
        fmsGuardrails -> vllm "Chat/text completions and tokenization" "HTTP/8080 TLS optional"
        fmsGuardrails -> otlpCollector "Export traces and metrics" "gRPC/4317 or HTTP/4318"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External Platform" {
                background #7ed321
                color #000000
            }
            element "External Infrastructure" {
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
