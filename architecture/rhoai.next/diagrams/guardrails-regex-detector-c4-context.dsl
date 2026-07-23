workspace {
    model {
        aiPipeline = person "AI Inference Pipeline" "Processes user prompts through safety guardrails before/after model inference"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust microservice that detects PII and custom patterns in text using regular expressions" {
            httpServer = container "Axum HTTP Server" "Receives detection requests on port 8080" "Rust / Axum 0.7.9"
            patternDispatcher = container "Pattern Dispatcher" "Routes pattern names to built-in or custom regex detectors" "Rust / HashMap"
            builtinDetectors = container "Built-in Detectors" "Pre-defined regex patterns for email, SSN, credit card" "Rust / regex 1.11.1"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes text content to appropriate detection backends based on guardrails configuration" "Internal RHOAI"

        user = person "End User" "Sends prompts to AI models via inference API"

        # Relationships
        user -> orchestrator "Sends prompts (indirectly via inference pipeline)"
        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080, plaintext, no auth"
        regexDetector -> orchestrator "Detection results (JSON)" "HTTP response"

        # Internal container relationships
        httpServer -> patternDispatcher "Dispatches pattern names"
        patternDispatcher -> builtinDetectors "Looks up built-in patterns"
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
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
