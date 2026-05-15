workspace {
    model {
        client = person "Client Application" "Sends text generation requests with guardrails requirements"
        operator = person "Platform Operator" "Deploys and configures the orchestrator via TrustyAI stack"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API orchestrator coordinating AI text generation with content safety guardrails (Rust/axum+tonic)" {
            apiServer = container "Guardrails API Server" "Handles REST API requests, routes to orchestration handlers" "Rust (axum)" "8033/TCP"
            orchestrationEngine = container "Orchestration Engine" "Implements Handle<Task> trait for each workflow type (unary, streaming, detection-only)" "Rust (tokio)"
            streamingPipeline = container "Streaming Pipeline" "Broadcast channels, concurrent detection streams, DetectionBatcher, CompletionState" "Rust (tokio::sync)"
            clientLayer = container "Client Layer" "gRPC clients (tonic) for generation/chunker, HTTP clients (reqwest) for detectors/OpenAI" "Rust (tonic, reqwest)"
            healthServer = container "Health Server" "Health check and backend status endpoints" "Rust (axum)" "8034/TCP"
            tlsLayer = container "TLS Layer" "Server TLS/mTLS (rustls/ring), per-service client TLS" "Rust (rustls)"
        }

        tgis = softwareSystem "TGIS Generation Server" "Text Generation Inference Server — gRPC text generation" "External Backend"
        caikitNlp = softwareSystem "Caikit NLP Server" "gRPC NLP service for generation, tokenization, classification" "External Backend"
        chunker = softwareSystem "Caikit Chunker Service" "gRPC text segmentation service for detection pipeline" "External Backend"
        detectors = softwareSystem "Detector Services" "HTTP REST content safety detectors (HAP, PII, etc.)" "External Backend"
        vllm = softwareSystem "OpenAI-compatible Service (vLLM)" "HTTP REST chat/text completions with streaming" "External Backend"
        otlpCollector = softwareSystem "OTLP Collector" "Receives OpenTelemetry traces and metrics" "Observability"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, health probes" "Platform"

        client -> orchestrator "Sends guardrailed generation/detection requests" "HTTPS/8033, TLS 1.2+"
        operator -> orchestrator "Configures via config.yaml and environment variables"

        orchestrator -> tgis "Text generation (Generate, GenerateStream, Tokenize)" "gRPC/8033, mTLS"
        orchestrator -> caikitNlp "Text generation, tokenization, classification" "gRPC/8085, mTLS"
        orchestrator -> chunker "Text chunking (unary and bidi-streaming)" "gRPC/8085, mTLS"
        orchestrator -> detectors "Content detection (contents, chat, context, generation)" "HTTP/8080, TLS + Bearer"
        orchestrator -> vllm "Chat/text completions, tokenization" "HTTP/8080, TLS + Bearer"
        orchestrator -> otlpCollector "Exports traces and metrics" "gRPC/4317 or HTTP/4318"
        kubernetes -> orchestrator "Liveness/readiness probes" "HTTP/8034"

        apiServer -> orchestrationEngine "Dispatches tasks via Handle<Task>"
        orchestrationEngine -> streamingPipeline "Creates streaming pipelines for SSE endpoints"
        orchestrationEngine -> clientLayer "Calls backend services"
        streamingPipeline -> clientLayer "Concurrent backend calls with ordering"
        apiServer -> tlsLayer "TLS termination and client verification"
        clientLayer -> tlsLayer "Per-service TLS configuration"
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
                background #4a90e2
                color #ffffff
            }
            element "External Backend" {
                background #999999
                color #ffffff
            }
            element "Observability" {
                background #9673a6
                color #ffffff
            }
            element "Platform" {
                background #d6b656
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
