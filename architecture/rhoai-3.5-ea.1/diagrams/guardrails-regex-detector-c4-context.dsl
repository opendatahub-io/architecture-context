workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates guardrails pipeline for screening LLM inputs and outputs" "Internal Platform"

        regexDetector = softwareSystem "guardrails-regex-detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regular expressions" {
            httpServer = container "axum HTTP Server" "Handles incoming HTTP requests on port 8080" "Rust / axum 0.7.9"
            detectionEngine = container "Detection Engine" "Compiles and runs regex patterns against text content" "Rust / regex 1.11.1" {
                emailDetector = component "Email Detector" "Built-in PII detector for email addresses" "Hardcoded Regex"
                ssnDetector = component "SSN Detector" "Built-in PII detector for Social Security Numbers" "Hardcoded Regex"
                creditCardDetector = component "Credit Card Detector" "Built-in PII detector for credit card numbers" "Hardcoded Regex"
                customRegex = component "Custom Regex Handler" "Compiles and executes arbitrary client-supplied regex patterns" "Dynamic Regex"
            }
        }

        llm = softwareSystem "LLM Service" "Large Language Model providing inference" "External"
        user = person "Application User" "Sends prompts to LLM through guardrails pipeline"

        # Relationships
        user -> orchestrator "Sends prompts for LLM interaction"
        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 (plaintext, no auth)"
        orchestrator -> llm "Forwards screened prompts" "HTTP/HTTPS"

        # Internal relationships
        httpServer -> detectionEngine "Routes detection requests"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing guardrails-regex-detector within the Guardrails pipeline"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Container view of guardrails-regex-detector internals"
        }

        component detectionEngine "Components" {
            include *
            autoLayout
            description "Detection engine components showing built-in and custom regex detectors"
        }

        styles {
            element "Internal Platform" {
                background #4a90e2
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
        }
    }
}
