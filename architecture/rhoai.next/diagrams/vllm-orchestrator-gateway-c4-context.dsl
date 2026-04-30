workspace {
    model {
        datascientist = person "Data Scientist / Application" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP gateway providing configurable detector-based content filtering routes for OpenAI-compatible chat completions" {
            routeHandler = container "Route Handler" "Dynamically registered POST /{route_name}/v1/chat/completions endpoints" "Rust / axum"
            configLoader = container "Config Loader" "Reads YAML configuration defining detectors, routes, and orchestrator settings" "serde_yml"
            streamHandler = container "SSE Stream Handler" "Processes chunked SSE responses, checking each chunk for detections" "futures::StreamExt"
            detectionChecker = container "Detection Checker" "Inspects orchestrator responses for detections and substitutes fallback messages" "Rust"
            tlsBuilder = container "TLS Client Builder" "Constructs mTLS client from PEM certs at well-known paths" "openssl + native-tls"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service performing LLM generation and detector evaluation" "Internal RHOAI"
        detectors = softwareSystem "Guardrails Detectors" "Content detection services (e.g., regex-language, PII, safety)" "Internal RHOAI"
        vllm = softwareSystem "vLLM / Model Server" "LLM inference backend for chat completion generation" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / OpenShift service-ca" "Provisions and rotates TLS certificates" "Platform"

        datascientist -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Runs configured content detectors" "Internal"
        orchestrator -> vllm "Inference requests" "Internal"
        certManager -> gateway "Provisions TLS certs at /etc/tls/private/" "File mount"

        routeHandler -> configLoader "Loads route definitions at startup"
        routeHandler -> streamHandler "Delegates streaming responses"
        routeHandler -> detectionChecker "Checks for content policy violations"
        routeHandler -> tlsBuilder "Uses mTLS client for orchestrator"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
