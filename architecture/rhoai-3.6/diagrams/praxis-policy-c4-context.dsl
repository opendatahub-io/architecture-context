workspace {
    model {
        agent = person "AI Agent" "LLM-based agent that invokes tools, prompts, and resources"
        operator = person "Platform Operator" "Configures APL policy and PPE extensions"

        praxisProxy = softwareSystem "Praxis Proxy" "Host application that embeds PPE and provides HTTP serving, deployment topology, and wire-level integration" {
            httpLayer = container "HTTP Serving Layer" "Receives agent/client requests and routes to PPE" "Rust Service"
            ppe = container "Praxis Policy Engine (PPE)" "Deterministic reference monitor for AI agent traffic — identity, authorization, delegation, redaction, audit" "Rust Library" {
                facade = component "praxis-policy" "Facade crate — re-exports runtime, macro-generated builtin registration" "Rust Crate"
                core = component "ppe-core" "PolicyEngine, five-phase executor, hook registry, config parser, secrets management" "Rust Crate"
                aplRuntime = component "ppe-apl-runtime" "Per-hook PluginInvoker implementations, route handler, session management" "Rust Crate"
                aplCmf = component "ppe-apl-cmf" "Extension ↔ AttributeBag bridge for APL predicates" "Rust Crate"
                aplCore = component "ppe-apl-core" "APL compiler and evaluator" "Rust Crate"
                orchestration = component "ppe-orchestration" "Async concurrency primitives (branch parallelism)" "Rust Crate"
                builtins = component "praxis-policy-builtins" "9 feature-gated extensions: JWT, API-key, OAuth, CIBA, Cedar, CEL, OPA, Valkey, Vault" "Rust Crate"
                transport = component "HyperTransport" "Outbound HTTP with rustls TLS, egress deny table (SSRF protection)" "Rust Module"
            }
        }

        idp = softwareSystem "Identity Provider" "OIDC-compliant IdP providing JWKS and token exchange endpoints" "External"
        valkey = softwareSystem "Valkey / Redis" "Distributed key-value store for session taint persistence" "External"
        vault = softwareSystem "HashiCorp Vault" "Secret management system providing KV v2 API" "External"
        cibaProvider = softwareSystem "CIBA Provider" "Backchannel authentication provider for out-of-band human approval" "External"

        # Relationships
        agent -> praxisProxy "Sends tool/prompt/resource calls via HTTP" "HTTPS/443"
        operator -> praxisProxy "Configures APL policy and extension settings" "YAML config"

        praxisProxy -> idp "Fetches JWKS keys and exchanges tokens" "HTTPS/443"
        praxisProxy -> valkey "Persists session taint labels" "Redis/6379"
        praxisProxy -> vault "Retrieves secret material" "HTTPS/8200"
        praxisProxy -> cibaProvider "Requests out-of-band human approval" "HTTPS/443"

        # Internal
        httpLayer -> ppe "Invokes policy evaluation" "Rust API"
        facade -> core "Re-exports runtime"
        facade -> builtins "Registers extensions"
        core -> aplRuntime "Dispatches hooks"
        aplRuntime -> aplCmf "Maps extensions to attributes"
        aplCmf -> aplCore "Evaluates APL predicates"
        core -> orchestration "Branch parallelism"
        builtins -> transport "Outbound HTTP for IdP, Vault"
    }

    views {
        systemContext praxisProxy "SystemContext" {
            include *
            autoLayout
            description "Praxis Proxy with embedded PPE in the context of external systems"
        }

        container praxisProxy "Containers" {
            include *
            autoLayout
            description "PPE as an embedded library within the Praxis Proxy host"
        }

        component ppe "PPEComponents" {
            include *
            autoLayout
            description "Internal crate structure of the Praxis Policy Engine"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
        }
    }
}
