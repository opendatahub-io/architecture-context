workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Routes detection requests to multiple detector services and aggregates results for guardrails policy enforcement"

        regexDetector = softwareSystem "guardrails-regex-detector" "Stateless Rust HTTP service that detects PII and custom patterns in text using regular expressions" {
            axumServer = container "Axum HTTP Server" "Async HTTP server handling routing and request deserialization" "Rust / Axum 0.7.9 / Tokio"
            builtInDetectors = container "Built-in PII Detectors" "Pre-defined regex patterns for email, SSN, and credit card detection" "Rust regex crate"
            customRegexEngine = container "Custom Regex Engine" "Compiles and executes user-supplied regex patterns per request" "Rust regex crate"
        }

        kubernetes = softwareSystem "Kubernetes Platform" "Container orchestration, probes, and resource management" "External"
        serviceMesh = softwareSystem "Service Mesh" "Expected mTLS encryption and network-level access control" "External"

        orchestrator -> regexDetector "Sends text content for PII/pattern detection" "HTTP/8080 JSON"
        regexDetector -> orchestrator "Returns detection results with offsets and classifications" "HTTP JSON Response"
        kubernetes -> regexDetector "Liveness probe" "HTTP GET /health :8080"
        serviceMesh -> regexDetector "Expected: provides mTLS and network isolation" "mTLS"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
