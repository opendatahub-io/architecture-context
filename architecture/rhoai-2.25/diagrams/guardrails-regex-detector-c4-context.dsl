workspace {
    model {
        operator = person "Platform Operator" "Deploys and configures the guardrails stack"
        llmUser = person "LLM User" "Sends prompts to LLM through guardrails"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regular expressions" {
            axumServer = container "Axum HTTP Server" "Handles HTTP requests on port 8080, routes to detection logic" "Rust / Axum 0.7.9"
            detectionEngine = container "Detection Engine" "Built-in PII detectors (email, SSN, credit card) and custom regex pattern matching" "Rust / regex 1.11.1"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes text content through multiple detector backends to enforce content safety guardrails on LLM inputs/outputs" "Internal RHOAI"

        trustyAI = softwareSystem "TrustyAI Stack" "RHOAI AI safety and trustworthiness platform" "Internal RHOAI"

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing network isolation and service discovery" "Infrastructure"

        # Relationships
        orchestrator -> regexDetector "Sends text content for regex-based PII scanning" "HTTP/8080 Plaintext"
        regexDetector -> orchestrator "Returns structured detection results with match offsets" "HTTP Response"

        llmUser -> orchestrator "Sends prompts through guardrails pipeline"
        orchestrator -> trustyAI "Part of TrustyAI guardrails stack"
        regexDetector -> kubernetes "Runs as ClusterIP service, relies on network isolation" "Pod-to-pod"

        # Internal container relationships
        axumServer -> detectionEngine "Routes detection requests"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context showing Guardrails Regex Detector within the RHOAI guardrails ecosystem"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Internal container view of the Guardrails Regex Detector service"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
