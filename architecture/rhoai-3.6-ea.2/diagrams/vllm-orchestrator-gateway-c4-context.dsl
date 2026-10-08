workspace {
    model {
        client = person "Client" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP gateway that routes chat completion requests through configurable detector pipelines for content filtering" {
            httpListener = container "HTTP Listener" "Accepts POST requests on dynamically generated routes" "axum 0.7.9 / Rust"
            routeEngine = container "Route Engine" "Maps route names to detector pipeline configurations" "Rust"
            requestForwarder = container "Request Forwarder" "Forwards requests to orchestrator with injected detector config" "reqwest 0.12.12 / Rust"
            streamHandler = container "SSE Stream Handler" "Processes streaming responses, checking each chunk for detections" "Rust"
            nonStreamHandler = container "Non-Stream Handler" "Processes non-streaming JSON responses with detection checks" "Rust"
            mtlsClient = container "mTLS Client Builder" "Constructs PKCS#12 identity from PEM certificates for optional mTLS" "openssl 0.10.73 / Rust"
            configLoader = container "Config Loader" "Loads and validates YAML configuration at startup" "serde_yml / Rust"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs model inference with detector-based content filtering" "External"
        serviceMesh = softwareSystem "Service Mesh / cert-manager" "Provisions mTLS certificates at /etc/tls/private/" "External"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides CA certificate at /etc/tls/ca/service-ca.crt" "External"

        client -> gateway "POST /{route}/v1/chat/completions" "HTTP/8090"
        gateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP or HTTPS/8085 (optional mTLS)"
        serviceMesh -> gateway "Provisions TLS client cert and key" "File mount"
        serviceCA -> gateway "Provisions CA certificate" "File mount"

        httpListener -> routeEngine "Route lookup"
        routeEngine -> requestForwarder "Detector config injection"
        requestForwarder -> streamHandler "SSE responses"
        requestForwarder -> nonStreamHandler "JSON responses"
        requestForwarder -> mtlsClient "TLS identity"
        configLoader -> routeEngine "Route definitions"
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
            }
        }
    }
}
