workspace {
    model {
        client = person "Client Application" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust/Axum HTTP gateway that proxies chat completion requests through content-safety detectors with mTLS support" {
            httpServer = container "Axum HTTP Server" "Accepts POST /{route}/v1/chat/completions on port 8090" "Rust / Axum / Tokio"
            routeHandler = container "Route Handler" "Matches request path to configured route and resolves detectors" "Rust"
            detectorInjector = container "Detector Injector" "Injects input/output detector parameter maps into the request payload" "Rust"
            orchestratorProxy = container "Orchestrator Proxy" "Forwards augmented payload to guardrails orchestrator via HTTP(S)" "Rust / reqwest"
            detectionChecker = container "Detection Checker" "Evaluates orchestrator response for detections and applies fallback message" "Rust"
            streamHandler = container "Stream Handler" "Handles SSE streaming and JSON response modes" "Rust / Axum"
            tlsConfig = container "TLS Configuration" "Configures mTLS for outbound connections using mounted certificates" "OpenSSL / native-tls"
            configLoader = container "Config Loader" "Loads route and detector definitions from YAML configuration" "serde_yml"
        }

        orchestrator = softwareSystem "TrustAI Guardrails Orchestrator" "Content safety detection service that evaluates inference requests against configured detectors" "Internal RHOAI"
        vllm = softwareSystem "vLLM Inference Endpoint" "LLM inference serving backend" "Internal RHOAI"

        # Relationships
        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP(S) with optional mTLS"
        orchestrator -> vllm "Forwards inference request"

        # Internal container relationships
        httpServer -> routeHandler "Routes request"
        routeHandler -> detectorInjector "Passes matched route config"
        detectorInjector -> orchestratorProxy "Sends augmented payload"
        orchestratorProxy -> detectionChecker "Returns orchestrator response"
        detectionChecker -> streamHandler "Passes final response"
        tlsConfig -> orchestratorProxy "Provides mTLS context"
        configLoader -> routeHandler "Provides route definitions"
        configLoader -> detectorInjector "Provides detector_params"
    }

    views {
        systemContext gateway "SystemContext" {
            include *
            autoLayout
        }

        container gateway "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
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
