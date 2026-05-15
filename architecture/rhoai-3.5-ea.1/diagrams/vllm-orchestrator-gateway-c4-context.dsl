workspace {
    model {
        user = person "Client Application" "Application or user sending chat completion requests to an LLM with content safety guardrails"

        vllmOrchestratorGateway = softwareSystem "vllm-orchestrator-gateway" "OpenAI-compatible HTTP gateway that routes chat completion requests through configurable detector-based content filtering pipelines" {
            gateway = container "Gateway Service" "HTTP gateway that injects detector configurations into requests and forwards to orchestrator; supports streaming (SSE) and non-streaming responses" "Rust / axum 0.7.9" "Service"
            configLoader = container "Config Loader" "Reads YAML configuration defining orchestrator connection, detector definitions, and route-to-detector mappings" "serde_yml" "Configuration"
            tlsBuilder = container "TLS Client Builder" "Constructs PKCS#12 identity from PEM certificates for mTLS communication with orchestrator" "openssl / native-tls" "Security"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs content detection and routes LLM inference requests; receives enriched requests from gateway" "Internal TrustyAI"
        detectors = softwareSystem "Detector Services" "Content detection services (e.g., regex-language for PII detection); invoked by orchestrator" "Internal TrustyAI"
        vllm = softwareSystem "vLLM Model Server" "LLM inference backend serving chat completions; invoked by orchestrator" "Internal"
        platformIngress = softwareSystem "Platform Ingress" "HTTPRoute or OpenShift Route providing external access, TLS termination, and authentication" "External Platform"
        certManager = softwareSystem "cert-manager / service-ca" "Provisions and rotates TLS certificates for mTLS communication" "External Platform"

        # External relationships
        user -> vllmOrchestratorGateway "POST /{route}/v1/chat/completions" "HTTP/8090"
        platformIngress -> vllmOrchestratorGateway "Routes external traffic" "HTTP/8090"
        vllmOrchestratorGateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Content detection requests" "HTTP"
        orchestrator -> vllm "Chat completion inference" "HTTP"
        certManager -> vllmOrchestratorGateway "Provisions TLS certs at /etc/tls/private/" "Volume mount"

        # Internal container relationships
        configLoader -> gateway "Provides route and detector configuration" "YAML"
        tlsBuilder -> gateway "Provides mTLS client identity" "PKCS#12"
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
            element "Internal TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #f9f9f9
                color #333333
                shape Person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
            }
            element "Configuration" {
                shape Cylinder
            }
            element "Security" {
                shape Hexagon
            }
        }
    }
}
