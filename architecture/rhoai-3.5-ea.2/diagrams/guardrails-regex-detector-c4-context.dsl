workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Coordinates text content analysis across multiple detector backends (regex, HAP, toxicity, etc.)" "Internal Platform"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP microservice that detects PII and custom patterns in text using regex matching" {
            server = container "Axum HTTP Server" "Handles incoming HTTP requests on port 8080" "Rust / Axum 0.7.9"
            detectorRegistry = container "Detector Registry" "HashMap of built-in detectors (email, ssn, credit-card) and custom regex patterns" "Rust"
            regexEngine = container "Regex Engine" "Finite automaton-based regex matching (linear time, ReDoS-safe)" "Rust regex 1.11.1"
        }

        llmService = softwareSystem "LLM / Model Service" "Language model serving endpoint that generates text to be guardrailed" "External"
        user = person "End User / Application" "Sends prompts to LLM via Guardrails Orchestrator for content safety"

        # Relationships
        user -> orchestrator "Sends text for guardrailed inference"
        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 Plaintext"
        orchestrator -> llmService "Forwards text for inference"

        # Internal container relationships
        server -> detectorRegistry "Looks up detector by name or compiles custom regex"
        detectorRegistry -> regexEngine "Applies regex patterns to text content"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing Guardrails Regex Detector within the Guardrails stack"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Internal container view of the Regex Detector service"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
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
