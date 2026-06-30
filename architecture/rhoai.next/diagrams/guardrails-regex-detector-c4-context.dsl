workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates content guardrails by dispatching text to detector backends and aggregating results" "Internal RHOAI"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regex matching" {
            httpServer = container "HTTP Server" "Axum-based HTTP API server accepting detection requests on port 8080" "Rust / Axum 0.7.9"
            builtInDetectors = container "Built-in Detectors" "Predefined regex patterns for email, SSN, and credit card detection" "Rust / regex 1.11.1"
            customRegex = container "Custom Regex Engine" "On-the-fly compilation and matching of user-supplied regex patterns" "Rust / regex 1.11.1"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing scheduling and health monitoring" "External"

        # Relationships
        orchestrator -> regexDetector "Sends text content for PII/pattern detection" "HTTP/8080 POST /api/v1/text/contents"
        kubernetes -> regexDetector "Liveness/readiness health probes" "HTTP/8080 GET /health"

        # Internal relationships
        httpServer -> builtInDetectors "Resolves named detector keys (email, ssn, credit-card)"
        httpServer -> customRegex "Compiles and executes arbitrary regex patterns"
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
                shape RoundedBox
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
