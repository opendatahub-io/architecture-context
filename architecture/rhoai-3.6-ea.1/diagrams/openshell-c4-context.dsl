workspace {
    model {
        user = person "Data Scientist / AI Agent" "Creates and manages sandboxed AI agent environments"

        openshell = softwareSystem "OpenShell" "Sandboxed runtime platform for autonomous AI agents with policy-enforced network egress and credential-injected inference routing" {
            gateway = container "OpenShell Gateway" "Control-plane gRPC/HTTP service managing sandbox lifecycle, provider credentials, inference routing, and policy enforcement" "Rust (tonic/axum)" {
                tags "Core"
            }
            supervisor = container "Sandbox Supervisor" "Process and network supervisor injected into sandbox containers enforcing egress policy via OPA, L7 inspection, seccomp, and Landlock" "Rust" {
                tags "Core"
            }
            cli = container "OpenShell CLI" "User-facing command-line interface with OIDC device flow authentication" "Rust (static binary)" {
                tags "Client"
            }
            sdk = container "OpenShell SDK" "Async Rust gRPC client library with TLS, OIDC refresh, and edge tunnel support" "Rust" {
                tags "Client"
            }
            pythonSdk = container "Python SDK" "Python gRPC client bindings via maturin with protobuf stubs" "Python (maturin)" {
                tags "Client"
            }
            router = container "Inference Router" "Multiplexes sandbox requests to upstream model endpoints" "Rust" {
                tags "Core"
            }
            prover = container "Policy Prover" "SMT-based formal verification engine using Z3 for detecting data exfiltration paths" "Rust (Z3)" {
                tags "Security"
            }
            tui = container "OpenShell TUI" "Terminal UI dashboard for sandbox monitoring and management" "Rust (ratatui)" {
                tags "Client"
            }
        }

        kubernetesApi = softwareSystem "Kubernetes API" "Container orchestration platform" {
            tags "External"
        }
        oidcProvider = softwareSystem "OIDC Identity Provider" "User authentication via JWT bearer tokens" {
            tags "External"
        }
        vault = softwareSystem "HashiCorp Vault" "Provider credential storage and retrieval" {
            tags "External"
        }
        postgresql = softwareSystem "PostgreSQL" "State persistence for multi-replica deployments" {
            tags "External"
        }
        envoyGateway = softwareSystem "Envoy Gateway" "Optional gRPC ingress via Gateway API" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" {
            tags "External"
        }
        spiffe = softwareSystem "SPIFFE/SPIRE" "Optional workload identity token grants" {
            tags "External"
        }
        llmProviders = softwareSystem "Upstream LLM Providers" "OpenAI, Claude, Vertex AI, Bedrock inference endpoints" {
            tags "External"
        }

        // User interactions
        user -> cli "Manages sandboxes and providers" "gRPC"
        user -> tui "Monitors sandbox activity" "TUI"

        // Client to Gateway
        cli -> sdk "Uses"
        tui -> sdk "Uses"
        sdk -> gateway "gRPC API calls" "gRPC/8080 TLS 1.2+"
        pythonSdk -> gateway "gRPC API calls" "gRPC/8080 TLS 1.2+"

        // Gateway to platform services
        gateway -> kubernetesApi "Pod lifecycle, token review, node topology" "HTTPS/6443"
        gateway -> oidcProvider "JWKS fetch for JWT validation" "HTTPS/443"
        gateway -> vault "Provider credential storage" "HTTPS/8200"
        gateway -> postgresql "State persistence" "SQL/5432"
        gateway -> supervisor "Sandbox control stream" "gRPC mTLS"

        // Gateway internal
        gateway -> router "Routes inference requests"
        gateway -> prover "Verifies sandbox policies" "Z3 SMT"

        // External ingress
        envoyGateway -> gateway "Routes external gRPC traffic" "gRPC/443"
        certManager -> gateway "Provisions TLS certificates" "K8s CRD"
        spiffe -> gateway "Workload identity tokens" "Unix socket"

        // Supervisor egress
        supervisor -> llmProviders "Policy-enforced inference requests" "HTTPS/443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Core" {
                background #4a90e2
            }
            element "Client" {
                background #50c878
            }
            element "Security" {
                background #e74c3c
            }
        }
    }
}
