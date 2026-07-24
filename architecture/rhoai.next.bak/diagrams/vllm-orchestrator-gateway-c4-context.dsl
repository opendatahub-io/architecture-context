workspace {
    model {
        client = person "Client Application" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP reverse proxy that injects detector configurations into chat completion requests and applies fallback messages when content detections are found" {
            routeHandler = container "Route Handler" "Dynamically registers /{route-name}/v1/chat/completions endpoints from YAML config" "Rust / axum"
            detectorInjector = container "Detector Injector" "Augments request payloads with route-specific detector specifications" "Rust"
            proxyClient = container "Proxy Client" "HTTP/HTTPS client with optional mTLS support" "reqwest + native-tls"
            streamProcessor = container "SSE Stream Processor" "Processes Server-Sent Events chunks for streaming responses" "Rust / futures"
            fallbackHandler = container "Fallback Handler" "Replaces response content with fallback message when detections are found" "Rust"
            tlsConfig = container "TLS Configuration" "Loads certificates from /etc/tls/private/ and constructs PKCS#12 identity" "openssl crate"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs chat completion with detector-based content filtering" "Internal RHOAI"
        detectors = softwareSystem "Detector Services" "Content detection services (PII, safety, regex)" "Internal RHOAI"
        vllm = softwareSystem "vLLM Model Server" "LLM inference backend (e.g., Qwen2.5)" "Internal RHOAI"
        certManager = softwareSystem "Certificate Manager" "Provisions and rotates TLS certificates" "Platform"
        serviceCA = softwareSystem "Service CA Operator" "Provides CA certificates for service-to-service TLS" "Platform"

        # System context relationships
        client -> gateway "Sends POST /{route}/v1/chat/completions" "HTTP/8090"
        gateway -> orchestrator "Proxies POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Evaluates content with detectors" "Internal"
        orchestrator -> vllm "Generates LLM completions" "Internal"
        certManager -> gateway "Provisions TLS certificates" "Volume mount"
        serviceCA -> gateway "Provisions CA certificate" "Volume mount"

        # Container relationships
        routeHandler -> detectorInjector "Passes request with route config"
        detectorInjector -> proxyClient "Sends augmented payload"
        proxyClient -> streamProcessor "Forwards SSE stream"
        proxyClient -> fallbackHandler "Forwards non-streaming response"
        streamProcessor -> fallbackHandler "Chunk with detection"
        tlsConfig -> proxyClient "Provides mTLS identity"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
