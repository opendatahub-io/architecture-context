workspace {
    model {
        client = person "Client Application" "Sends OpenAI-compatible chat completion requests with optional content filtering"

        gateway = softwareSystem "vLLM Orchestrator Gateway" "Rust HTTP gateway that routes chat completions through configurable detector pipelines via the FMS Guardrails Orchestrator" {
            axumServer = container "Axum HTTP Server" "Handles incoming OpenAI-compatible requests, performs route-based detector injection, and manages SSE streaming" "Rust / Axum 0.7.9"
            configLoader = container "Config Loader" "Parses YAML config defining orchestrator address, detector definitions, and route-to-detector mappings" "Rust / serde_yml"
            tlsClient = container "TLS Client" "Constructs PKCS#12 identity from PEM files for mTLS communication with orchestrator" "Rust / openssl + native-tls"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service that performs chat completion with detector-based content filtering" "Internal Platform"
        detectors = softwareSystem "Guardrails Detector Services" "Content detection backends (e.g., regex-language for PII)" "Internal Platform"
        vllm = softwareSystem "vLLM Inference Backend" "LLM inference engine for generating chat completions" "Internal Platform"
        trustyai = softwareSystem "TrustyAI Operator" "Consuming operator that deploys and manages the gateway, injects config and TLS secrets" "Internal Platform"
        certManager = softwareSystem "cert-manager / service-serving-cert" "Provisions TLS certificates for mTLS" "External"
        serviceCA = softwareSystem "service-ca-operator" "Provides CA certificates for trust chain validation" "External"

        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090, plaintext, Authorization header"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, plaintext or mTLS"
        orchestrator -> detectors "Runs configured detectors" "Internal"
        orchestrator -> vllm "Generates chat completions" "Internal"
        trustyai -> gateway "Deploys, configures, mounts secrets" "Kubernetes API"
        certManager -> gateway "Provisions TLS certs at /etc/tls/private/" "Volume mount"
        serviceCA -> gateway "Provisions CA cert at /etc/tls/ca/" "Volume mount"

        axumServer -> configLoader "Reads config at startup"
        axumServer -> tlsClient "Configures mTLS for upstream calls"
    }

    views {
        systemContext gateway "SystemContext" {
            include *
            autoLayout
            description "System context showing the vLLM Orchestrator Gateway and its interactions"
        }

        container gateway "Containers" {
            include *
            autoLayout
            description "Internal structure of the vLLM Orchestrator Gateway"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
