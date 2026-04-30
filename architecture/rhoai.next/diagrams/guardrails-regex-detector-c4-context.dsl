workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Routes content inspection requests to detection backends"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regex matching" {
            axumServer = container "Axum HTTP Server" "Routes HTTP requests, binds to 0.0.0.0:8080" "Rust / Axum 0.7.9"
            detectionEngine = container "Detection Engine" "Performs regex pattern matching against text content" "Rust / regex 1.11.1"
            builtinRegistry = container "Builtin Pattern Registry" "HashMap of named PII patterns (email, ssn, credit-card)" "Rust HashMap"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        orchestrator -> regexDetector "Sends text content for PII/pattern inspection" "HTTP POST /api/v1/text/contents, 8080/TCP, No TLS"
        k8s -> regexDetector "Health check probes" "HTTP GET /health, 8080/TCP"

        axumServer -> detectionEngine "Delegates pattern matching"
        detectionEngine -> builtinRegistry "Looks up builtin patterns by name"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing Guardrails Regex Detector in the RHOAI Guardrails ecosystem"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Internal structure of the Guardrails Regex Detector service"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape Person
            }
        }
    }
}
