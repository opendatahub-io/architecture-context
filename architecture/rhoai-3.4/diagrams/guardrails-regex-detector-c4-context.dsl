workspace {
    model {
        llmUser = person "LLM User" "Sends prompts to LLM via guardrails-protected endpoint"

        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes LLM I/O through multiple detector services to enforce guardrail policies" "Internal RHOAI"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regex matching" {
            httpServer = container "Axum HTTP Server" "Serves POST /api/v1/text/contents and GET /health" "Rust / Axum 0.7.9" "Service"
            detectionEngine = container "Detection Engine" "Dispatches built-in (email, SSN, credit card) and custom regex patterns against input text" "Rust / regex 1.11.1" "Engine"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        llmUser -> guardrailsOrchestrator "Sends prompts for LLM inference"
        guardrailsOrchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 plaintext"
        kubernetes -> regexDetector "GET /health (liveness/readiness probes)" "HTTP/8080"

        httpServer -> detectionEngine "Dispatches regex patterns for matching"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context for Guardrails Regex Detector within the RHOAI Guardrails subsystem"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Internal container architecture of the Guardrails Regex Detector"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #e17055
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Engine" {
                shape Hexagon
                background #00b894
                color #ffffff
            }
        }
    }
}
