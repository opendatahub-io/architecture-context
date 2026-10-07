workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Sends inference requests via OpenAI or Anthropic SDKs"
        agentDev = person "Agent Developer" "Builds agentic applications with MCP tools and A2A protocols"

        praxisAI = softwareSystem "Praxis AI" "AI gateway proxy providing provider-aware routing, protocol translation, stateful APIs, and agentic traffic management" {
            proxy = container "praxis-ai-proxy" "Entry point binary: assembles filter pipeline, manages server lifecycle, config reload" "Rust Binary"
            apis = container "praxis-ai-apis" "Provider-specific API types, request classification, SSE parsing, protocol translation" "Rust Library"
            filters = container "praxis-ai-filters" "Cross-cutting AI filters: routing, guardrails, credential injection, metering, MCP, A2A" "Rust Library"
            store = container "praxis-ai-store" "ResponseStore and ConversationItemStore traits, tenant-scoped ownership model" "Rust Library"
            storeBackends = container "praxis-ai-store-backends" "PostgreSQL and SQLite backend implementations" "Rust Library"
            extProc = container "praxis-ai-llmd-ext-proc" "llm-d ext_proc gRPC compatibility layer (optional)" "Rust Library"
        }

        praxisCore = softwareSystem "Praxis Core" "Proxy runtime built on Pingora: listeners, TLS, load balancing, connection pooling, health checks" "External"
        vllm = softwareSystem "vLLM / Inference Backends" "LLM inference serving engines" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for stateful response and conversation storage" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "AI content safety screening service" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers for agentic tool dispatch" "External"
        a2aAgents = softwareSystem "A2A Agents" "Agent-to-agent task routing participants" "External"
        meteringService = softwareSystem "External Metering Service" "Token usage and request metering endpoint" "External"
        cloudProviders = softwareSystem "Cloud Identity Providers" "AWS STS, Azure AD, GCP for credential acquisition" "External"
        llmdExtProc = softwareSystem "llm-d ext_proc Server" "Envoy external processing server for llm-d integration" "External"

        dataScientist -> praxisAI "Sends inference requests via OpenAI/Anthropic SDK" "HTTPS/8080"
        agentDev -> praxisAI "Runs agentic tool loops via Responses API with MCP tools" "HTTPS/8080"

        praxisAI -> praxisCore "Uses as proxy runtime foundation" "In-process (Cargo dependency)"
        praxisAI -> vllm "Forwards inference requests (Chat Completions, Embeddings)" "HTTP/HTTPS"
        praxisAI -> postgresql "Persists responses, conversations, MCP approvals" "PostgreSQL/5432 TLS"
        praxisAI -> nemoGuardrails "Screens requests and responses for content safety" "HTTP/HTTPS"
        praxisAI -> mcpServers "Discovers and dispatches MCP tools" "HTTP Streamable"
        praxisAI -> a2aAgents "Routes agent-to-agent tasks" "HTTP/HTTPS"
        praxisAI -> meteringService "Reports token usage and request metrics" "HTTP/HTTPS"
        praxisAI -> cloudProviders "Acquires cloud credentials (SigV4, Azure AD, GCP ADC)" "HTTPS/443"
        praxisAI -> llmdExtProc "Sends ext_proc requests (optional)" "gRPC"

        proxy -> apis "Uses API types and classification"
        proxy -> filters "Registers and executes filter pipeline"
        proxy -> store "Provisions store backends"
        filters -> apis "Provider-specific protocol logic"
        store -> storeBackends "Delegates to database backends"
    }

    views {
        systemContext praxisAI "SystemContext" {
            include *
            autoLayout
        }

        container praxisAI "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
        }
    }
}
