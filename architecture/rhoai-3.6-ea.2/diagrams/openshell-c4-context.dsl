workspace {
    model {
        aiEngineer = person "AI Engineer / Data Scientist" "Creates and manages sandboxed AI agent environments"

        openshell = softwareSystem "OpenShell" "Safe, private runtime for autonomous AI agents with policy-enforced sandboxed execution" {
            gateway = container "OpenShell Gateway" "Control-plane gRPC/HTTP server managing sandbox lifecycle, auth, and provider coordination" "Rust (axum + tonic)" "Service"
            supervisor = container "OpenShell Supervisor" "Policy enforcement sidecar: L7 proxy, OPA evaluation, credential injection" "Rust (static binary)" "Service"
            sandbox = container "OpenShell Sandbox" "In-container process monitor with seccomp and capability-free workload launcher" "Rust (static glibc binary)" "Binary"
            cli = container "OpenShell CLI" "User-facing command-line interface for sandbox management" "Rust (static binary)" "CLI"
            tui = container "OpenShell TUI" "Real-time terminal dashboard for monitoring" "Rust (ratatui)" "TUI"
            policyEngine = container "Policy Engine" "Sandbox policy parsing, filesystem/network/process constraint evaluation, Z3 formal verification" "Rust (regorus + z3)" "Library"
            rustSDK = container "Rust SDK" "Async Rust client SDK for gateway gRPC transport" "Rust" "Library"
            pythonSDK = container "Python SDK" "Python gRPC client with protobuf bindings" "Python" "Library"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        sandboxCRD = softwareSystem "agents.x-k8s.io Sandbox CRD" "Agent sandbox lifecycle coordination" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "External ingress via GRPCRoute" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External ingress via OpenShift Routes" "External"
        postgresql = softwareSystem "PostgreSQL" "External database for multi-replica gateways" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace export" "External"
        modelProviders = softwareSystem "Model Provider APIs" "AI model inference endpoints (Anthropic, GCP, NVIDIA)" "External"

        # User interactions
        aiEngineer -> cli "Creates sandboxes, manages providers via" "CLI"
        aiEngineer -> tui "Monitors sandbox status via" "Terminal"
        cli -> gateway "gRPC requests" "gRPC/8080 TLS"
        tui -> gateway "gRPC requests" "gRPC/8080 TLS"
        rustSDK -> gateway "gRPC requests" "gRPC/8080 TLS"
        pythonSDK -> gateway "gRPC requests" "gRPC/8080 TLS"

        # Internal flows
        gateway -> policyEngine "Verifies policy boundaries" "In-process"
        gateway -> sandbox "SSH connection for sandbox setup" "SSH/2222 mTLS"
        supervisor -> gateway "Session registration" "gRPC/8080 mTLS"
        supervisor -> sandbox "Isolation protocol" "gRPC over UDS"
        supervisor -> policyEngine "OPA policy evaluation" "In-process"

        # External dependencies
        gateway -> kubernetesAPI "Pod CRUD, TokenReview, namespace management" "HTTPS/443"
        gateway -> sandboxCRD "Sandbox lifecycle coordination" "HTTPS/443"
        gateway -> certManager "Optional PKI for TLS certificates" "HTTPS/443"
        gateway -> postgresql "Multi-replica state storage" "TCP/5432 TLS"
        gateway -> otlpCollector "Trace export" "gRPC/4317"
        gatewayAPI -> gateway "External ingress" "HTTPS/443"
        openshiftRoutes -> gateway "External ingress" "HTTPS/443 passthrough"
        supervisor -> modelProviders "Policy-admitted, credential-injected inference" "HTTPS/443"
    }

    views {
        systemContext openshell "SystemContext" {
            include *
            autoLayout
        }

        container openshell "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Binary" {
                background #e8744f
                color #ffffff
            }
            element "CLI" {
                background #7ed321
                color #ffffff
            }
            element "TUI" {
                background #7ed321
                color #ffffff
            }
            element "Library" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
