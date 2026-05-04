workspace {
    model {
        apiClient = person "API Client" "Application or user consuming OpenAI-compatible chat completion endpoints"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP gateway providing route-based OpenAI-compatible chat completion endpoints with configurable detector pipelines for content filtering" {
            router = container "axum Router" "Dynamically registers routes from YAML config; maps /{route}/v1/chat/completions to proxy handler" "Rust/axum"
            proxyHandler = container "Proxy Handler" "Injects detector configuration into payload, forwards to orchestrator, applies fallback messages on detections" "Rust"
            streamProcessor = container "SSE Stream Processor" "Processes orchestrator SSE stream chunk-by-chunk, applying fallback logic per chunk" "Rust"
            configLoader = container "Config Loader" "Parses YAML config defining orchestrator connection, detector definitions, and route-to-detector mappings" "Rust/serde_yml"
            tlsBuilder = container "TLS Client Builder" "Constructs mTLS identity (PEM → PKCS#12 via openssl crate) for secure orchestrator communication" "Rust/openssl"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs actual content detection on chat completions, manages detector invocation and model routing" "Internal TrustyAI"
        detectors = softwareSystem "Content Detectors" "Detection servers (e.g., regex-detector) that analyze input/output content for policy violations" "Internal TrustyAI"
        vllm = softwareSystem "vLLM Model Server" "LLM inference backend serving model predictions" "Internal"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for mTLS" "External Platform"
        serviceCaOperator = softwareSystem "service-ca-operator" "Provides CA certificates for trusting internal service certificates" "External Platform"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and manages lifecycle of gateway, creates Kubernetes Service and mounts secrets" "Internal RHOAI"

        apiClient -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090, plaintext, optional Auth header"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS, Auth forwarded"
        orchestrator -> detectors "Invokes content detection" "Internal"
        orchestrator -> vllm "Routes inference requests" "Internal"
        certManager -> gateway "Provisions TLS cert/key" "kubernetes.io/tls secret volume mount"
        serviceCaOperator -> gateway "Provisions CA certificate" "Opaque secret volume mount"
        trustyaiOperator -> gateway "Deploys, creates Service, mounts config/secrets" "Kubernetes API"
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
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
                background #50e3c2
                color #000000
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
