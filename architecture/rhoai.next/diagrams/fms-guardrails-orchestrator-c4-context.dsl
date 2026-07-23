workspace {
    model {
        aiApp = person "AI Application Client" "Sends text generation and detection requests"
        sre = person "SRE / Platform Engineer" "Monitors health and observability"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Rust middleware that coordinates AI text generation with content safety guardrails" {
            guardrailsServer = container "Guardrails Server" "REST API server serving guardrails and detection endpoints" "Rust (axum + tokio), Port 8033"
            healthServer = container "Health Server" "Health and info endpoint server" "Rust (axum), Port 8034"
            detectorClient = container "Detector Client" "HTTP client for content analysis services" "reqwest + rustls"
            chunkerClient = container "Chunker Client" "gRPC client for text segmentation services" "tonic + ginepro"
            generationClient = container "Generation Client" "gRPC client abstracting TGIS and Caikit NLP" "tonic + ginepro"
            openaiClient = container "OpenAI Client" "HTTP client for OpenAI-compatible LLM endpoints" "reqwest + rustls"
            detectionBatcher = container "Detection Batcher" "Orders and batches detection results for streaming" "Internal module"
        }

        detectorServices = softwareSystem "Detector Services" "Content analysis services (HAP, toxicity, PII detection)" "Internal Platform"
        chunkerServices = softwareSystem "Chunker Services (Caikit)" "Text segmentation and tokenization services" "Internal Platform"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server (fmaas protocol)" "Internal Platform"
        caikitNlp = softwareSystem "Caikit NLP" "Text generation and tokenization (Caikit protocol)" "Internal Platform"
        openaiLLM = softwareSystem "OpenAI-compatible LLM" "Chat and text completions (e.g., vLLM)" "External/Internal"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metric collection" "Infrastructure"

        # External relationships
        aiApp -> orchestrator "Sends generation and detection requests" "HTTP/HTTPS 8033/TCP"
        sre -> orchestrator "Monitors health" "HTTP 8034/TCP"

        # Internal container relationships
        aiApp -> guardrailsServer "POST /api/v1/* /api/v2/*" "HTTP/HTTPS 8033/TCP, TLS optional"
        sre -> healthServer "GET /health, /info" "HTTP 8034/TCP"
        guardrailsServer -> detectorClient "Dispatches detection tasks"
        guardrailsServer -> chunkerClient "Dispatches chunking tasks"
        guardrailsServer -> generationClient "Dispatches generation tasks"
        guardrailsServer -> openaiClient "Dispatches OpenAI-compatible tasks"
        detectorClient -> detectionBatcher "Feeds detection results"
        detectionBatcher -> guardrailsServer "Returns ordered results"

        # Backend relationships
        orchestrator -> detectorServices "Content detection requests" "HTTP/HTTPS 8080/TCP, TLS configurable"
        orchestrator -> chunkerServices "Text tokenization and chunking" "gRPC 8085/TCP, TLS/mTLS"
        orchestrator -> tgis "Text generation (fmaas)" "gRPC 8033/TCP, TLS/mTLS"
        orchestrator -> caikitNlp "Text generation and tokenization" "gRPC 8085/TCP, TLS/mTLS"
        orchestrator -> openaiLLM "Chat and text completions" "HTTP/HTTPS 8080/TCP, TLS configurable"
        orchestrator -> otlpCollector "Exports traces and metrics" "gRPC 4317/TCP or HTTP 4318/TCP"

        detectorClient -> detectorServices "POST /api/v1/text/*" "HTTP/HTTPS 8080/TCP"
        chunkerClient -> chunkerServices "ChunkerTokenizationTaskPredict" "gRPC 8085/TCP"
        generationClient -> tgis "Generate, GenerateStream" "gRPC 8033/TCP"
        generationClient -> caikitNlp "TextGenerationTaskPredict" "gRPC 8085/TCP"
        openaiClient -> openaiLLM "POST /v1/chat/completions" "HTTP/HTTPS 8080/TCP"
    }

    views {
        systemContext orchestrator "SystemContext" {
            include *
            autoLayout
            description "FMS Guardrails Orchestrator in the RHOAI ecosystem"
        }

        container orchestrator "Containers" {
            include *
            autoLayout
            description "Internal structure of the FMS Guardrails Orchestrator"
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
            element "External/Internal" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
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
        }
    }
}
