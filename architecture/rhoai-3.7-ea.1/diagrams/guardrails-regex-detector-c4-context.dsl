workspace "guardrails-regex-detector" "RHOAI 3.7 EA1 — standalone regex/PII detector for FMS Guardrails" {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Calls detectors over the text contents API" "Internal RHOAI"
        kubelet = softwareSystem "Kubelet" "Runs liveness probes" "External"
        builtInDetector = softwareSystem "guardrails-detectors (odh-built-in-detector)" "Operator-shipped regex/PII detector; functional overlap" "Internal RHOAI"
        logging = softwareSystem "Container Log Aggregation" "Receives stdout logs, including full request payloads" "External"

        regexDetector = softwareSystem "guardrails-regex-detector" "Stateless Rust/Axum HTTP service that matches built-in PII or custom regexes and returns spans" {
            server = container "regex-detector" "Axum router, TraceLayer, plain-HTTP Tokio listener on 0.0.0.0:8080" "Rust 1.84 / Axum 0.7"
            detectors = container "detectors module" "Built-in email/SSN/credit-card regexes and custom-regex matching" "Rust regex 1.11"
            server -> detectors "Dispatches each content x pattern"
        }

        orchestrator -> server "POST /api/v1/text/contents (no auth, no TLS)" "HTTP/8080"
        kubelet -> server "GET /health" "HTTP/8080"
        server -> logging "INFO logs incl. full payload (PII)" "stdout"
        regexDetector -> builtInDetector "Functional overlap (no deployment reference found)"
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
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
