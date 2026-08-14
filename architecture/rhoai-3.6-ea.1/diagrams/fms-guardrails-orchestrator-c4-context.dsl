workspace {
    model {
        client = person "API Client" "Application or service consuming guardrailed text generation"

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "REST API orchestrator that coordinates AI text generation with content safety guardrails" {
            apiServer = container "REST API Server" "Handles v1 and v2 REST endpoints for classification-with-generation and detection" "Rust / axum / Port 8033"
            healthServer = container "Health Server" "Provides unauthenticated /health and /info endpoints" "Rust / axum / Port 8034"
            grpcClients = container "gRPC Clients" "tonic-generated clients for chunker and TGIS communication" "Rust / tonic"
            restClients = container "REST Clients" "reqwest-based clients for detector service communication" "Rust / reqwest"
            tlsLayer = container "TLS Layer" "Optional server TLS and mTLS; per-service downstream TLS configs" "rustls / ring (NOT FIPS)"
        }

        chunkerServices = softwareSystem "Chunker Services" "Text chunking services using caikit Chunkers API" "Internal Platform"
        detectorServices = softwareSystem "Detector Services" "Content safety detection services" "Internal Platform"
        detectorHealthServices = softwareSystem "Detector Health Services" "Health endpoints for detector services" "Internal Platform"
        tgisService = softwareSystem "TGIS Generation Service" "Text Generation Inference Service for LLM generation" "Internal Platform"

        # Relationships
        client -> orchestrator "Sends text generation requests with guardrails" "HTTP/HTTPS 8033/TCP"
        client -> orchestrator "Checks health" "HTTP 8034/TCP"

        apiServer -> grpcClients "Routes chunking requests"
        apiServer -> restClients "Routes detection requests"
        grpcClients -> chunkerServices "Chunks text" "gRPC/8085 TLS optional"
        restClients -> detectorServices "Runs content safety detection" "HTTP/HTTPS/8080 TLS optional"
        restClients -> detectorHealthServices "Probes detector health" "HTTP/8081"
        grpcClients -> tgisService "Generates text" "gRPC/8033"
    }

    views {
        systemContext orchestrator "SystemContext" {
            include *
            autoLayout
        }

        container orchestrator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
