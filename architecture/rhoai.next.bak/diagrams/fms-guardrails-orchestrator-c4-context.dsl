workspace {
    model {
        aiApp = person "AI Application" "Client application requesting text generation with content safety guardrails"
        platformOp = person "Platform Operator" "Deploys and configures the orchestrator via TrustyAI or KServe"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware that coordinates AI text generation with content safety detection, filtering, and secure generation" {
            apiServer = container "Guardrails API Server" "Handles REST requests for text generation with detection, content detection, and OpenAI-compatible chat/text completions" "Rust (axum)" "8033/TCP"
            healthServer = container "Health Server" "Provides liveness and downstream health status" "Rust (axum)" "8034/TCP"
            clientLayer = container "Client Abstraction Layer" "Trait-based polymorphic clients for detectors, chunkers, and generation backends with DNS-based gRPC load balancing" "Rust (reqwest, tonic, ginepro)"
            detectionBatcher = container "Detection Batcher" "Aggregates streaming text chunks for concurrent detector invocation with chunk and whole-document strategies" "Rust (tokio broadcast channels)"
        }

        detectors = softwareSystem "Detector Services" "Content safety detection services (HAP, PII, etc.) that analyze text for policy violations" "Internal Platform"
        chunkers = softwareSystem "Chunker Services" "caikit-based text tokenization and sentence chunking services" "Internal Platform"
        tgis = softwareSystem "TGIS" "IBM Text Generation Inference Service for text generation via gRPC" "Internal Platform"
        caikitNlp = softwareSystem "caikit-nlp" "caikit NLP service for text generation, tokenization, and classification via gRPC" "Internal Platform"
        openaiSvc = softwareSystem "OpenAI-compatible Server" "vLLM or other OpenAI API-compatible serving backend for chat/text completions" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Collects distributed traces and metrics via OTLP protocol" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Manages TLS certificates for the orchestrator and downstream services" "Infrastructure"

        aiApp -> orchestrator "Sends generation/detection requests via REST API" "HTTP/HTTPS 8033/TCP, TLS 1.2+ optional"
        platformOp -> orchestrator "Deploys as pod, configures TLS and downstream services" "Container image + config.yaml"

        orchestrator -> detectors "Content safety detection requests (concurrent)" "HTTP/HTTPS 8080/TCP, TLS optional, Bearer token optional"
        orchestrator -> chunkers "Text tokenization and chunking" "gRPC 8085/TCP, TLS optional"
        orchestrator -> tgis "Text generation (unary and streaming)" "gRPC 8033/TCP, TLS optional"
        orchestrator -> caikitNlp "Text generation and tokenization" "gRPC 8085/TCP, TLS optional"
        orchestrator -> openaiSvc "Chat/text completions (SSE streaming)" "HTTP/HTTPS 8080/TCP, TLS optional, Bearer token"
        orchestrator -> otelCollector "Exports traces and metrics" "OTLP gRPC 4317/TCP or HTTP 4318/TCP"

        certManager -> orchestrator "Provisions TLS certificates" "kubernetes.io/tls secrets"
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
