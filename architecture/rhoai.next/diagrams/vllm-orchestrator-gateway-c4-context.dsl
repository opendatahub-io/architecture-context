workspace {
    model {
        client = person "API Client" "Application or user sending chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "OpenAI-compatible HTTP gateway that routes chat completions through configurable detector pipelines for content filtering" {
            router = container "Axum Router" "Dynamic route registration from YAML config" "Rust (Axum 0.7.9)"
            requestHandler = container "Request Handler" "Dispatches streaming vs non-streaming requests, injects detector configs" "Rust"
            mtlsClient = container "mTLS Client" "Builds PKCS#12 identity from PEM certs, configures TLS via system OpenSSL" "Rust (openssl + native-tls)"
            fallbackEngine = container "Fallback Engine" "Substitutes configurable fallback responses when detections trigger" "Rust"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service for chat completion with content detection" "Internal Platform"
        detectors = softwareSystem "Content Detectors" "Detector services (PII, toxicity, regex) registered in the orchestrator" "Internal Platform"
        vllm = softwareSystem "vLLM Inference Server" "LLM serving backend for chat completions" "Internal Platform"
        serviceCa = softwareSystem "OpenShift service-ca" "Provides CA certificates for internal service TLS" "Platform"
        certProvisioner = softwareSystem "Platform TLS Provisioner" "Provisions client certificates for mTLS" "Platform"

        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085 (optional mTLS)"
        orchestrator -> detectors "Content analysis requests" "HTTP"
        orchestrator -> vllm "Chat completion inference" "HTTP"
        serviceCa -> gateway "CA certificate at /etc/tls/ca/service-ca.crt" "File mount"
        certProvisioner -> gateway "Client cert/key at /etc/tls/private/" "File mount"

        router -> requestHandler "Dispatches requests"
        requestHandler -> mtlsClient "Uses for orchestrator connections"
        requestHandler -> fallbackEngine "Applies fallback on detection"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
