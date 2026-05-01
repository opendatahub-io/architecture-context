workspace {
    model {
        client = person "API Consumer" "Application or service requesting text generation with safety guardrails"

        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware that coordinates AI text generation with content safety guardrails" {
            apiServer = container "API Server" "Handles guardrails API requests, orchestrates detection and generation pipelines" "Rust (axum + tokio)" "Port 8033"
            healthServer = container "Health Server" "Isolated liveness/readiness checks, probes all downstream services" "Rust (axum)" "Port 8034"
            orchestrationEngine = container "Orchestration Engine" "Coordinates parallel detector calls, manages streaming pipelines, applies score thresholds" "Tokio async tasks"
            tlsManager = container "TLS Manager" "Manages server TLS termination and client mTLS connections using named TLS profiles" "rustls + ring"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server - gRPC-based text generation" "Internal Platform"
        caikitNlp = softwareSystem "Caikit NLP" "Caikit NLP service for text generation and tokenization" "Internal Platform"
        chunkerService = softwareSystem "Chunker Service" "Text chunking/tokenization for detector processing" "Internal Platform"
        detectorServices = softwareSystem "Detector Services" "Content safety detectors (HAP, toxicity, profanity, etc.)" "Internal Platform"
        openaiApi = softwareSystem "OpenAI-compatible API (vLLM)" "Chat and text completions via OpenAI-compatible REST API" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives OTLP traces and metrics for distributed observability" "Infrastructure"

        client -> guardrailsOrchestrator "Sends text generation/detection requests" "HTTP/8033, TLS optional"
        guardrailsOrchestrator -> tgis "Text generation (unary + streaming)" "gRPC/8033, mTLS optional"
        guardrailsOrchestrator -> caikitNlp "Text generation and tokenization" "gRPC/8085, mTLS optional"
        guardrailsOrchestrator -> chunkerService "Text chunking/tokenization" "gRPC/8085, mTLS optional"
        guardrailsOrchestrator -> detectorServices "Content detection (parallel calls)" "HTTP/8080, TLS optional"
        guardrailsOrchestrator -> openaiApi "Chat/text completions (SSE streaming)" "HTTP/8080, TLS optional"
        guardrailsOrchestrator -> otelCollector "Export traces and metrics" "OTLP gRPC/4317 or HTTP/4318"

        apiServer -> orchestrationEngine "Delegates request processing"
        orchestrationEngine -> tlsManager "Uses for downstream connections"
        healthServer -> tgis "Health probes" "gRPC"
        healthServer -> caikitNlp "Health probes" "gRPC"
        healthServer -> chunkerService "Health probes" "gRPC"
        healthServer -> detectorServices "Health probes" "HTTP/8081"
        healthServer -> openaiApi "Health probes" "HTTP"
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
                background #438DD5
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
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
