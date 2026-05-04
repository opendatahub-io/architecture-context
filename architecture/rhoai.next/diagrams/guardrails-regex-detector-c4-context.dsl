workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes text content to detector backends for safety screening before/after LLM inference" "Internal RHOAI"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service for PII and custom pattern detection via regex matching" {
            server = container "Axum HTTP Server" "Async HTTP server listening on port 8080" "Rust / Axum 0.7.9 / Tokio"
            builtinDetectors = container "Built-in PII Detectors" "Pre-compiled regex patterns for email, SSN, credit card" "Rust regex crate"
            customRegex = container "Custom Regex Engine" "Compiles and executes arbitrary regex from request params" "Rust regex crate"
        }

        llm = softwareSystem "LLM Inference Service" "Large Language Model serving predictions" "External"

        # Relationships
        orchestrator -> regexDetector "Sends text for PII/regex detection" "HTTP/8080 POST /api/v1/text/contents"
        orchestrator -> llm "Sends prompts / receives completions" "HTTP/gRPC"

        # Internal relationships
        server -> builtinDetectors "Invokes named patterns (email, ssn, credit-card)"
        server -> customRegex "Invokes custom regex from detector_params"
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
            description "Internal structure of the Guardrails Regex Detector service"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
