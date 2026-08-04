workspace {
    model {
        orchestrator = person "Guardrails Orchestrator" "Upstream service that coordinates guardrails detection pipelines"

        guardrailsRegexDetector = softwareSystem "guardrails-regex-detector" "Rust-based regex detection microservice for PII pattern scanning (email, SSN, credit card) and custom regex matching" {
            axumServer = container "Axum HTTP Server" "Handles HTTP routing, request/response logging via TraceLayer" "Rust / Axum 0.7.9 / Tokio 1.41.1"
            detectionHandler = container "Detection Handler" "Dispatches to built-in PII detectors or compiles user-supplied regex patterns" "Rust"
            builtinDetectors = container "Built-in Detectors" "Pre-compiled regex patterns for email, SSN, credit card detection" "Rust / regex 1.11.1"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing probes and network isolation" "External"

        orchestrator -> guardrailsRegexDetector "Sends text content for regex detection" "HTTP POST /api/v1/text/contents, port 8080, JSON"
        kubernetes -> guardrailsRegexDetector "Health probes" "HTTP GET /health, port 8080"

        axumServer -> detectionHandler "Routes POST requests"
        detectionHandler -> builtinDetectors "Dispatches to built-in PII patterns"
    }

    views {
        systemContext guardrailsRegexDetector "SystemContext" {
            include *
            autoLayout
        }

        container guardrailsRegexDetector "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
