workspace {
    model {
        user = person "API Client" "Application or user sending chat completion requests to an LLM with guardrails"

        gatewaySystem = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP reverse proxy that routes OpenAI-compatible chat completion requests through configurable detector pipelines" {
            gateway = container "vllm-orchestrator-gateway" "Stateless HTTP proxy with config-driven route generation, detector injection, and fallback message handling" "Rust/axum" {
                router = component "axum Router" "Dynamically generates /{route}/v1/chat/completions endpoints from config.yaml"
                configLoader = component "Config Loader" "Parses config.yaml to build route-to-detector mappings" "serde_yml"
                detectorInjector = component "Detector Injector" "Injects input/output detector configuration into request payload before forwarding"
                fallbackHandler = component "Fallback Handler" "Replaces response content with fallback_message when detections are found"
                streamHandler = component "SSE Stream Handler" "Processes chunked SSE responses, checking each chunk for detections" "futures/tokio"
                tlsClient = component "mTLS Client" "Builds PKCS12 identity from OpenShift service-serving certs for outbound mTLS" "openssl/native-tls"
            }
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs LLM inference with detector-based content filtering" "Internal TrustyAI"
        detectors = softwareSystem "Detector Services" "Content detection services (PII, regex-based filters) called by orchestrator" "Internal TrustyAI"
        vllm = softwareSystem "vLLM Inference Server" "LLM serving backend for chat completions" "Internal"
        certSigner = softwareSystem "OpenShift service-serving-cert-signer" "Provisions TLS client certificates at /etc/tls/private/" "OpenShift Infrastructure"
        caOperator = softwareSystem "OpenShift service-ca-operator" "Provisions CA certificate at /etc/tls/ca/service-ca.crt" "OpenShift Infrastructure"

        user -> gatewaySystem "POST /{route}/v1/chat/completions" "HTTP/8090, Authorization header pass-through"
        gatewaySystem -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Dispatches detection requests" "Internal"
        orchestrator -> vllm "Chat completion inference" "Internal"
        certSigner -> gatewaySystem "Provisions TLS client cert/key" "kubernetes.io/tls secret"
        caOperator -> gatewaySystem "Provisions CA certificate" "ConfigMap projection"
    }

    views {
        systemContext gatewaySystem "SystemContext" {
            include *
            autoLayout
            description "System context showing vllm-orchestrator-gateway in the TrustyAI ecosystem"
        }

        container gatewaySystem "Containers" {
            include *
            autoLayout
            description "Container view of the gateway service"
        }

        component gateway "Components" {
            include *
            autoLayout
            description "Internal components of the vllm-orchestrator-gateway"
        }

        styles {
            element "Internal TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #82b366
                color #ffffff
            }
            element "OpenShift Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
