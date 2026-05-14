workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes text content to various detectors for content safety screening before/after LLM inference" "Internal Platform"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP microservice that detects PII and custom patterns in text using regex matching" {
            httpServer = container "Axum HTTP Server" "Serves health check and detection endpoints on port 8080" "Rust / Axum 0.7.9"
            detectionEngine = container "Detection Engine" "Regex-based pattern matching with built-in PII patterns (email, SSN, credit card) and custom regex support" "Rust / regex 1.11.1"
            asyncRuntime = container "Tokio Runtime" "Multi-threaded async runtime powering the HTTP server" "Rust / Tokio 1.41.1"
        }

        llm = softwareSystem "LLM Service" "Large Language Model inference service" "External"
        user = person "End User" "Sends prompts to LLM via the guardrails pipeline"

        # Relationships
        user -> orchestrator "Sends prompts for LLM inference (via guardrails pipeline)"
        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 plaintext, no auth"
        orchestrator -> llm "Forwards screened prompts for inference"

        # Internal container relationships
        httpServer -> detectionEngine "Invokes pattern matching"
        asyncRuntime -> httpServer "Powers async request handling"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
        }

        container regexDetector "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
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
