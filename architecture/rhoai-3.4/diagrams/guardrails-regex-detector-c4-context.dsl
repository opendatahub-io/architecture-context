workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Sends text content for regex-based PII and pattern detection; aggregates results from multiple detectors"

        regexDetector = softwareSystem "Guardrails Regex Detector" "Lightweight Rust HTTP service that detects PII and custom patterns in text using regular expressions" {
            server = container "axum HTTP Server" "Handles HTTP routing and request/response lifecycle" "Rust / axum 0.7.9"
            detectionEngine = container "Detection Engine" "Pattern registry with built-in PII detectors (email, SSN, credit card) and custom regex compilation" "Rust / regex 1.11.1"
        }

        platformSecurity = softwareSystem "Platform Security Infrastructure" "Provides network isolation, mTLS, and auth proxy for cluster-internal services" "External" {
            networkPolicies = container "Kubernetes Network Policies" "Restricts pod-to-pod communication" "Kubernetes"
            serviceMesh = container "Service Mesh" "Provides mTLS encryption between services" "Istio / OSSM"
            kubeRBACProxy = container "kube-rbac-proxy" "Sidecar providing authentication and authorization" "kube-rbac-proxy"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster orchestration (not accessed by this component)" "External"

        orchestrator -> regexDetector "POST /api/v1/text/contents" "HTTP/8080 (plaintext)"
        orchestrator -> regexDetector "GET /health" "HTTP/8080 (plaintext)"
        platformSecurity -> regexDetector "Enforces mTLS, network isolation, auth proxy" "Platform-level"
    }

    views {
        systemContext regexDetector "SystemContext" {
            include *
            autoLayout
            description "System context for the Guardrails Regex Detector showing its role as an internal detection backend"
        }

        container regexDetector "Containers" {
            include *
            autoLayout
            description "Internal structure of the Guardrails Regex Detector"
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
                background #9013fe
                color #ffffff
                shape Person
            }
            element "Container" {
                background #5ba5e6
                color #ffffff
            }
        }
    }
}
