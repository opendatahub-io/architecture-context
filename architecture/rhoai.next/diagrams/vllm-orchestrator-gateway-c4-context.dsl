workspace {
    model {
        apiClient = person "API Client" "Application or user consuming OpenAI-compatible chat completion endpoints"

        vllmOrchestratorGateway = softwareSystem "vLLM Orchestrator Gateway" "HTTP gateway providing route-based OpenAI-compatible chat completion endpoints with configurable detector pipelines for content filtering" {
            gatewayService = container "Gateway Service" "Rust binary using axum framework; dispatches requests by route, injects detector config, applies fallback messages" "Rust/axum"
            configFile = container "YAML Configuration" "Defines orchestrator connection, detector definitions (input/output), and route-to-detector mappings with optional fallback messages" "YAML file mount"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Performs content detection on chat completions using configured detectors; routes to model server for inference" "Internal TrustyAI"
        contentDetectors = softwareSystem "Content Detectors" "Detection servers (e.g., regex-detector) that evaluate input/output content for policy violations" "Internal TrustyAI"
        vllmModelServer = softwareSystem "vLLM Model Server" "LLM inference backend; provides chat completion responses" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for mTLS communication" "External Platform"
        serviceCaOperator = softwareSystem "service-ca-operator" "Provides CA certificates for trusting internal service certificates" "External Platform"
        platformOperator = softwareSystem "TrustyAI / RHOAI Operator" "Deploys and manages the gateway lifecycle, creates Kubernetes Service, mounts secrets and config" "Internal Platform"

        apiClient -> vllmOrchestratorGateway "POST /{route_name}/v1/chat/completions" "HTTP/8090, plaintext, Authorization passthrough"
        vllmOrchestratorGateway -> orchestrator "POST /api/v2/chat/completions-detection" "HTTP(S)/8085, optional mTLS, Authorization forwarded"
        orchestrator -> contentDetectors "Runs input/output detection" "Internal API"
        orchestrator -> vllmModelServer "Forwards inference requests" "Internal API"
        certManager -> vllmOrchestratorGateway "Provisions TLS cert/key" "kubernetes.io/tls secret mount"
        serviceCaOperator -> vllmOrchestratorGateway "Provisions CA certificate" "Opaque secret mount"
        platformOperator -> vllmOrchestratorGateway "Deploys and configures" "Kubernetes resources"

        gatewayService -> configFile "Reads at startup" "File I/O"
    }

    views {
        systemContext vllmOrchestratorGateway "SystemContext" {
            include *
            autoLayout
        }

        container vllmOrchestratorGateway "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
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
