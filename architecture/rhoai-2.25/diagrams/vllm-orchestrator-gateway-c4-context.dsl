workspace {
    model {
        user = person "AI Application Developer" "Sends OpenAI-compatible chat completion requests to guardrailed LLM endpoints"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Lightweight Rust HTTP gateway that routes chat completions through configurable detector pipelines" {
            routeHandler = container "Route Handler" "Receives OpenAI-compatible requests and injects detector config per route" "Rust / axum"
            configLoader = container "Config Loader" "Loads YAML config defining routes, detectors, and fallback messages" "serde_yml"
            tlsClient = container "HTTP/mTLS Client" "Forwards requests to orchestrator with optional mTLS and header forwarding" "reqwest / native-tls"
            fallbackHandler = container "Fallback Handler" "Replaces response content with fallback message when detections are found" "Rust"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs LLM inference with detector-based content filtering" "Internal Platform"
        detectors = softwareSystem "Guardrails Detectors" "Content filtering detectors (e.g., regex, PII)" "Internal Platform"
        vllm = softwareSystem "vLLM / LLM Server" "Model serving backend for text generation" "Internal Platform"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides CA certificates for internal service TLS validation" "Platform Infrastructure"
        k8sSecrets = softwareSystem "Kubernetes Secrets" "Provides TLS certificates for mTLS client identity" "Platform Infrastructure"

        # User interactions
        user -> gateway "Sends POST /{route}/v1/chat/completions" "HTTP/8090"

        # Internal container interactions
        routeHandler -> configLoader "Reads route and detector configuration"
        routeHandler -> tlsClient "Forwards request with injected detector config"
        tlsClient -> fallbackHandler "Passes orchestrator response"
        fallbackHandler -> routeHandler "Returns final response (original or fallback)"

        # External interactions
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, Optional mTLS"
        orchestrator -> detectors "Invokes configured detectors" "Internal"
        orchestrator -> vllm "Forwards generation requests" "Internal"
        serviceCA -> gateway "Provides CA cert at /etc/tls/ca/service-ca.crt" "Volume Mount"
        k8sSecrets -> gateway "Provides TLS cert+key at /etc/tls/private/" "Volume Mount"
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
            element "Platform Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
