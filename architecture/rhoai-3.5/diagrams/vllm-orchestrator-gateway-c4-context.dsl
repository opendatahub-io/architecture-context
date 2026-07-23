workspace {
    model {
        client = person "API Client" "Application or user sending OpenAI-compatible chat completion requests"
        operator = person "Platform Operator" "Configures gateway routes, detectors, and deploys the service"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust-based HTTP gateway providing per-route OpenAI-compatible chat completion endpoints with detector-based content filtering" {
            router = container "axum Router" "Dynamically registers per-route POST endpoints from YAML config" "Rust (axum 0.7.9)"
            headerForwarder = container "Header Forwarder" "Selectively forwards Authorization and X-Forwarded-* headers, drops others" "Rust"
            detectorInjector = container "Detector Injector" "Injects route-specific detector configuration (input/output maps) into request payload" "Rust"
            streamHandler = container "Stream Handler" "Handles SSE streaming responses, per-chunk detection checking, fallback message application" "Rust (futures 0.3.30)"
            nonStreamHandler = container "Non-Stream Handler" "Handles synchronous JSON responses with detection checking and fallback" "Rust"
            tlsClient = container "TLS Client Builder" "Constructs reqwest HTTP client with optional mTLS (PEM→PKCS#12 conversion via openssl crate)" "Rust (reqwest 0.12.12, native-tls, openssl)"
            configLoader = container "Config Loader" "Parses YAML config defining orchestrator endpoint, detectors, and routes; validates detector references" "Rust (serde_yml)"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs chat completion with detector-based guardrails via /api/v2/chat/completions-detection" "Internal RHOAI"
        vllm = softwareSystem "vLLM Inference Server" "LLM inference backend (accessed indirectly via orchestrator)" "Internal RHOAI"
        detectors = softwareSystem "Guardrails Detectors" "Content detection services (e.g., regex-detector) configured in the orchestrator" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift service-ca" "Provides CA certificate for TLS validation" "Platform"
        certSigner = softwareSystem "service-serving-cert-signer" "Provides client TLS certificates for mTLS" "Platform"
        configMap = softwareSystem "Kubernetes ConfigMap" "Stores gateway configuration file (config.yaml)" "Platform"

        # External relationships
        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090, plaintext, Authorization passthrough"
        operator -> configMap "Configures routes and detectors" "kubectl/YAML"

        # Internal container relationships
        client -> router "POST /{route}/v1/chat/completions" "HTTP/8090"
        router -> headerForwarder "Matched request"
        headerForwarder -> nonStreamHandler "Non-streaming request"
        headerForwarder -> streamHandler "Streaming request (stream=true)"
        nonStreamHandler -> detectorInjector "Request with headers"
        streamHandler -> detectorInjector "Request with headers"
        detectorInjector -> tlsClient "Enriched request"
        configLoader -> router "Route definitions"

        # External interactions
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> vllm "Inference requests" "Internal"
        orchestrator -> detectors "Detection requests" "Internal"
        serviceCA -> gateway "CA cert at /etc/tls/ca/service-ca.crt" "File mount"
        certSigner -> gateway "Client cert+key at /etc/tls/private/" "File mount"
        configMap -> gateway "config.yaml via GATEWAY_CONFIG env" "Volume mount"
    }

    views {
        systemContext gateway "SystemContext" {
            include *
            autoLayout
            description "vllm-orchestrator-gateway in the RHOAI TrustyAI guardrails stack"
        }

        container gateway "Containers" {
            include *
            autoLayout
            description "Internal components of the vllm-orchestrator-gateway"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
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
