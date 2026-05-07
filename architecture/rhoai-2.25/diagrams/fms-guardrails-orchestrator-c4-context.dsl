workspace {
    model {
        client = person "Client / Inference Pipeline" "Sends text generation and detection requests via REST API"

        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API orchestrator coordinating AI text generation with safety guardrails through configurable detector, chunker, and LLM backend services" {
            apiServer = container "Guardrails API Server" "axum HTTP/HTTPS server handling v1/v2 REST endpoints with optional TLS (rustls/ring)" "Rust (axum + tokio)" "Service"
            orchestratorCore = container "Orchestrator Core" "Handle<Task> dispatch system with 12 handler implementations for different detection/generation patterns" "Rust" "Component"
            clientLayer = container "Client Layer" "Heterogeneous ClientMap with type-safe downcast, managing gRPC and HTTP clients with per-service TLS" "Rust" "Component"
            detectionBatcher = container "Detection Batcher" "CompletionBatcher and MaxProcessedIndexBatcher for in-order aggregation of concurrent detection results during streaming" "Rust" "Component"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server for model serving via gRPC" "External Backend"
        caikitNlp = softwareSystem "Caikit NLP" "Alternative text generation and tokenization provider via gRPC" "External Backend"
        openaiServer = softwareSystem "OpenAI-compatible Server (vLLM)" "Chat/text completions via HTTP REST API" "External Backend"
        chunkerServices = softwareSystem "Chunker Services (Caikit)" "Text tokenization and chunking via gRPC for detector input preparation" "External Backend"
        detectorServices = softwareSystem "Detector Services" "Content safety analysis (hate speech, PII, toxicity) via HTTP REST" "External Backend"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection via OTLP" "Infrastructure"

        client -> guardrailsOrchestrator "Sends generation/detection requests" "HTTP/HTTPS :8033, Header passthrough"
        guardrailsOrchestrator -> tgis "Text generation (Generate, GenerateStream, Tokenize)" "gRPC :8033, Optional TLS"
        guardrailsOrchestrator -> caikitNlp "Alternative text generation and tokenization" "gRPC :8085, Optional TLS"
        guardrailsOrchestrator -> openaiServer "Chat/text completions" "HTTP :8080, Optional TLS"
        guardrailsOrchestrator -> chunkerServices "Text chunking/tokenization" "gRPC :8085, Optional TLS"
        guardrailsOrchestrator -> detectorServices "Content safety detection" "HTTP :8080, Optional TLS"
        guardrailsOrchestrator -> otelCollector "Exports traces and metrics" "OTLP gRPC :4317 / HTTP :4318"

        apiServer -> orchestratorCore "Dispatches typed task structs"
        orchestratorCore -> clientLayer "Accesses backend clients via ClientMap"
        orchestratorCore -> detectionBatcher "Aggregates streaming detection results"
        clientLayer -> tgis "gRPC calls"
        clientLayer -> caikitNlp "gRPC calls"
        clientLayer -> openaiServer "HTTP calls"
        clientLayer -> chunkerServices "gRPC calls"
        clientLayer -> detectorServices "HTTP calls"
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
            element "External Backend" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #6ba3d6
                color #ffffff
            }
            element "Person" {
                background #7ed321
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
