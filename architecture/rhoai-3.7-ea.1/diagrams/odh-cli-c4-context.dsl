workspace "odh-cli" "RHOAI 3.7.0-ea.1 client-side upgrade-readiness and migration CLI" {
    model {
        admin = person "Cluster Administrator" "Runs upgrade-readiness checks and migrations with their kubeconfig"
        agent = person "MCP Client (AI agent)" "Calls CLI tools over MCP stdio or SSE (hidden mcp serve)"

        odhcli = softwareSystem "odh-cli (rhai-cli / kubectl-odh)" "Client-side kubectl plugin for lint, migrate and diagnostics. No in-cluster footprint." {
            root = container "Root Command" "Cobra root; wires kubectl ConfigFlags (kubeconfig, token, certs, OIDC)" "Go / Cobra"
            lint = container "lint" "Version-aware read-only upgrade-readiness checks; exit codes 0/1/2" "Go"
            migrate = container "migrate" "Phased migration actions (prepare/run/verify) for 2.x to 3.x" "Go"
            deps = container "deps (hidden)" "Installs operator dependencies via OLM v0/v1 from embedded or fetched odh-gitops manifest" "Go"
            mcp = container "mcp serve (hidden)" "MCP server: stdio or SSE on 127.0.0.1:8080, no auth" "Go / mcp-go"
            diagnose = container "diagnose (hidden)" "Cluster health diagnosis using opendatahub-operator libs" "Go"
            image = container "Container Image" "quay.io/rhoai/odh-cli-rhel9 on ose-cli-rhel9; oc, kubectl, jq; KUBECONFIG=/kubeconfig" "Container (one-shot)"
        }

        k8s = softwareSystem "Kubernetes / OpenShift API Server" "Cluster API; enforces user RBAC" "External"
        odhOperator = softwareSystem "opendatahub-operator" "DSC/DSCI CRs; Go libs clusterhealth, failureclassifier, mcptools" "Internal ODH"
        olm = softwareSystem "Operator Lifecycle Manager v0/v1" "Subscription, OperatorGroup, CSV, ClusterExtension, ClusterCatalog" "External"
        trustyai = softwareSystem "TrustyAI Service" "Fairness/drift metrics via OpenShift Route" "Internal ODH"
        components = softwareSystem "Platform Component CRs" "KServe, Kueue/RHBOK, Ray, Training, Notebooks, DSPA, LlamaStack/OGX, Dashboard, Kuadrant, Gateway API, Feast, Model Registry" "Internal ODH"
        platformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, OLM helpers (Go library v0.4.0)" "Internal ODH"
        gitops = softwareSystem "odh-gitops (GitHub)" "Dependency manifest at raw.githubusercontent.com" "External"

        admin -> root "Invokes kubectl odh / rhai-cli"
        agent -> mcp "MCP tool calls" "stdio or HTTP/8080 loopback (no auth)"
        root -> lint "Dispatches"
        root -> migrate "Dispatches"
        root -> deps "Dispatches"
        root -> mcp "Dispatches"
        root -> diagnose "Dispatches"

        lint -> k8s "Read-only list/get, discovery" "HTTPS/6443 TLS 1.2+"
        migrate -> k8s "SSAR pre-flight, patch/create, SPDY pod exec" "HTTPS/6443 TLS 1.2+"
        deps -> k8s "Create Namespace/OperatorGroup/Subscription/ClusterExtension, poll CSV" "HTTPS/6443 TLS 1.2+"
        diagnose -> k8s "Reads cluster health" "HTTPS/6443 TLS 1.2+"
        migrate -> trustyai "Read/replay metric requests (bearer token, cert verify disabled)" "HTTPS/443 TLS 1.2"
        deps -> gitops "Optional manifest fetch" "HTTPS/443"

        odhcli -> odhOperator "Reads/migrates DSC/DSCI; imports Go libs"
        odhcli -> olm "Installs and detects operators" "via API server"
        odhcli -> components "Lint checks and migrations" "via API server"
        odhcli -> platformUtils "Imports Go library"
    }

    views {
        systemContext odhcli "SystemContext" {
            include *
            autoLayout
        }

        container odhcli "Containers" {
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
                background #9fc5f8
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}
