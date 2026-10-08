workspace {
    model {
        client = person "API Client" "Application or user sending OpenAI-compatible chat completion requests"
        platformOps = person "Platform Operator" "Configures gateway routes, detectors, and deployment"

        gateway = softwareSystem "vllm-orchestrator-gateway" "Rust HTTP gateway that routes chat completion requests through configurable detector pipelines for content filtering and safety enforcement" {
            httpServer = container "HTTP Server" "Axum-based HTTP listener with dynamic route registration from YAML config" "Rust / Axum 0.7.9"
            routeHandler = container "Route Handler" "Dispatches to streaming or non-streaming chat completion handling per route config" "Rust"
            detectorInjector = container "Detector Injector" "Injects route-specific detector definitions into outbound payloads" "Rust"
            tlsClient = container "TLS Client Builder" "Probes for mTLS certificates, constructs reqwest client with optional mTLS identity and custom CA" "Rust / native-tls / OpenSSL"
            orchestratorForwarder = container "Orchestrator Forwarder" "Forwards enriched requests to orchestrator, handles streaming SSE and detection fallback" "Rust / reqwest"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Backend service that performs LLM inference with detector-based content filtering" "Internal Platform"
        detectors = softwareSystem "Content Detectors" "Detection services (regex, PII, etc.) registered with the orchestrator" "Internal Platform"
        vllm = softwareSystem "vLLM Runtime" "Large language model serving runtime for inference" "Internal Platform"
        certSigner = softwareSystem "OpenShift service-serving-cert-signer" "Provisions TLS certificates for service-to-service mTLS" "OpenShift Platform"
        caOperator = softwareSystem "OpenShift service-ca operator" "Provisions CA certificates for trust chain verification" "OpenShift Platform"

        client -> gateway "Sends chat completion requests" "HTTP/8090"
        platformOps -> gateway "Configures routes and detectors" "YAML config file"

        gateway -> orchestrator "Forwards enriched requests with detector config" "HTTP or HTTPS/8085, optional mTLS"
        orchestrator -> detectors "Invokes content detectors" "Internal API"
        orchestrator -> vllm "Delegates model inference" "Internal API"

        certSigner -> gateway "Provisions TLS client certificates" "Certificate mount"
        caOperator -> gateway "Provisions CA certificate" "ConfigMap mount"

        httpServer -> routeHandler "Routes incoming requests"
        routeHandler -> detectorInjector "Passes request for enrichment"
        detectorInjector -> orchestratorForwarder "Sends enriched payload"
        orchestratorForwarder -> tlsClient "Uses for HTTPS connections"
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
            element "OpenShift Platform" {
                background #ee0000
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
