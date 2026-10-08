workspace {
    model {
        aiAgent = person "AI Agent" "LLM-driven agent attempting tool calls, resource access, and data operations"
        operator = person "Platform Operator" "Configures APL policy, secrets, and engine settings"

        praxisPolicy = softwareSystem "Praxis Policy Engine (PPE)" "Typed, phased policy engine library for AI agent traffic authorization, identity resolution, credential delegation, data-flow control, and audit" {
            facade = container "praxis-policy" "Facade crate — re-exports runtime and feature-gated builtins" "Rust Library (crates.io)"
            core = container "praxis-policy-core" "PolicyEngine, 5-phase executor, hook registry, config parser, HTTP transport seam" "Rust Library"
            aplCore = container "praxis-policy-apl-core" "APL compiler and evaluator — rules, effects, field pipelines, routes" "Rust Library"
            aplCmf = container "praxis-policy-apl-cmf" "APL-to-PPE bridge — typed extension to flat AttributeBag mapping" "Rust Library"
            aplRuntime = container "praxis-policy-apl-runtime" "Per-hook PluginInvoker implementations, route dispatch, session management" "Rust Library"
            orchestration = container "praxis-policy-orchestration" "Async branch-concurrency primitives" "Rust Library"
            builtins = container "praxis-policy-builtins" "9 bundled extensions: JWT, API-key, OAuth, CIBA, Cedar, CEL, OPA, Valkey, Vault" "Rust Library"
        }

        praxisProxy = softwareSystem "Praxis Proxy" "Primary host — embeds PPE as its policy enforcement layer, provides pingora-backed HTTP transport" "Internal"
        idp = softwareSystem "Identity Provider" "OIDC-compliant IdP providing JWKS, token exchange, and CIBA endpoints" "External"
        valkey = softwareSystem "Valkey / Redis" "Session taint label persistence across processes and replicas" "External"
        vault = softwareSystem "HashiCorp Vault" "Secret material resolution via KV v2 API" "External"
        limitador = softwareSystem "Limitador" "Experimental token quota enforcement" "External"

        # Relationships
        praxisProxy -> praxisPolicy "Embeds as library, invokes policy evaluation" "In-process function call"
        operator -> praxisPolicy "Configures APL policy, secrets, engine settings" "YAML configuration files"

        praxisPolicy -> idp "Fetches JWKS keys, exchanges tokens, requests CIBA approval" "HTTPS/443, TLS 1.2+ (rustls/ring)"
        praxisPolicy -> valkey "Persists session taint labels" "Redis/6379, Optional TLS"
        praxisPolicy -> vault "Resolves secret material at startup" "HTTPS/8200, TLS required"
        praxisPolicy -> limitador "Enforces token quotas (experimental)" "HTTP/configurable"

        # Internal container relationships
        facade -> core "Re-exports"
        facade -> builtins "Feature-gates"
        core -> aplRuntime "Invokes per-hook"
        aplRuntime -> aplCmf "Maps attributes"
        aplCmf -> aplCore "Compiles and evaluates"
        core -> orchestration "Uses concurrency primitives"
    }

    views {
        systemContext praxisPolicy "SystemContext" {
            include *
            autoLayout
        }

        container praxisPolicy "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
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
        }
    }
}
