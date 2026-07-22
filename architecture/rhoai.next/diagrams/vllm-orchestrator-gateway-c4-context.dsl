workspace {
    model {
        aiApp = person "AI Application / Client" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vLLM Orchestrator Gateway" "Lightweight Rust HTTP gateway that routes OpenAI-compatible chat completion requests through configurable detector pipelines" {
            gatewayService = container "vllm-orchestrator-gateway" "HTTP reverse proxy with route-specific detector injection, fallback message handling, and SSE streaming support" "Rust (axum 0.7.9)"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs guardrail detection on chat completions using configured detector pipelines" "Internal Platform"
        detectors = softwareSystem "Detector Services" "Content detection services (e.g., guardrails-regex-detector) that analyze input/output for policy violations" "Internal Platform"
        vllm = softwareSystem "vLLM Model Server" "LLM inference backend for generating chat completions" "Internal Platform"

        serviceCA = softwareSystem "OpenShift service-ca" "Provides CA certificates for internal service TLS trust" "Infrastructure"
        certManager = softwareSystem "cert-manager / Cluster CA" "Provisions TLS client certificates and keys for mTLS identity" "Infrastructure"

        aiApp -> gateway "POST /{route_name}/v1/chat/completions" "HTTP/8090 plaintext"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Runs input/output detectors" "Varies"
        orchestrator -> vllm "LLM inference requests" "Varies"

        serviceCA -> gateway "Provides CA cert at /etc/tls/ca/service-ca.crt" ""
        certManager -> gateway "Provides client cert+key at /etc/tls/private/" ""
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
                background #f5a623
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
