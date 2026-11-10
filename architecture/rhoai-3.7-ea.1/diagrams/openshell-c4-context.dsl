workspace "OpenShell" "RHOAI 3.7 EA1 - policy-enforced sandbox runtime for AI agents" {
    model {
        user = person "AI Engineer / Admin" "Creates sandboxes, approves policies, manages providers"

        openshell = softwareSystem "OpenShell" "Policy-enforced sandbox runtime for autonomous AI agents" {
            gateway = container "openshell-gateway" "Control plane: sandbox/workspace/provider/policy gRPC API, auth, persistence, driver orchestration" "Rust, tonic + axum, 8080/TCP TLS"
            supervisor = container "openshell-supervisor" "Policy enforcer outside the workload: L7 proxy, OPA/Rego, credential injection, session runtime" "Rust, 5500/TCP gRPC TLS"
            sandbox = container "openshell-sandbox" "Static binary injected into agent images; filesystem and syscall confinement" "Rust static binary, SSH 2222/TCP"
            cli = container "openshell CLI" "User/admin client, OIDC PKCE login" "Rust CLI/TUI"
            db = container "Gateway Database" "Sandbox, workspace, policy and encrypted credential records" "SQLite PVC or PostgreSQL" "Database"
        }

        dashboard = softwareSystem "openshell-dashboard" "Web UI for workspaces, sandboxes and terminal" "Internal ODH"
        agentSandbox = softwareSystem "Kubernetes SIG Agent Sandbox" "agents.x-k8s.io Sandbox CRD and controller" "External"
        k8s = softwareSystem "Kubernetes API" "OpenShift cluster API" "External"
        oidc = softwareSystem "OIDC IdP" "Red Hat build of Keycloak / Entra ID / Okta" "External"
        providers = softwareSystem "Inference / Model Providers" "NVIDIA, Anthropic, OpenAI-compatible APIs" "External"
        router = softwareSystem "OpenShift Router" "Route with TLS passthrough" "Internal ODH"
        vault = softwareSystem "Vault / OpenBao" "Optional credential driver" "External"
        postgres = softwareSystem "PostgreSQL" "Optional HA persistence" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scrape" "External"
        otlp = softwareSystem "OTLP Collector" "Optional trace export" "External"
        certManager = softwareSystem "cert-manager" "Optional PKI issuance" "External"

        user -> cli "Uses"
        user -> dashboard "Uses via browser" "HTTPS, OIDC PKCE"
        cli -> router "gRPC" "443/TCP TLS"
        router -> gateway "TLS passthrough" "8080/TCP"
        dashboard -> gateway "gRPC/HTTP client" "8080/TCP TLS"
        gateway -> db "Reads/writes" "SQLite / PostgreSQL 5432 TLS"
        gateway -> k8s "Creates Sandbox CRs, Pods, Secrets, NetworkPolicies; TokenReview" "HTTPS 6443/TCP"
        gateway -> agentSandbox "Creates Sandbox resources" "agents.x-k8s.io"
        gateway -> oidc "Fetches JWKS" "HTTPS 443/TCP"
        gateway -> sandbox "SSH sessions" "SSH 2222/TCP"
        supervisor -> gateway "ConnectSupervisor, logs, status" "gRPC/TLS 8080, sandbox JWT"
        sandbox -> supervisor "Agent egress" "HTTP/CONNECT 5500/TCP TLS pinned"
        supervisor -> providers "Policy-approved requests with injected credentials" "HTTPS 443/TCP"
        gateway -> vault "Resolves credentials" "HTTPS 8200/TCP"
        gateway -> postgres "HA persistence" "5432/TCP TLS"
        prometheus -> gateway "Scrapes metrics" "HTTP 9090/TCP"
        gateway -> otlp "Exports traces" "gRPC 4317/TCP"
        certManager -> openshell "Issues server/client certificates"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}
