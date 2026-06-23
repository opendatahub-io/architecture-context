workspace {
    model {
        client = person "AI Application Client" "Sends text generation and content detection requests"

        fmsGuardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API orchestrator that coordinates AI text generation with configurable content safety guardrails" {
            apiServer = container "Guardrails API Server" "Main REST API — routes v1/v2 detection, generation-detection, and OpenAI-compatible endpoints" "Rust (axum)" "8033/TCP"
            healthServer = container "Health Server" "Health check and downstream status reporting" "Rust (axum)" "8034/TCP"
            orchestratorEngine = container "Orchestrator Engine" "Handle<Task> trait dispatch with ClientMap — coordinates parallel calls to downstream services" "Rust"
            clientMap = container "ClientMap" "Type-safe heterogeneous map of DetectorClient, GenerationClient, ChunkerClient, OpenAiClient" "Rust"

            apiServer -> orchestratorEngine "Dispatches typed tasks"
            orchestratorEngine -> clientMap "Resolves downstream clients"
            clientMap -> healthServer "Reports downstream health"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server — gRPC generation backend" "External"
        caikitNlp = softwareSystem "caikit-nlp" "Alternative gRPC generation and tokenization backend" "External"
        openaiServer = softwareSystem "OpenAI-compatible Server (vLLM)" "Chat completions and completions backend" "External"
        detectorServices = softwareSystem "Content Detector Services" "Content safety detection via REST API" "External"
        chunkerServices = softwareSystem "Chunker Services (caikit)" "Text chunking/tokenization via gRPC" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics receiver" "External"

        client -> fmsGuardrailsOrchestrator "Sends generation/detection requests" "HTTP/HTTPS 8033/TCP"
        client -> fmsGuardrailsOrchestrator "Health checks" "HTTP 8034/TCP"

        fmsGuardrailsOrchestrator -> tgis "Text generation and tokenization" "gRPC/HTTP2, Optional mTLS"
        fmsGuardrailsOrchestrator -> caikitNlp "Text generation and tokenization" "gRPC/HTTP2, Optional mTLS"
        fmsGuardrailsOrchestrator -> openaiServer "Chat completions proxy" "HTTP/HTTPS, Bearer Token"
        fmsGuardrailsOrchestrator -> detectorServices "Content safety detection" "HTTP/HTTPS, Optional TLS"
        fmsGuardrailsOrchestrator -> chunkerServices "Text chunking before detection" "gRPC/HTTP2, Optional mTLS"
        fmsGuardrailsOrchestrator -> otlpCollector "Traces and metrics export" "gRPC or HTTP (OTLP)"
    }

    views {
        systemContext fmsGuardrailsOrchestrator "SystemContext" {
            include *
            autoLayout
        }

        container fmsGuardrailsOrchestrator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
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
