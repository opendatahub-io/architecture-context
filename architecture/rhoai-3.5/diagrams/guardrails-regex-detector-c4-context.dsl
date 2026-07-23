workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Routes text content to downstream detectors for content safety scanning"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust microservice that detects PII and custom patterns in text using regex matching" {
            service = container "regex-detector" "HTTP service for regex-based PII and custom pattern detection" "Rust / axum" {
                detectApi = component "Detection API" "POST /api/v1/text/contents - accepts text and regex patterns, returns detection results" "axum Route Handler"
                healthApi = component "Health API" "GET /health - returns health status" "axum Route Handler"
                builtinDetectors = component "Built-in Detectors" "Pre-compiled regex patterns for email, SSN, credit card detection" "Rust HashMap<&str, fn>"
                customDetectors = component "Custom Regex Engine" "Compiles and executes user-supplied regex patterns at request time" "Rust regex crate"
            }
        }

        # Relationships
        orchestrator -> regexDetector "Sends text content for PII/pattern detection" "HTTP/8080 plaintext"
        orchestrator -> service "POST /api/v1/text/contents" "HTTP/8080"

        detectApi -> builtinDetectors "Dispatches built-in pattern names"
        detectApi -> customDetectors "Dispatches custom regex strings"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing the Guardrails Regex Detector within the FMS Guardrails ecosystem"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Container view of the regex-detector service"
        }

        component service "Components" {
            include *
            autoLayout
            description "Internal components of the regex-detector service"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Person" {
                background #7ed321
                color #ffffff
                shape Person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #f5a623
                color #333333
            }
        }
    }
}
