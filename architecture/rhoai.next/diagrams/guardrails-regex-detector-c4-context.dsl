workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates guardrails detection by routing requests to pluggable detector backends" "Internal RHOAI"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Stateless Rust HTTP microservice that detects PII patterns (email, SSN, credit card) and custom regex patterns in text" {
            axumRouter = container "axum HTTP Router" "Routes incoming HTTP requests to handler functions" "Rust - axum 0.7.9 + tokio 1.41.1"
            detectionEngine = container "Detection Engine" "Applies built-in PII regex patterns and custom user-supplied patterns against input text" "Rust - regex 1.11.1"
        }

        user = person "Platform User" "Submits text for guardrails checking (indirectly via orchestrator)"

        # Relationships
        user -> orchestrator "Submits text for guardrails checking"
        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 plaintext, no auth"
        axumRouter -> detectionEngine "Passes parsed request to detection logic"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing guardrails-regex-detector in the RHOAI guardrails subsystem"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Internal structure of the regex detector service"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #85BBF0
                color #000000
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
        }
    }
}
