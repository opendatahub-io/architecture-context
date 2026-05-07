workspace {
    model {
        client = person "Client Application" "Sends text generation and detection requests via REST API"
        platformAdmin = person "Platform Admin" "Deploys and configures the orchestrator via rhods-operator"

        fmsGuardrails = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware coordinating text generation with content safety detection via multiple upstream services" {
            guardrailsServer = container "Guardrails Server" "Axum HTTP server handling all API requests (v1 legacy, v2 detection, OpenAI-compatible)" "Rust (axum + tokio)" "8033/TCP"
            healthServer = container "Health Server" "Separate health endpoint for Kubernetes liveness/readiness probes" "Rust (axum)" "8034/TCP"
            detectionPipeline = container "Detection Pipeline" "Orchestrates chunking, parallel detection, result aggregation with actor-based batching" "Rust (tokio tasks)"
            grpcClients = container "gRPC Client Layer" "Manages connections to TGIS, Caikit NLP, and Chunker services with ginepro load balancing" "Rust (tonic + ginepro)"
            httpClients = container "HTTP Client Layer" "Manages connections to Detector and OpenAI-compatible services" "Rust (reqwest + rustls)"
            tlsLayer = container "TLS Layer" "Provides server TLS and optional mTLS via rustls with ring crypto backend" "Rust (rustls 0.23.36)"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server for model serving" "External Service"
        caikitNLP = softwareSystem "Caikit NLP" "NLP service for text generation, tokenization, and token classification" "External Service"
        caikitChunkers = softwareSystem "Caikit Chunkers" "Text chunking service for sentence-level segmentation" "External Service"
        detectors = softwareSystem "Detector Services" "Content safety detectors (HAP, PII, etc.)" "External Service"
        openaiVLLM = softwareSystem "OpenAI / vLLM" "OpenAI-compatible completion endpoints" "External Service"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry collector for distributed traces and metrics" "Infrastructure"
        rhodsOperator = softwareSystem "RHODS Operator" "Deploys and manages the orchestrator, creates Routes/HTTPRoutes" "Internal Platform"

        # Relationships
        client -> fmsGuardrails "Sends generation/detection requests" "HTTP/HTTPS 8033/TCP"
        platformAdmin -> rhodsOperator "Configures deployment"

        guardrailsServer -> detectionPipeline "Routes requests through detection stages"
        detectionPipeline -> grpcClients "Sends generation and chunking requests"
        detectionPipeline -> httpClients "Sends detection and completion requests"
        grpcClients -> tlsLayer "Uses for TLS connections"
        httpClients -> tlsLayer "Uses for TLS connections"

        fmsGuardrails -> tgis "Generate, GenerateStream, Tokenize, ModelInfo" "gRPC/8033"
        fmsGuardrails -> caikitNLP "TextGeneration, Tokenization, TokenClassification" "gRPC/8085"
        fmsGuardrails -> caikitChunkers "ChunkerTokenization (unary + bidi streaming)" "gRPC/8085"
        fmsGuardrails -> detectors "Content detection (text, chat, context, generation)" "HTTP/8080"
        fmsGuardrails -> openaiVLLM "Chat/text completions, tokenization" "HTTP/8080"
        fmsGuardrails -> otlpCollector "Export traces and metrics" "gRPC/4317 or HTTP/4318"
        rhodsOperator -> fmsGuardrails "Deploys, manages RBAC, creates Routes"
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
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #000000
            }
            element "Internal Platform" {
                background #7ed321
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
