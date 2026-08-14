workspace {
    model {
        orchestrator = softwareSystem "Guardrails Orchestrator" "Coordinates guardrails pipeline for content moderation" "External Caller"

        regexDetector = softwareSystem "guardrails-regex-detector" "Lightweight Rust microservice for regex-based PII and content detection" {
            axumServer = container "Axum HTTP Server" "Serves detection API and health endpoints on port 8080" "Rust / Axum 0.7.9 / Tokio 1.41.1"
            detectorRegistry = container "Detector Registry" "HashMap mapping detector keys to regex functions" "Rust HashMap"
            builtinDetectors = container "Built-in Detectors" "Pre-compiled regex patterns for email, SSN, credit card" "Rust regex crate"
            customRegex = container "Custom Regex Engine" "Compiles and executes arbitrary regex patterns at request time" "Rust regex crate"
        }

        k8s = softwareSystem "Kubernetes Platform" "Container orchestration and service mesh" "Infrastructure"

        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 · No app-layer TLS/auth"
        k8s -> regexDetector "GET /health (probes)" "HTTP/8080"

        axumServer -> detectorRegistry "Looks up built-in detector by key"
        axumServer -> customRegex "Compiles and runs custom regex"
        detectorRegistry -> builtinDetectors "Invokes detector function"
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
            element "External Caller" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #666666
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
        }
    }
}
