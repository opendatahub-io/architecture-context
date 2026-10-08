workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Sends inference requests via OpenAI, Anthropic, or MCP SDKs"
        platformeng = person "Platform Engineer" "Configures gateway routes, filter chains, and credentials"

        praxisai = softwareSystem "Praxis AI" "AI-native gateway proxy providing provider-aware routing, protocol translation, stateful APIs, and agent traffic management" {
            server = container "praxis-ai-proxy" "Assembles filter registry, initializes TLS, runs Pingora-based proxy" "Rust Binary"
            apis = container "praxis-ai-apis" "Provider-specific types, request classification, SSE parsing, protocol translation" "Rust Library"
            filters = container "praxis-ai-filters" "Cross-cutting AI filters: agentic protocols, guardrails, routing, metering" "Rust Library"
            store = container "Response Store" "PostgreSQL/SQLite persistence for stateful OpenAI Responses and Conversations" "Rust Library + SQL"
            extproc = container "llmd-ext-proc" "gRPC ext_proc compatibility layer for Envoy/llm-d interop" "Rust Library (gRPC)"
        }

        praxiscore = softwareSystem "Praxis Core" "Proxy runtime: listeners, TLS, load balancing, filter framework, admin API" "External"
        vllm = softwareSystem "vLLM / Inference Backends" "Model-serving endpoints (Chat Completions API)" "External"
        nemo = softwareSystem "NeMo Guardrails" "AI content safety checks (pre-request and post-response)" "External"
        mcpservers = softwareSystem "MCP Servers" "Tool discovery and execution for agentic workflows" "External"
        a2aagents = softwareSystem "A2A Agents" "Agent-to-Agent task routing" "External"
        postgresql = softwareSystem "PostgreSQL" "Response and conversation state persistence" "External"
        redis = softwareSystem "Redis" "Token rate limiting state" "External"
        bedrock = softwareSystem "AWS Bedrock" "Bedrock Converse inference" "External Cloud"
        azureoai = softwareSystem "Azure OpenAI" "Azure AI inference" "External Cloud"
        vertexai = softwareSystem "Google Vertex AI" "Vertex AI Gemini inference" "External Cloud"
        metering = softwareSystem "External Metering" "Token usage and metering data reporting" "External"

        datascientist -> praxisai "Sends inference requests" "HTTPS/8080"
        platformeng -> praxisai "Configures via YAML and admin API" "HTTPS/9901"

        praxisai -> praxiscore "Uses proxy runtime and filter framework" "Rust crate"
        praxisai -> vllm "Forwards classified inference requests" "HTTP/HTTPS"
        praxisai -> nemo "Sends guardrail check requests" "HTTP/HTTPS"
        praxisai -> mcpservers "Discovers and calls tools" "HTTP/HTTPS"
        praxisai -> a2aagents "Routes agent-to-agent tasks" "HTTP/HTTPS"
        praxisai -> postgresql "Persists response/conversation state" "PostgreSQL/5432"
        praxisai -> redis "Stores rate limiting state" "Redis/6379"
        praxisai -> bedrock "Translates to Bedrock Converse" "HTTPS/443"
        praxisai -> azureoai "Translates to Azure AI" "HTTPS/443"
        praxisai -> vertexai "Translates to Vertex Gemini" "HTTPS/443"
        praxisai -> metering "Reports token usage" "HTTP/HTTPS"
    }

    views {
        systemContext praxisai "SystemContext" {
            include *
            autoLayout
        }

        container praxisai "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #f5a623
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
