workspace {
    model {
        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes content through multiple detectors before allowing LLM responses" "Internal RHOAI"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Stateless HTTP service that detects PII and custom patterns in text using regular expressions" {
            axumRouter = container "Axum HTTP Router" "Routes incoming requests to detection or health endpoints" "Rust / Axum 0.7.9"
            detectorEngine = container "Detector Engine" "Resolves named patterns and compiles custom regexes, executes matching" "Rust / regex 1.11.1"
            builtinDetectors = container "Built-in Detectors" "Hardcoded patterns for email, SSN, credit card detection" "Rust"
        }

        serviceMesh = softwareSystem "Service Mesh" "Provides mTLS transport security and authorization policies" "Platform Infrastructure"
        networkPolicy = softwareSystem "Network Policy" "Restricts pod-to-pod network access" "Platform Infrastructure"
        foundationModel = softwareSystem "Foundation Model" "LLM whose responses are screened by guardrails" "External"

        orchestrator -> regexDetector "Sends text for regex-based detection" "HTTP/8080"
        orchestrator -> foundationModel "Sends prompts, receives responses" "HTTP/HTTPS"

        regexDetector -> serviceMesh "Transport security delegated to" "mTLS"
        regexDetector -> networkPolicy "Network isolation managed by" "Kubernetes"
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
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Platform Infrastructure" {
                background #f5a623
            }
            element "External" {
                background #999999
            }
        }
    }
}
