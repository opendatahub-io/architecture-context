workspace {
    model {
        client = person "API Client" "Application or user sending OpenAI-compatible chat completion requests"
        platformOp = person "Platform Operator" "Configures routes, detectors, and TLS settings via YAML config and volume mounts"

        gateway = softwareSystem "vLLM Orchestrator Gateway" "Rust HTTP gateway that proxies OpenAI-compatible chat completion requests with per-route detector injection and fallback message handling" {
            routeHandler = container "Route Handler" "Receives POST requests on /{route_name}/v1/chat/completions and matches to configured routes" "Rust / axum"
            detectorInjector = container "Detector Injector" "Injects route-specific input/output detector maps into request payload before forwarding" "Rust"
            streamHandler = container "SSE Stream Handler" "Handles streaming responses; parses SSE chunks, checks detections, applies fallback" "Rust / futures"
            nonStreamHandler = container "Non-Stream Handler" "Handles non-streaming responses; deserializes JSON, checks detections, applies fallback" "Rust / reqwest"
            tlsConfig = container "TLS/mTLS Config" "Constructs PKCS#12 identity from PEM certs; configures custom CA trust; enables mTLS client auth" "Rust / openssl + native-tls"
            configLoader = container "Config Loader" "Parses YAML config defining orchestrator connection, detector definitions, and route mappings" "Rust / serde_yml"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service that performs chat completions with detector-based content analysis" "Internal"
        detectors = softwareSystem "Guardrails Detectors" "Content detection services (e.g., regex-detector, PII detector) invoked by the orchestrator" "Internal"
        llmServer = softwareSystem "vLLM / LLM Inference Server" "Language model serving engine for text generation" "Internal"
        certManager = softwareSystem "cert-manager / service-ca-operator" "Provisions TLS certificates and CA bundles via Kubernetes volume mounts" "External"
        k8sSecrets = softwareSystem "Kubernetes Secrets" "Volume-mounted TLS certificates and keys at well-known paths" "External"

        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090, plaintext, Authorization pass-through"
        platformOp -> gateway "Configures routes, detectors, TLS" "YAML config file + volume mounts"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS, forwarded auth"
        orchestrator -> detectors "Invokes content detectors" "Internal"
        orchestrator -> llmServer "Dispatches generation requests" "Internal"
        certManager -> k8sSecrets "Provisions certificates" "X.509 PEM"
        k8sSecrets -> gateway "Volume mounts TLS certs/keys" "/etc/tls/private/, /etc/tls/ca/"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
