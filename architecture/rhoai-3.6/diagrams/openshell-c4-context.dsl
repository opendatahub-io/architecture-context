workspace {
    model {
        datascientist = person "Data Scientist / AI Developer" "Creates and deploys autonomous AI agents in sandboxed environments"
        platformadmin = person "Platform Admin" "Manages OpenShell gateway, policies, and workspaces"
        securityengineer = person "Security Engineer" "Reviews and approves sandbox policies using formal prover"

        openshell = softwareSystem "OpenShell" "Safe, private runtime for autonomous AI agents with kernel-level isolation and policy enforcement" {
            gateway = container "OpenShell Gateway" "gRPC/HTTP control plane: sandbox lifecycle, auth, provider management, policy enforcement, multi-gateway peering" "Rust (axum + tonic)" "StatefulSet"
            supervisor = container "Supervisor Sidecar" "Per-sandbox policy evaluation, credential injection, L7 network enforcement, OCSF audit logging" "Rust" "Sidecar"
            sandbox = container "Sandbox Binary" "Workload-side runtime: seccomp-mediated I/O, filesystem/network/syscall constraints, process monitoring" "Rust (static glibc)" "Injected Binary"
            prover = container "Policy Prover" "Formal policy verification using Z3 SMT solver — pre-approval review of policy changes" "Rust + Z3"
            cli = container "OpenShell CLI" "User-facing CLI for sandbox management, policy authoring, and gateway interaction" "Rust" "CLI"
            k8sDriver = container "Kubernetes Compute Driver" "Manages sandbox pods with per-pod identity and namespace isolation" "Rust" "Driver (UDS)"
            credDrivers = container "Credential Drivers" "Kubernetes Secrets, Vault, and database-backed credential storage" "Rust" "Driver (UDS)"
        }

        kubernetesApi = softwareSystem "Kubernetes API" "Container orchestration and RBAC" "External"
        oidcProvider = softwareSystem "OIDC Provider" "User identity and authentication" "External"
        aiProviders = softwareSystem "AI Inference Providers" "Upstream LLM and model inference services" "External"
        vault = softwareSystem "HashiCorp Vault" "Secret management and credential storage" "External (Optional)"
        postgresql = softwareSystem "PostgreSQL" "External database for multi-replica gateway state" "External (Optional)"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External (Optional)"

        # User interactions
        datascientist -> openshell "Creates sandboxes, runs agents via CLI/SDK" "gRPC/8080 TLS"
        platformadmin -> openshell "Manages workspaces, policies, providers" "gRPC/8080 TLS"
        securityengineer -> openshell "Reviews policy changes with formal prover" "CLI"

        # Internal container relationships
        gateway -> supervisor "Initialize sandbox, forward connections" "gRPC/5500 mTLS"
        gateway -> sandbox "SSH sessions" "SSH/2222"
        supervisor -> sandbox "Sandbox Protocol" "UDS gRPC"
        gateway -> k8sDriver "Sandbox CRUD" "UDS gRPC"
        gateway -> credDrivers "Credential resolution" "UDS gRPC"
        gateway -> prover "Policy verification" "Library call"
        cli -> gateway "User commands" "gRPC/8080 TLS"

        # External dependencies
        k8sDriver -> kubernetesApi "Pod lifecycle, token reviews" "HTTPS/443"
        gateway -> oidcProvider "User authentication" "HTTPS/443"
        supervisor -> aiProviders "Proxied inference requests with injected credentials" "HTTPS/443"
        credDrivers -> vault "Credential storage" "HTTPS/443"
        gateway -> postgresql "Multi-replica state" "PostgreSQL/5432"
        gateway -> otelCollector "Trace export" "gRPC"
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
            element "External (Optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "StatefulSet" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #27ae60
                color #ffffff
            }
            element "Injected Binary" {
                background #2ecc71
                color #ffffff
            }
            element "CLI" {
                background #3498db
                color #ffffff
            }
            element "Driver (UDS)" {
                background #e67e22
                color #ffffff
            }
        }
    }
}
