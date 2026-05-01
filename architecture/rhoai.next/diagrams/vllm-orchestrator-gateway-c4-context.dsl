workspace {
    model {
        client = person "Client Application" "OpenAI-compatible client sending chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "HTTP gateway providing multiple OpenAI-compatible chat completion endpoints with configurable detector-based content filtering" {
            httpServer = container "HTTP Server" "Listens on 8090/TCP, routes requests based on YAML config" "Rust (axum 0.7.9)"
            configLoader = container "Config Loader" "Reads YAML configuration defining detectors, routes, and orchestrator settings" "Rust (serde_yml)"
            detectorInjector = container "Detector Injector" "Injects detector specifications into client payloads before forwarding" "Rust"
            detectionChecker = container "Detection Checker" "Inspects orchestrator responses for detections; substitutes fallback messages" "Rust"
            sseHandler = container "SSE Stream Handler" "Processes chunked SSE responses for streaming chat completions" "Rust (futures::StreamExt)"
            tlsClient = container "TLS Client" "Builds mTLS-capable HTTP client when certificates are present" "Rust (openssl + native-tls)"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service performing LLM generation and detector evaluation" "Internal TrustyAI"
        detectors = softwareSystem "Guardrails Detectors" "Content detection services (e.g., regex-language) for input/output filtering" "Internal TrustyAI"
        vllm = softwareSystem "vLLM / Model Server" "LLM inference backend for chat completion generation" "Internal"
        serviceCA = softwareSystem "OpenShift service-ca" "Provides CA certificate for validating orchestrator TLS" "Platform"
        certManager = softwareSystem "cert-manager" "Provisions client TLS certificates for mTLS" "Platform"

        # External relationships
        client -> gateway "POST /{route_name}/v1/chat/completions" "HTTP/8090"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085 (optional mTLS)"
        orchestrator -> detectors "Invokes configured detectors" "Internal"
        orchestrator -> vllm "Inference request" "Internal"
        serviceCA -> gateway "CA cert at /etc/tls/ca/service-ca.crt" "File mount"
        certManager -> gateway "Client cert+key at /etc/tls/private/" "File mount"

        # Container relationships
        httpServer -> configLoader "Loads route/detector config at startup"
        httpServer -> detectorInjector "Passes request for detector injection"
        detectorInjector -> tlsClient "Sends modified request to orchestrator"
        tlsClient -> detectionChecker "Returns orchestrator response"
        httpServer -> sseHandler "Handles streaming requests"
        sseHandler -> detectorInjector "Injects detectors for streaming"
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
                background #438dd5
                color #ffffff
            }
            element "Internal TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
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
