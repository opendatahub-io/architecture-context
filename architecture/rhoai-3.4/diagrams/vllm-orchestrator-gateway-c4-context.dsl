workspace {
    model {
        client = person "API Client" "Application or user sending OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP gateway that routes OpenAI-compatible chat requests through configurable detector pipelines to the FMS Guardrails Orchestrator" {
            routerContainer = container "Axum Router" "Dynamic route registration from YAML config; dispatches requests to handler" "Rust (axum 0.7.9)"
            handlerContainer = container "Request Handler" "Injects per-route detector configuration into request payload; forwards to orchestrator" "Rust"
            streamProcessor = container "Stream Processor" "Parses SSE chunks, checks for detections, applies fallback messages" "Rust (futures)"
            tlsModule = container "TLS Module" "Optional mTLS client identity using OpenSSL PKCS12 bridge to native-tls" "Rust (openssl + native-tls)"
            configLoader = container "Config Loader" "Reads and validates YAML configuration defining routes and detector pipelines" "Rust (serde_yml)"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service that performs chat completion with detector-based content filtering" "TrustyAI"
        detectors = softwareSystem "Detector Services" "Content detection services (PII, toxicity, regex patterns) invoked by the orchestrator" "TrustyAI"
        vllm = softwareSystem "vLLM Inference Server" "LLM model serving backend for generating chat completions" "External"
        serviceCa = softwareSystem "Kubernetes service-ca" "Provides CA certificate for validating orchestrator TLS" "Platform"

        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090, Authorization header passthrough"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, Optional mTLS + forwarded Auth"
        orchestrator -> detectors "Invoke configured detectors" "Internal"
        orchestrator -> vllm "Forward generation request" "Internal"
        serviceCa -> gateway "Provides CA cert" "Volume mount /etc/tls/ca/"

        configLoader -> routerContainer "Registers dynamic routes"
        routerContainer -> handlerContainer "Dispatches request"
        handlerContainer -> streamProcessor "Streaming mode"
        handlerContainer -> tlsModule "If TLS certs mounted"
    }

    views {
        systemContext gateway "SystemContext" {
            include *
            autoLayout
            description "System context showing vllm-orchestrator-gateway in the TrustyAI guardrailing ecosystem"
        }

        container gateway "Containers" {
            include *
            autoLayout
            description "Internal container view of the vllm-orchestrator-gateway service"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
