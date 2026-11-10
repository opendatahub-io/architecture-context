workspace "praxis-ai" "AI gateway built on the Praxis proxy (RHOAI 3.7-ea.1)" {
    model {
        client = person "AI Client / Agent" "Sends OpenAI, Anthropic, MCP or A2A traffic"
        authn = softwareSystem "Trusted Authenticator" "Gateway / kube-rbac-proxy asserting x-auth-tenant and x-auth-user" "Consumer"
        deployer = softwareSystem "Consuming Platform" "Operator, Helm chart or llm-d supplying Deployment, Service and config" "Consumer"

        praxisAi = softwareSystem "praxis-ai" "Classifies, translates, routes and applies policy to AI traffic" {
            proxy = container "praxis-ai-proxy" "Server binary: CLI, filter registration, store provisioning, readiness, hot reload, FIPS checks" "Rust / Praxis 0.8.0 / Pingora" {
                tags "Core"
            }
            filters = container "praxis-ai-filters" "Routing, guardrails, metering, token usage, rate limit, identity guard, OTel, cloud auth" "Rust library"
            apis = container "praxis-ai-apis" "Protocol translators, Responses/Conversations/agentic loop, MCP client, state owner" "Rust library"
            extProc = container "praxis-ai-llmd-ext-proc" "Envoy ext_proc gRPC client for llm-d EPP (optional)" "Rust library / tonic"
            store = container "praxis-ai-store(+backends, lifecycle)" "Response and conversation store, PostgreSQL/SQLite via SQLx fork, expiry" "Rust library"
            admin = container "Admin API" "/healthy, /ready, /metrics on 9901/TCP (no auth)" "Praxis admin"
        }

        kserve = softwareSystem "KServe LLMInferenceService" "Model inference; publisher-style model IDs rewritten" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "Native Chat Completions / Responses / Messages backend" "Internal RHOAI"
        llmd = softwareSystem "llm-d EPP" "Endpoint Picker / inference scheduler" "Internal RHOAI"
        ogx = softwareSystem "OGX" "Responses/agents backend (formerly llama-stack)" "Internal RHOAI"
        guardrails = softwareSystem "Guardrails" "NeMo Guardrails / TrustyAI / Lakera" "Internal RHOAI"
        postgres = softwareSystem "PostgreSQL / SQLite" "Response and conversation state" "External"
        valkey = softwareSystem "Valkey / Redis Sentinel" "Distributed token rate-limit buckets" "External"
        cloud = softwareSystem "Cloud AI Providers" "AWS Bedrock, Azure OpenAI, Google Vertex AI, OpenAI, Anthropic" "External"
        mcp = softwareSystem "MCP Servers / A2A Agents" "Tool and agent backends" "External"
        observability = softwareSystem "Prometheus / OTel Collector" "Metrics and traces" "External"

        client -> authn "Sends requests" "HTTPS"
        client -> praxisAi "Sends AI requests (if exposed directly)" "HTTP/HTTPS 8080"
        authn -> praxisAi "Forwards with trusted identity headers" "HTTP/HTTPS 8080, TLS/mTLS"
        deployer -> praxisAi "Deploys and configures"

        authn -> proxy "Forwards requests" "HTTP/HTTPS 8080"
        proxy -> filters "Runs filter chain"
        filters -> apis "Translation and stateful APIs"
        filters -> extProc "Endpoint selection"
        apis -> store "Persists and rehydrates state"

        praxisAi -> kserve "Routes inference" "HTTP/HTTPS"
        praxisAi -> vllm "Routes inference" "HTTP/HTTPS"
        praxisAi -> llmd "Picks endpoints" "gRPC ext_proc"
        praxisAi -> ogx "Projects tenant/user identity" "HTTP/HTTPS"
        praxisAi -> guardrails "Request/response checks" "HTTPS 443"
        praxisAi -> postgres "Stores responses/conversations" "PostgreSQL 5432 TLS"
        praxisAi -> valkey "Rate-limit buckets" "RESP TLS"
        praxisAi -> cloud "Translated inference" "HTTPS 443, SigV4 / Entra ID / GCP ADC / API key"
        praxisAi -> mcp "Tool calls and task routing" "HTTPS"
        observability -> praxisAi "Scrapes metrics" "HTTP 9901"

        filters -> kserve "Routes inference" "HTTP/HTTPS"
        filters -> guardrails "Callouts" "HTTPS 443"
        filters -> valkey "Rate-limit buckets" "RESP TLS"
        filters -> cloud "Signed requests" "HTTPS 443"
        extProc -> llmd "ext_proc stream" "gRPC"
        apis -> mcp "MCP client" "HTTPS"
        store -> postgres "SQL" "PostgreSQL 5432 TLS"
        observability -> admin "Scrapes" "HTTP 9901"
    }

    views {
        systemContext praxisAi "SystemContext" {
            include *
            autoLayout
        }

        container praxisAi "Containers" {
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
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Consumer" {
                background #f5a623
            }
        }
    }
}
