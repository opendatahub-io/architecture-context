workspace {
    model {
        client = person "API Client" "Sends text generation requests requiring content safety enforcement"

        guardrailsOrch = softwareSystem "FMS Guardrails Orchestrator" "Rust middleware that coordinates AI text generation with content safety guardrails" {
            apiServer = container "HTTP API Server" "Exposes REST endpoints for detection and generation orchestration" "Rust (axum + hyper)"
            orchestrationEngine = container "Orchestration Engine" "Routes requests through input detection → generation → output detection pipeline" "Rust (tokio async)"
            detectionBatcher = container "Detection Batcher" "Manages concurrent streaming detection with ordered batch correlation" "Rust (tokio::select!)"
            httpClient = container "HTTP Client" "Communicates with detector and OpenAI-compatible services" "Rust (reqwest)"
            grpcClient = container "gRPC Client" "Communicates with TGIS, NLP, and chunker services" "Rust (tonic)"
            tlsLayer = container "TLS Layer" "Configurable TLS/mTLS for server and client connections" "Rust (rustls + ring)"
            otelExporter = container "OTel Exporter" "Exports distributed traces and metrics" "Rust (opentelemetry)"
        }

        detectorServices = softwareSystem "Detector Services" "Content safety classification services (HAP, PII, toxicity)" "External"
        chunkerServices = softwareSystem "Chunker Services (Caikit)" "Text segmentation services for detection pipelines" "External"
        tgisService = softwareSystem "TGIS Generation Service" "Text generation via TGIS gRPC API" "External"
        caikitNlpService = softwareSystem "Caikit NLP Service" "Text generation and tokenization via Caikit NLP gRPC API" "External"
        openaiService = softwareSystem "OpenAI-Compatible Service" "Chat/text completions via OpenAI-compatible HTTP API" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metric collection" "External"
        platformGateway = softwareSystem "Platform Gateway" "kube-rbac-proxy / OAuth proxy for authentication and authorization" "Internal RHOAI"
        platformOperator = softwareSystem "Platform Operator (rhods-operator)" "Manages deployment, RBAC, NetworkPolicy, and TLS certificates" "Internal RHOAI"

        client -> platformGateway "Sends requests via" "HTTPS/443"
        platformGateway -> guardrailsOrch "Forwards authenticated requests to" "HTTP(S)/8033"
        guardrailsOrch -> detectorServices "Sends content for classification" "HTTP(S)/8080"
        guardrailsOrch -> chunkerServices "Sends text for segmentation" "gRPC/8085"
        guardrailsOrch -> tgisService "Sends generation requests" "gRPC/8033"
        guardrailsOrch -> caikitNlpService "Sends generation requests" "gRPC/8085"
        guardrailsOrch -> openaiService "Sends chat/text completions" "HTTP(S)/8080"
        guardrailsOrch -> otlpCollector "Exports traces and metrics" "gRPC/4317 or HTTP/4318"
        platformOperator -> guardrailsOrch "Manages deployment, certs, RBAC" "Kubernetes API"
    }

    views {
        systemContext guardrailsOrch "SystemContext" {
            include *
            autoLayout
        }

        container guardrailsOrch "Containers" {
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
            element "Internal RHOAI" {
                background #7ed321
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
