workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes content inspection requests to detection backends; handles external-facing authentication" "Internal RHOAI"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regular expressions" {
            server = container "Regex Detector Server" "Axum-based HTTP server binding to 0.0.0.0:8080" "Rust / Axum 0.7.9"
            detectionEngine = container "Detection Engine" "Regex pattern matching with built-in PII patterns (email, SSN, credit card) and custom pattern support" "Rust / regex 1.11.1"
        }

        user = person "Platform Operator" "Deploys and configures the guardrails detection stack"

        # Relationships
        orchestrator -> regexDetector "Sends text content inspection requests" "HTTP/8080 POST /api/v1/text/contents"
        user -> orchestrator "Configures guardrails policies"

        # Internal container relationships
        server -> detectionEngine "Routes detection requests"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing the Guardrails Regex Detector within the RHOAI guardrails ecosystem"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Container view showing internal structure of the Regex Detector service"
        }

        styles {
            element "Internal RHOAI" {
                background #7ed321
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
                shape person
            }
        }
    }
}
