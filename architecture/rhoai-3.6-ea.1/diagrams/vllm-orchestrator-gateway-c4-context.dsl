workspace {
    model {
        apiClient = person "API Client" "Sends OpenAI-compatible chat completion requests"

        gateway = softwareSystem "vllm-orchestrator-gateway" "OpenAI-compatible HTTP gateway that routes chat completion requests through configurable detector-based content filtering" {
            httpRouter = container "HTTP Router" "Registers dynamic POST /{route_name}/v1/chat/completions endpoints from YAML config" "Rust / axum + tokio"
            streamHandler = container "Streaming Handler" "Processes SSE streaming responses chunk-by-chunk with fallback injection" "Rust / axum"
            nonStreamHandler = container "Non-Streaming Handler" "Processes JSON responses with detection-based fallback replacement" "Rust / axum"
            configLoader = container "Config Loader" "Reads YAML configuration defining routes, detectors, and fallback messages" "Rust / serde_yml"
            tlsClient = container "TLS Client" "Constructs mTLS identity from platform-injected certificates using OpenSSL PKCS#12" "Rust / openssl + native-tls"
        }

        orchestrator = softwareSystem "vllm-orchestrator" "Backend service that performs detector-based content filtering and LLM inference" "Internal Platform"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Provides service-ca certificate injection, routing, and infrastructure auth" "External"

        apiClient -> gateway "Sends chat completion requests" "HTTP/8090, Authorization header"
        gateway -> orchestrator "Forwards augmented requests with detector config" "HTTP or HTTPS/8032, mTLS when certs present"
        openshiftPlatform -> gateway "Injects TLS certificates at /etc/tls/private/" "Volume mounts"

        httpRouter -> configLoader "Reads route definitions at startup"
        httpRouter -> streamHandler "Routes streaming requests (stream=true)"
        httpRouter -> nonStreamHandler "Routes non-streaming requests (stream=false)"
        streamHandler -> tlsClient "Uses for orchestrator connection"
        nonStreamHandler -> tlsClient "Uses for orchestrator connection"
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
            }
            element "External" {
                background #999999
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
