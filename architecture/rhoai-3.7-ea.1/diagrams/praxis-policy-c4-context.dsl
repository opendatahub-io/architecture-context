workspace "praxis-policy" "Praxis Policy Engine (PPE), RHOAI 3.7-ea.1" {
    model {
        agent = person "AI Agent / Client" "Calls tools, resources, prompts, LLMs and HTTP routes through Praxis"
        operator = person "Platform Operator" "Authors YAML policy documents and selects Cargo features for the host build"

        praxis = softwareSystem "Praxis proxy" "AI agent/tool proxy that embeds the policy engine, owns the listener, transport and FIPS config" "Internal RHOAI" {
            listener = container "Praxis listener" "Inbound HTTP(S) and upstream forwarding" "Rust / pingora"
            transport = container "HttpTransport" "Host-injected pingora-backed outbound HTTP" "Rust / pingora"

            ppe = container "praxis-policy facade" "Host-facing facade, crypto_capability_report(), optional http-hyper" "Rust library"
            core = container "ppe-core" "PolicyEngine, executor, hooks, config, identity/delegation/elicitation abstractions, crypto backend" "Rust library"
            orchestration = container "ppe-orchestration" "Async branch concurrency primitives" "Rust library"
            runtime = container "ppe-apl-runtime" "PluginInvokers, route handler, PDP router, decision cache, session resolver" "Rust library"
            cmf = container "ppe-apl-cmf" "Maps Common Message Format to AttributeBags" "Rust library"
            aplcore = container "ppe-apl-core" "APL parser, compiler, evaluator" "Rust library"
            builtins = container "praxis-policy-builtins" "JWT/DPoP, API key, OAuth, Vault, CIBA, Cedar, CEL, OPA, Valkey, Limitador quota" "Rust library (feature-gated)"
        }

        idp = softwareSystem "OIDC IdP (Keycloak)" "JWKS, RFC 8693 token exchange, CIBA" "External"
        vault = softwareSystem "HashiCorp Vault" "KV v2 secrets, Kubernetes/JWT/AppRole login, credential delegation" "External"
        valkey = softwareSystem "Valkey / Redis" "Session Taint, CIBA correlation, DPoP replay store" "External"
        limitador = softwareSystem "Limitador (Kuadrant)" "Experimental per-principal token quota" "External"
        apikeydir = softwareSystem "HTTP API-key directory" "Remote API-key record lookup" "External"
        upstream = softwareSystem "Upstream tool / LLM server" "Receives delegated, audience-scoped requests" "External"

        agent -> listener "Sends requests" "HTTP(S), Bearer JWT / API key"
        operator -> core "Supplies YAML policy document" "routes + plugins config"
        listener -> ppe "Invokes hooks per request" "In-process Rust API"
        ppe -> runtime "Delegates hook evaluation"
        ppe -> builtins "Re-exports feature-gated extensions"
        runtime -> cmf "Builds attribute bags"
        cmf -> aplcore "Evaluates APL"
        runtime -> orchestration "Runs concurrent branches"
        runtime -> core "Uses engine and hook types"
        builtins -> core "Implements PluginFactory"
        core -> transport "All outbound HTTP" "HttpTransport trait"
        listener -> upstream "Forwards with delegated token" "HTTP(S)"

        transport -> idp "JWKS fetch, token exchange, CIBA" "HTTPS/443"
        transport -> vault "Login, KV read, token renew" "HTTPS/8200"
        transport -> limitador "/check, /report" "HTTPS/configurable"
        transport -> apikeydir "API-key lookup" "HTTPS/configurable"
        builtins -> valkey "Session, CIBA, DPoP stores" "RESP over TLS/6379"
    }

    views {
        systemContext praxis "SystemContext" {
            include *
            autoLayout
        }

        container praxis "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
