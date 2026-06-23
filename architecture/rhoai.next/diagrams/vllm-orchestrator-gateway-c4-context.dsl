workspace {
    model {
        user = person "Client Application" "Application or user sending chat completion requests with content safety requirements"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust-based HTTP gateway that routes OpenAI-compatible chat completion requests through FMS Guardrails Orchestrator with configurable detector-based content filtering per route" {
            httpServer = container "HTTP Server" "axum-based HTTP listener exposing dynamic per-route chat completion endpoints on port 8090/TCP" "Rust (axum 0.7.9)"
            configLoader = container "Config Loader" "Loads YAML configuration defining orchestrator connection, detector registry, and named routes" "Rust (serde_yml)"
            routeEngine = container "Route Engine" "Creates POST /{route_name}/v1/chat/completions endpoints from config-defined routes with bound detector sets" "Rust"
            tlsClient = container "TLS Client Builder" "Constructs mTLS-capable HTTP client from Kubernetes-mounted certificates (PEM to PKCS#12 via OpenSSL)" "Rust (openssl + native-tls)"
            streamHandler = container "SSE Stream Handler" "Processes Server-Sent Events chunks from orchestrator, applying per-chunk detection-aware fallback" "Rust (futures)"
            detectionFilter = container "Detection Filter" "Inspects orchestrator responses for detection results and replaces content with fallback messages when configured" "Rust"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service performing chat completion with detector-based content filtering" "Internal Platform"
        vllm = softwareSystem "vLLM Inference Server" "LLM inference engine for text generation (accessed indirectly via orchestrator)" "Internal Platform"
        detectors = softwareSystem "Content Detectors" "Detector services (e.g., regex-language detector) performing input/output content analysis (accessed via orchestrator)" "Internal Platform"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / kube-rbac-proxy providing TLS termination and authentication" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for mTLS" "Infrastructure"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides CA certificates for internal service TLS validation" "Infrastructure"

        user -> platformIngress "Sends chat completion requests" "HTTPS/443"
        platformIngress -> gateway "Forwards requests after TLS termination" "HTTP/8090"
        gateway -> orchestrator "Forwards requests with injected detector config" "HTTP or HTTPS/8085, Conditional mTLS"
        orchestrator -> vllm "Inference requests" "Internal"
        orchestrator -> detectors "Detection requests" "Internal"
        certManager -> gateway "Provisions TLS client certificate and key" "Kubernetes volume mount"
        serviceCA -> gateway "Provisions CA certificate" "Kubernetes volume mount"

        configLoader -> routeEngine "Passes parsed route configuration"
        routeEngine -> httpServer "Registers dynamic route handlers"
        httpServer -> streamHandler "Delegates streaming requests"
        httpServer -> detectionFilter "Delegates non-streaming requests"
        streamHandler -> detectionFilter "Per-chunk detection filtering"
        tlsClient -> httpServer "Provides configured HTTP client"
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
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #e8e8e8
                shape Person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
