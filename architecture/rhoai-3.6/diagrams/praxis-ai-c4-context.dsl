workspace {
    model {
        aiClient = person "AI Client" "Application using OpenAI SDK, Anthropic SDK, MCP agent, or A2A task runner"

        praxisAI = softwareSystem "Praxis AI" "AI gateway proxy that classifies, routes, translates, and applies policy to provider-native AI traffic through a configurable filter pipeline" {
            server = container "praxis-ai-proxy" "AI gateway entry point; assembles filter registry, provisions stores, delegates to Praxis Pingora runtime" "Rust Binary" "Primary"
            apis = container "praxis-ai-apis" "Provider-specific API types (OpenAI, Anthropic, Azure, Bedrock, Vertex), request classification, token counting, SSE parsing" "Rust Library"
            filters = container "praxis-ai-filters" "Cross-cutting AI filter implementations: routing, guardrails, MCP, A2A, metering, token usage, prompt enrichment (~40 filters)" "Rust Library"
            store = container "praxis-ai-store" "ResponseStore trait and in-memory registry for response persistence contracts" "Rust Library"
            storeBackends = container "praxis-ai-store-backends" "Concrete store backends (PostgreSQL with password or cert-auth, SQLite) via SQLx" "Rust Library"
            storeLifecycle = container "praxis-ai-store-lifecycle" "Store generation lifecycle management for hot-reloaded store backends" "Rust Library"
            extProc = container "praxis-ai-llmd-ext-proc" "llm-d Envoy ext_proc compatibility layer via gRPC (tonic)" "Rust Library" "Optional"
        }

        praxisCore = softwareSystem "Praxis Core" "Proxy runtime, filter framework, TLS, load balancing, config, protocol handling (praxis-proxy 0.7.3)" "Internal"
        pingora = softwareSystem "Pingora" "HTTP proxy engine, connection pooling, H2 backpressure (Cloudflare fork 0.10.0)" "External"

        vllm = softwareSystem "vLLM / Inference Backends" "Local inference servers running AI models" "External"
        cloudProviders = softwareSystem "Cloud AI Providers" "AWS Bedrock, Azure AI, GCP Vertex AI — cloud-hosted inference" "External"
        postgresql = softwareSystem "PostgreSQL" "Response and conversation state persistence (5432/TCP, TLS/mTLS)" "External"
        valkey = softwareSystem "Valkey / Redis" "Token rate limit state storage (6379/TCP)" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content safety guardrail checks (pre/post inference)" "External"
        mcpServers = softwareSystem "MCP Servers" "Tool discovery and dispatch for agentic Responses via Streamable HTTP" "External"
        llmdExtProc = softwareSystem "llm-d ext_proc Server" "Envoy-compatible external processing for llm-d inference platform" "External"
        webSearch = softwareSystem "Web Search Providers" "OpenAI/Anthropic web search tool execution (HTTPS/443)" "External"

        aiClient -> praxisAI "Sends AI requests via OpenAI/Anthropic/MCP/A2A APIs" "HTTPS/8080"
        praxisAI -> praxisCore "Uses for proxy runtime, TLS, load balancing" "In-process library"
        praxisCore -> pingora "Uses for HTTP proxy engine" "In-process library"
        praxisAI -> vllm "Routes inference requests" "HTTP/HTTPS, Bearer Token"
        praxisAI -> cloudProviders "Routes inference requests" "HTTPS/443, SigV4/Azure AD/GCP ADC"
        praxisAI -> postgresql "Persists response state" "TCP/5432, TLS/mTLS"
        praxisAI -> valkey "Stores rate limit counters" "TCP/6379"
        praxisAI -> nemoGuardrails "Checks content safety" "HTTP/HTTPS"
        praxisAI -> mcpServers "Dispatches MCP tools" "Streamable HTTP"
        praxisAI -> llmdExtProc "Sends ext_proc callouts" "gRPC"
        praxisAI -> webSearch "Executes web search tools" "HTTPS/443"

        server -> apis "Uses for request classification and types"
        server -> filters "Assembles filter registry"
        server -> store "Provisions store registry"
        server -> storeBackends "Creates store backends"
        server -> storeLifecycle "Manages store generations"
        server -> extProc "Optional ext_proc filter"
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
            element "Internal" {
                background #6c5ce7
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #fdcb6e
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
