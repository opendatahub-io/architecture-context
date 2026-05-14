workspace {
    model {
        client = person "API Consumer" "Application or service sending text generation or detection requests"
        k8sAdmin = person "Platform Operator" "Deploys and configures the orchestrator via rhods-operator"

        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware coordinating AI text generation with content safety guardrails" {
            guardrailsServer = container "Guardrails Server" "Handles all /api/v1/* and /api/v2/* endpoints; routes requests through detection pipelines" "Rust (axum + tokio), 8033/TCP"
            healthServer = container "Health Server" "Provides /health and /info endpoints for Kubernetes probes" "Rust (axum), 8034/TCP"
            generationClient = container "GenerationClient" "Unified abstraction over TGIS and Caikit NLP backends" "Rust (tonic + ginepro gRPC)"
            chunkerClient = container "ChunkerClient" "gRPC client for text chunking services" "Rust (tonic + ginepro gRPC)"
            detectorClient = container "DetectorClient" "HTTP client for content safety detector services" "Rust (reqwest HTTP)"
            openaiClient = container "OpenAIClient" "HTTP client for OpenAI-compatible / vLLM backends" "Rust (reqwest HTTP)"
            tlsLayer = container "TLS Layer" "Manages server TLS and mTLS via rustls with ring crypto backend" "rustls 0.23.36"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server — gRPC-based LLM generation backend" "Internal Platform"
        caikitNlp = softwareSystem "Caikit NLP" "gRPC-based NLP service for generation, tokenization, and classification" "Internal Platform"
        caikitChunkers = softwareSystem "Caikit Chunkers" "gRPC-based text chunking service for sentence segmentation" "Internal Platform"
        detectorServices = softwareSystem "Detector Services" "Content safety detectors (HAP, PII, etc.) — REST API" "Internal Platform"
        openaiVllm = softwareSystem "OpenAI / vLLM" "OpenAI-compatible chat/completion generation backend — REST API" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry collector for distributed traces and metrics" "Observability"
        certManager = softwareSystem "cert-manager" "Manages TLS certificate lifecycle" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys and manages RHOAI components including guardrails orchestrator" "Internal Platform"

        # External relationships
        client -> guardrailsOrchestrator "Sends generation and detection requests" "HTTP(S)/8033, Optional TLS/mTLS"
        k8sAdmin -> rhodsOperator "Configures deployment"
        rhodsOperator -> guardrailsOrchestrator "Deploys and manages" "Kubernetes API"
        certManager -> guardrailsOrchestrator "Provisions TLS certificates" "kubernetes.io/tls secrets"

        # Internal container relationships
        guardrailsServer -> generationClient "Delegates text generation"
        guardrailsServer -> chunkerClient "Requests text chunking"
        guardrailsServer -> detectorClient "Requests content detection"
        guardrailsServer -> openaiClient "Delegates OpenAI-compatible requests"
        guardrailsServer -> tlsLayer "TLS termination and mTLS"
        healthServer -> generationClient "Checks upstream health"
        healthServer -> detectorClient "Checks upstream health"

        # Upstream dependencies
        guardrailsOrchestrator -> tgis "Generate, GenerateStream, Tokenize, ModelInfo" "gRPC/8033, Optional TLS"
        guardrailsOrchestrator -> caikitNlp "TextGeneration, Tokenization, TokenClassification" "gRPC/8085, Optional TLS"
        guardrailsOrchestrator -> caikitChunkers "ChunkerTokenization (unary + bidi streaming)" "gRPC/8085, Optional TLS"
        guardrailsOrchestrator -> detectorServices "Content detection (text, chat, context, generation)" "HTTP(S)/8080, Optional Bearer"
        guardrailsOrchestrator -> openaiVllm "Chat/text completions, tokenization" "HTTP(S)/8080, Optional Bearer"
        guardrailsOrchestrator -> otlpCollector "Exports traces and metrics" "gRPC/4317 or HTTP/4318, Plaintext"
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
            element "Observability" {
                background #f5a623
                color #ffffff
            }
            element "External" {
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
