workspace {
    model {
        datascientist = person "Data Scientist / AI Engineer" "Deploys and manages autonomous AI agents"
        platformadmin = person "Platform Admin" "Configures workspaces, policies, and providers"

        openshell = softwareSystem "OpenShell" "Secure, policy-enforced runtime environment for autonomous AI agents with kernel-level isolation and formal policy verification" {
            gateway = container "OpenShell Gateway" "gRPC/HTTP control-plane server: sandbox lifecycle, provider credentials, OIDC auth, policy storage, peer relay" "Rust (axum + tonic)" "Service"
            supervisor = container "OpenShell Supervisor" "Per-sandbox enforcement: L7 network proxy, OPA/Rego policy evaluation, credential injection, process lifecycle" "Rust" "Service"
            sandbox = container "OpenShell Sandbox" "Workload-side runtime: seccomp mediation, filesystem access control, process identity, boundary protocol" "Rust (static binary)" "Service"
            prover = container "Policy Prover" "Formal verification of policy changes using Z3 SMT solver" "Rust + Z3" "Library"
            k8sDriver = container "Kubernetes Compute Driver" "Pod lifecycle, workspace modes (shared/managed/operator), NetworkPolicy" "Rust" "Service"
            dbCredStore = container "DB Credential Store" "AES-256-GCM encrypted credential storage" "Rust" "Service"
            cli = container "OpenShell CLI" "Command-line interface and TUI dashboard" "Rust" "CLI"
            pythonSDK = container "Python SDK" "Python gRPC client bindings" "Python" "Library"
            goSDK = container "Go SDK" "Go gRPC client with OIDC" "Go" "Library"
            tsSDK = container "TypeScript SDK" "Native Connect client" "TypeScript" "Library"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration and API server" "External"
        oidcProvider = softwareSystem "OIDC Provider" "User authentication and token validation" "External"
        vault = softwareSystem "Vault" "Secret management for provider credentials" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry distributed tracing" "External"
        upstreamAPIs = softwareSystem "Upstream AI APIs" "Anthropic, OpenAI, NVIDIA, and other AI provider endpoints" "External"
        envoyGateway = softwareSystem "Envoy Gateway" "External gRPC/HTTP ingress via Gateway API" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "External access via SNI-based TLS passthrough" "External"

        # User interactions
        datascientist -> cli "Creates sandboxes, runs agents" "gRPC/TLS"
        datascientist -> pythonSDK "Programmatic sandbox management" "gRPC/TLS"
        datascientist -> goSDK "Programmatic sandbox management" "gRPC/TLS"
        datascientist -> tsSDK "Programmatic sandbox management" "Connect/TLS"
        platformadmin -> gateway "Configures workspaces, policies, providers" "gRPC/TLS + OIDC"

        # Internal flows
        cli -> gateway "Sandbox CRUD, SSH, policy management" "gRPC/8080 TLS"
        pythonSDK -> gateway "Sandbox CRUD" "gRPC/8080 TLS"
        goSDK -> gateway "Sandbox CRUD" "gRPC/8080 TLS"
        tsSDK -> gateway "Sandbox CRUD" "Connect/8080 TLS"
        gateway -> k8sDriver "Create/delete sandbox pods" "gRPC (Unix socket)"
        gateway -> dbCredStore "Store/retrieve encrypted credentials" "gRPC (Unix socket)"
        gateway -> prover "Verify policy changes" "In-process"
        gateway -> supervisor "Session relay, bootstrap" "gRPC/5500 mTLS"
        supervisor -> sandbox "Policy enforcement, process control" "Sandbox Protocol (mTLS)"
        sandbox -> supervisor "Outbound network requests" "L7 proxy (mTLS)"

        # External dependencies
        gateway -> k8s "Pod lifecycle, RBAC, Secrets, TokenReview" "HTTPS/443"
        gateway -> oidcProvider "JWKS fetch, token validation" "HTTPS/443"
        gateway -> vault "Credential storage (optional)" "HTTPS/8200"
        gateway -> certManager "TLS certificate lifecycle (optional)" "Kubernetes API"
        gateway -> otlpCollector "Distributed tracing (optional)" "gRPC/4317"
        supervisor -> upstreamAPIs "Proxied agent API calls with injected credentials" "HTTPS/443"
        envoyGateway -> gateway "External gRPC ingress" "HTTP(S)/443"
        openshiftRouter -> gateway "External access (TLS passthrough)" "HTTPS/443"
        k8sDriver -> k8s "Create Sandbox CRs, Pods, NetworkPolicies" "HTTPS/443"
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
            element "Library" {
                background #7ed321
                color #ffffff
            }
            element "CLI" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
