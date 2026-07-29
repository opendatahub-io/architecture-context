workspace {
    model {
        apiConsumer = person "API Consumer" "Application or service sending LLM generation requests with safety guardrails"

        guardrailsOrchestrator = softwareSystem "fms-guardrails-orchestrator" "Guardrails orchestration server that intercepts LLM generation requests, applies configurable content detection and classification, and returns safety-annotated responses" {
            guardrailsServer = container "Guardrails API Server" "Handles content detection, classification, and generation orchestration across 12 HTTP endpoints (v1 and v2 APIs)" "Rust (axum)" {
                tlsAcceptor = component "TLS/mTLS Acceptor" "Optional inbound TLS termination and client certificate verification" "rustls + ring"
                headerFilter = component "Header Passthrough Filter" "Filters request headers via configured allowlist, rewrites X-Forwarded-Access-Token to Bearer" "axum middleware"
                v1Router = component "v1 API Routes" "Classification-with-generation and streaming endpoints" "axum router"
                v2Router = component "v2 API Routes" "Detection, completions-detection, and generation-detection endpoints" "axum router"
                orchestratorHandler = component "Orchestrator Handler" "Coordinates concurrent calls to generation, chunker, and detector services" "Rust async"
                grpcClient = component "gRPC Client" "Communicates with TGIS and chunker services" "tonic"
                restClient = component "REST Client" "Communicates with detector and OpenAI-compatible services" "reqwest"
                tlsConfig = component "Named TLS Configurations" "Reusable TLS configurations for downstream service connections" "rustls"
            }
            healthServer = container "Health Server" "Provides unauthenticated health and info endpoints on port 8034" "Rust (axum)"
        }

        tgis = softwareSystem "TGIS Generation Service" "Text Generation Inference Server for foundation model generation" "Internal"
        chunkerServices = softwareSystem "Chunker Services" "Content chunking services for detection pipelines" "Internal"
        detectorServices = softwareSystem "Detector Services" "Content detection and classification services" "Internal"
        detectorHealthServices = softwareSystem "Detector Health Services" "Health monitoring for detector services" "Internal"

        apiConsumer -> guardrailsOrchestrator "Sends generation/detection requests" "HTTP(S)/8033, TLS 1.2+ optional"
        apiConsumer -> guardrailsOrchestrator "Checks health status" "HTTP/8034, no auth"
        guardrailsOrchestrator -> tgis "Generates text" "gRPC/8033"
        guardrailsOrchestrator -> chunkerServices "Chunks content for detection" "gRPC/8085, TLS optional"
        guardrailsOrchestrator -> detectorServices "Detects and classifies content" "HTTP(S)/8080, TLS optional, Bearer optional"
        guardrailsOrchestrator -> detectorHealthServices "Monitors detector health" "HTTP(S)/8081"
    }

    views {
        systemContext guardrailsOrchestrator "SystemContext" {
            include *
            autoLayout
        }

        container guardrailsOrchestrator "Containers" {
            include *
            autoLayout
        }

        component guardrailsServer "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal" {
                background #7ed321
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
