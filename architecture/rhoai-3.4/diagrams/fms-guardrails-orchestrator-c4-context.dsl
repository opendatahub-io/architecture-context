workspace {
    model {
        aiAppDev = person "AI Application Developer" "Builds AI applications that require content safety guardrails"
        platformAdmin = person "Platform Administrator" "Configures guardrail policies, detectors, and backend connections"

        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API middleware that coordinates AI text generation with content safety guardrails, managing detectors, chunkers, and LLM backends" {
            apiServer = container "Guardrails API Server" "REST API server with v1 (classification) and v2 (detection) endpoints, optional TLS/mTLS" "Rust (axum + hyper), port 8033" "Service"
            healthServer = container "Health Server" "Health and info endpoints with aggregated backend status" "Rust (axum), port 8034" "Service"
            orchestratorCore = container "Orchestrator Core" "Request handlers, task pipeline with concurrent processing (buffer_unordered, broadcast channels)" "Rust (tokio)" "Component"
            tlsLayer = container "TLS Layer" "Server and client TLS/mTLS using rustls with ring crypto backend" "rustls 0.23.36" "Component"
            headerFilter = container "Header Filter" "X-Forwarded-Access-Token to Bearer token rewrite, header passthrough" "Rust" "Component"
            grpcClients = container "gRPC Clients" "TGIS, NLP, and Chunker clients with load-balanced channels (ginepro)" "tonic 0.14.2" "Component"
            httpClients = container "HTTP Clients" "Detector and OpenAI clients with retry logic and TLS support" "reqwest 0.12.28" "Component"
            otelIntegration = container "OpenTelemetry Integration" "Distributed tracing (W3C Trace Context) and metrics export" "opentelemetry 0.31.0" "Component"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server - gRPC text generation backend" "Internal RHOAI"
        caikitNLP = softwareSystem "Caikit NLP Runtime" "gRPC text generation and tokenization backend" "Internal RHOAI"
        caikitChunker = softwareSystem "Caikit Chunker Service" "gRPC text chunking and tokenization service" "Internal RHOAI"
        detectorServices = softwareSystem "Detector Services" "Content safety detection services (HAP, PII, groundedness, etc.)" "Internal RHOAI"
        openaiServer = softwareSystem "OpenAI-compatible Server" "vLLM or similar server providing OpenAI-compatible chat/completions API" "Internal RHOAI"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metric collection" "Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "Infrastructure"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator managing deployment, routes, and ingress" "Internal RHOAI"

        # Person relationships
        aiAppDev -> guardrailsOrchestrator "Sends prompts with guardrail configs via REST API" "HTTP/HTTPS 8033/TCP"
        platformAdmin -> guardrailsOrchestrator "Configures detectors, backends, and TLS via config.yaml"

        # Internal container relationships
        apiServer -> orchestratorCore "Routes requests to handlers"
        apiServer -> tlsLayer "TLS termination and mTLS verification"
        apiServer -> headerFilter "Filters and rewrites auth headers"
        orchestratorCore -> grpcClients "Generation and chunking requests"
        orchestratorCore -> httpClients "Detection and OpenAI requests"
        orchestratorCore -> otelIntegration "Trace spans and metrics"
        healthServer -> grpcClients "Backend health checks (gRPC Health.check)"
        healthServer -> httpClients "Backend health checks (HTTP GET /health)"

        # External system relationships
        guardrailsOrchestrator -> tgis "Text generation (generate, generate_stream, tokenize)" "gRPC/8033 Optional TLS/mTLS"
        guardrailsOrchestrator -> caikitNLP "Text generation and tokenization" "gRPC/8085 Optional TLS/mTLS"
        guardrailsOrchestrator -> caikitChunker "Text chunking/tokenization" "gRPC/8085 Optional TLS/mTLS"
        guardrailsOrchestrator -> detectorServices "Content safety detection" "HTTP/8080 Optional TLS/mTLS"
        guardrailsOrchestrator -> openaiServer "Chat/text completions" "HTTP/8080 Optional TLS"
        guardrailsOrchestrator -> otlpCollector "Trace and metric export" "gRPC/4317 or HTTP/4318"
        certManager -> guardrailsOrchestrator "Provisions TLS certificates"
        rhodsOperator -> guardrailsOrchestrator "Deploys and manages service, creates Routes/HTTPRoutes"
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
            element "Internal RHOAI" {
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
            element "Service" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
                background #85BBF0
                color #000000
            }
        }
    }
}
