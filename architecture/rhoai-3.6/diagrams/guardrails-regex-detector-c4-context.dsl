workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes text content through detector backends to identify sensitive or policy-violating content in LLM inputs/outputs" "Internal TrustyAI"

        regexDetector = softwareSystem "guardrails-regex-detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regular expressions" {
            axumServer = container "Axum HTTP Server" "Accepts POST requests on port 8080, routes to detection handler" "Rust / Axum 0.7.9"
            detectionEngine = container "Detection Engine" "Matches text against built-in PII patterns (email, SSN, credit card) and custom regex" "Rust / regex 1.11.1"
        }

        llmService = softwareSystem "LLM Service" "Large Language Model serving endpoint" "External"
        user = person "End User" "Sends prompts to LLM via guardrails pipeline"

        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and authorization policies" "Platform Infrastructure"
        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "Platform Infrastructure"

        # Relationships
        user -> orchestrator "Sends text prompts for guarded LLM interaction"
        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 (plain; Istio mTLS if mesh enabled)"
        orchestrator -> llmService "Forwards sanitized prompts" "HTTP/HTTPS"

        # Internal container relationships
        axumServer -> detectionEngine "Dispatches detection requests"

        # Platform relationships
        regexDetector -> istio "TLS termination delegated to sidecar proxy" "" "implicit"
        regexDetector -> kubernetes "Deployed as a Pod" "" "implicit"
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
            element "Internal TrustyAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
