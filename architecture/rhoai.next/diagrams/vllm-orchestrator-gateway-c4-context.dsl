workspace {
    model {
        apiClient = person "API Client" "Application or user consuming OpenAI-compatible chat completion endpoints"

        gateway = softwareSystem "vLLM Orchestrator Gateway" "Rust/axum HTTP gateway that provides route-based OpenAI-compatible chat completion endpoints with configurable detector-based content filtering" {
            router = container "axum Router" "Dynamic route registration from YAML config; maps /{route}/v1/chat/completions to detector pipelines" "Rust/axum"
            detectorInjector = container "Detector Injector" "Augments client request payload with configured detector specifications before forwarding" "Rust"
            streamHandler = container "SSE Stream Handler" "Processes orchestrator SSE stream chunk-by-chunk, applying fallback logic per-chunk" "Rust/futures"
            fallbackHandler = container "Fallback Handler" "Checks response for detections; replaces content with configured fallback message if detections found" "Rust"
            tlsClient = container "mTLS Client Builder" "Constructs PKCS#12 identity from PEM cert/key via OpenSSL for native-tls transport" "Rust/openssl+native-tls"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs content detection on chat completions using configured detector servers" "Internal TrustyAI"
        detectors = softwareSystem "Content Detectors" "Detection servers (e.g., regex-detector) that analyze input/output for content safety" "Internal TrustyAI"
        vllm = softwareSystem "vLLM Model Server" "LLM inference backend serving model predictions" "Internal TrustyAI"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for mTLS" "External Platform"
        serviceCA = softwareSystem "service-ca-operator" "Provides CA certificates for internal service trust" "External Platform"

        apiClient -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090, plaintext, Authorization passthrough"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS, forwarded Authorization"
        orchestrator -> detectors "Invokes content detection" "Internal"
        orchestrator -> vllm "Routes inference requests" "Internal"
        certManager -> gateway "Provisions TLS cert/key" "Volume mount /etc/tls/private/"
        serviceCA -> gateway "Provisions CA certificate" "Volume mount /etc/tls/ca/"
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
            element "Internal TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
