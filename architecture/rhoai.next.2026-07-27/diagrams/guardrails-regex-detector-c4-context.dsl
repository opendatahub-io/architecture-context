workspace {
    model {
        guardrailsOrchestrator = person "Guardrails Orchestrator" "Upstream service that routes text content through detection pipelines"

        regexDetector = softwareSystem "guardrails-regex-detector" "Regex-based text content detection service for AI guardrails" {
            server = container "regex-detector" "Single async Rust binary serving HTTP on port 8080" "Rust / Axum 0.7.9 / Tokio 1.41.1" {
                router = component "Axum Router" "Routes HTTP requests to handlers"
                traceLayer = component "TraceLayer" "Request/response logging middleware (tower-http)"
                healthHandler = component "Health Handler" "Returns static health status on GET /health"
                detectorsHandler = component "Detectors Handler" "Regex-based text content detection on POST /api/v1/text/contents"
                regexEngine = component "Regex Engine" "Compiles and evaluates regex patterns against input text (regex crate)"
            }
        }

        serviceMesh = softwareSystem "Service Mesh" "Infrastructure-level TLS termination, mTLS, and auth (e.g., Istio)" "External Infrastructure"
        healthMonitor = softwareSystem "Health Monitor" "Kubernetes liveness/readiness probes" "External Infrastructure"

        # Relationships
        guardrailsOrchestrator -> regexDetector "Sends text content for regex detection" "HTTP POST /api/v1/text/contents"
        healthMonitor -> regexDetector "Checks service health" "HTTP GET /health"
        serviceMesh -> regexDetector "Provides TLS termination, mTLS, authentication" "Sidecar proxy"

        # Internal relationships
        router -> traceLayer "Applies middleware"
        traceLayer -> healthHandler "Routes GET /health"
        traceLayer -> detectorsHandler "Routes POST /api/v1/text/contents"
        detectorsHandler -> regexEngine "Evaluates regex patterns"
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

        component server "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
