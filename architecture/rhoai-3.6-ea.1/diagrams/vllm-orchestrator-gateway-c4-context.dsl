workspace {
    model {
        client = person "API Client" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "OpenAI-compatible HTTP gateway that routes chat completion requests through configurable detector-based content filtering" {
            configLoader = container "Config Loader" "Parses YAML configuration defining routes, detectors, and orchestrator backend" "Rust (serde_yml)"
            axumRouter = container "Axum Router" "Dynamic HTTP router generating POST endpoints per configured route" "Rust (Axum 0.7)"
            requestHandler = container "Request Handler" "Injects detector configurations and proxies requests to orchestrator" "Rust (reqwest)"
            streamProcessor = container "Stream Processor" "Handles SSE streaming responses with detection-aware fallback" "Rust (futures)"
            tlsClient = container "TLS Client Builder" "Builds HTTP client with optional mTLS using OpenSSL PKCS#12 identity" "Rust (native-tls, openssl)"
        }

        orchestrator = softwareSystem "vLLM Orchestrator" "Backend service processing chat completions with detector-based content filtering" "Internal RHOAI"

        # Relationships
        client -> gateway "POST /{route_name}/v1/chat/completions" "HTTP/8090, Authorization header optional"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/configurable, mTLS when certs present"

        # Internal container relationships
        configLoader -> axumRouter "Route definitions and detector configs"
        axumRouter -> requestHandler "Matched route request"
        requestHandler -> tlsClient "HTTP client for backend calls"
        requestHandler -> streamProcessor "SSE response handling"
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
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
