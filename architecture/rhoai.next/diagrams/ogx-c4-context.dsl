workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Builds AI applications using OGX APIs"

        ogx = softwareSystem "OGX (Llama Stack)" "Unified API framework for AI application development with pluggable provider architecture" {
            server = container "OGX Server" "FastAPI/Uvicorn ASGI server exposing unified AI APIs on port 8321" "Python FastAPI"
            authMiddleware = container "Authentication Middleware" "OAuth2 JWT/JWKS, token introspection, or custom HTTP auth delegation" "Python ASGI Middleware"
            abacEngine = container "ABAC Engine" "Attribute-based access control with permit/forbid rules on roles/teams/projects/namespaces" "Python"
            routingTable = container "Routing Table" "Maps resource identifiers (models, shields, vector DBs) to provider implementations" "Python"
            inlineProviders = container "Inline Providers" "In-process provider implementations (meta-reference inference, SQLite-vec, Faiss, SQLite KV)" "Python"
            remoteProviders = container "Remote Providers" "Thin API client wrappers delegating to external services (vLLM, TGI, OpenAI, etc.)" "Python"
            quotaMiddleware = container "Quota Middleware" "Per-client rate limiting with separate authenticated/anonymous thresholds" "Python ASGI Middleware"
            cli = container "llama CLI" "Command-line interface for building, configuring, and running stack distributions" "Python console_script"
            streamlitUI = container "Streamlit UI" "Optional web interface for interacting with the OGX server" "Python Streamlit" "Optional"
        }

        ogxDistribution = softwareSystem "ogx-distribution" "Containerized OGX distribution for Kubernetes deployment (Konflux-built images)" "Companion"
        ogxK8sOperator = softwareSystem "ogx-k8s-operator" "Kubernetes operator managing OGX deployments via CRDs" "Companion"

        vllm = softwareSystem "vLLM" "High-performance LLM inference engine" "External"
        tgi = softwareSystem "TGI" "Text Generation Inference server" "External"
        openai = softwareSystem "OpenAI API" "OpenAI inference service" "External"
        cloudProviders = softwareSystem "Cloud AI Providers" "Fireworks, Together, Cerebras, SambaNova, NVIDIA, WatsonX" "External"
        tavily = softwareSystem "Tavily" "Web search API for tool runtime" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        vectorStores = softwareSystem "Remote Vector Stores" "Chroma, Milvus, PgVector, Qdrant, Weaviate" "External"
        kvStores = softwareSystem "Remote KV Stores" "PostgreSQL, Redis, MongoDB for persistence" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol servers for tool integration" "External"
        jwksProvider = softwareSystem "JWKS / OAuth2 Provider" "JWT key and token validation service" "External"

        datascientist -> ogx "Creates AI applications via REST APIs" "HTTPS/8321"
        ogx -> vllm "Delegates LLM inference" "HTTPS"
        ogx -> tgi "Delegates LLM inference" "HTTPS"
        ogx -> openai "Delegates LLM inference" "HTTPS"
        ogx -> cloudProviders "Delegates LLM inference" "HTTPS"
        ogx -> tavily "Web search tool calls" "HTTPS/443"
        ogx -> huggingface "Downloads models and datasets" "HTTPS/443"
        ogx -> vectorStores "Stores and queries vectors" "Various/TLS"
        ogx -> kvStores "Persists metadata and state" "Various/TLS"
        ogx -> mcpServers "Tool integration via MCP protocol" "HTTP/SSE"
        ogx -> jwksProvider "Validates auth tokens" "HTTPS/443"
        ogxDistribution -> ogx "Packages as container image"
        ogxK8sOperator -> ogx "Manages Kubernetes deployment"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Companion" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #cccccc
                color #333333
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
        }
    }
}
