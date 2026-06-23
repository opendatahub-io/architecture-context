workspace {
    model {
        user = person "Client Application" "Any OpenAI-compatible client sending chat completion requests"

        vllmOrchestratorGateway = softwareSystem "vLLM Orchestrator Gateway" "Stateless Rust HTTP gateway that routes OpenAI-compatible chat completions through configurable detector pipelines" {
            axumRouter = container "Axum HTTP Router" "Dynamically registers POST /{route_name}/v1/chat/completions endpoints based on YAML config" "Rust / Axum 0.7.9"
            configLoader = container "Config Loader" "Reads and validates gateway YAML configuration at startup; ensures detector references are consistent" "Rust / serde_yml"
            chatHandler = container "Chat Completion Handler" "Transforms OpenAI requests by injecting route-specific detector configurations and forwarding to orchestrator" "Rust / reqwest"
            streamHandler = container "SSE Stream Handler" "Proxies Server-Sent Events from orchestrator, inspecting chunks for detections and applying fallback messages" "Rust / futures"
            tlsBuilder = container "TLS Client Builder" "Probes for Kubernetes-mounted TLS certificates and constructs mTLS-enabled HTTP client; degrades to plaintext if certs absent" "Rust / openssl + native-tls"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs chat completion with detector-based content filtering" "Internal Platform"
        detectors = softwareSystem "Guardrails Detectors" "Content detection services (e.g., regex-language) configured in the orchestrator" "Internal Platform"
        llm = softwareSystem "vLLM / LLM Inference" "Large Language Model server that generates chat completions" "Internal Platform"
        k8sServiceCA = softwareSystem "Kubernetes Service CA" "Provides CA certificates for mTLS verification" "Platform Infrastructure"
        certManager = softwareSystem "cert-manager / service-serving-cert-signer" "Provisions and rotates TLS client certificates" "Platform Infrastructure"

        # User interactions
        user -> vllmOrchestratorGateway "POST /{route}/v1/chat/completions" "HTTP/8090 (plaintext)"

        # Internal container relationships
        configLoader -> axumRouter "Registers route handlers"
        axumRouter -> chatHandler "Routes requests"
        chatHandler -> streamHandler "Delegates streaming requests"
        tlsBuilder -> chatHandler "Provides mTLS-enabled HTTP client"

        # External dependencies
        vllmOrchestratorGateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Invokes configured detectors" "HTTP"
        orchestrator -> llm "Requests chat completions" "HTTP"
        k8sServiceCA -> vllmOrchestratorGateway "Provides CA cert at /etc/tls/ca/service-ca.crt" "File mount"
        certManager -> vllmOrchestratorGateway "Provisions client cert at /etc/tls/private/" "File mount"
    }

    views {
        systemContext vllmOrchestratorGateway "SystemContext" {
            include *
            autoLayout
        }

        container vllmOrchestratorGateway "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Platform Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape Person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
