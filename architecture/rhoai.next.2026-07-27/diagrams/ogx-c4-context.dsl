workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys AI models, runs inference and agent workflows"
        developer = person "Application Developer" "Integrates Llama Stack APIs into applications"

        ogx = softwareSystem "ogx (Llama Stack)" "Multi-provider AI inference, agents, and tool runtime platform with pluggable authentication and ABAC-based access control" {
            server = container "FastAPI Server" "Hosts dynamic API routes for inference, agents, safety, vector I/O, dataset I/O, scoring, eval, tool runtime, inspect, and providers APIs" "Python/FastAPI/uvicorn" "Port 8321"
            authMiddleware = container "Authentication Middleware" "Configuration-conditional auth via OAuth2 JWT/JWKS, RFC 7662 introspection, or custom external HTTP delegation" "ASGI Middleware"
            inferenceRouter = container "Inference Router" "Routes inference requests to backend providers based on model identity" "Python"
            routingTable = container "Common Routing Table" "Manages provider registration and enforces ABAC on resource create, read, delete, list operations" "Python"
            agentPersistence = container "Agent Persistence" "Stores session and turn data in KV store with per-session ABAC ownership checks" "Python"
            quotaMiddleware = container "Quota Middleware" "Rate limiting with separate thresholds for authenticated and anonymous clients" "ASGI Middleware"
            streamlitUI = container "Streamlit UI" "Browser-based UI connecting to Llama Stack API via llama-stack-client SDK" "Streamlit"
        }

        openai = softwareSystem "OpenAI API" "LLM inference provider" "External"
        cerebras = softwareSystem "Cerebras API" "LLM inference provider (api.cerebras.ai)" "External"
        nvidia = softwareSystem "NVIDIA NeMo API" "Inference and dataset I/O provider" "External"
        tavily = softwareSystem "Tavily Search API" "Web search tool runtime (api.tavily.com)" "External"
        oauth2 = softwareSystem "OAuth2/OIDC Provider" "JWT validation via JWKS or RFC 7662 token introspection" "External"
        externalAuth = softwareSystem "External Auth Service" "Custom HTTP-based authentication delegation endpoint" "External"

        # User interactions
        datascientist -> ogx "Creates inference requests, manages agents, runs evaluations"
        developer -> ogx "Integrates via llama-stack-client SDK"
        datascientist -> streamlitUI "Uses browser-based UI for AI workflows"

        # Internal flows
        server -> authMiddleware "Delegates authentication"
        authMiddleware -> quotaMiddleware "Passes authenticated request"
        server -> inferenceRouter "Routes inference requests"
        inferenceRouter -> routingTable "Resolves provider by model identity"
        server -> agentPersistence "Manages agent sessions"
        streamlitUI -> server "Calls Llama Stack API via SDK"

        # External dependencies
        inferenceRouter -> openai "Sends inference requests" "HTTPS/TLS, OPENAI_API_KEY"
        inferenceRouter -> cerebras "Sends inference requests" "HTTPS/TLS, CEREBRAS_API_KEY"
        inferenceRouter -> nvidia "Sends inference and dataset requests" "HTTPS/TLS, NVIDIA_API_KEY"
        ogx -> tavily "Executes web searches" "HTTPS/443, TAVILY_SEARCH_API_KEY"
        authMiddleware -> oauth2 "Fetches JWKS keys or introspects tokens" "HTTPS"
        authMiddleware -> externalAuth "Delegates auth decision" "HTTP(S)"
    }

    views {
        systemContext ogx "SystemContext" {
            include *
            autoLayout
        }

        container ogx "Containers" {
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
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
