workspace {
    model {
        user = person "Application Developer" "Sends inference requests and manages AI agent workflows"

        ogxDistribution = softwareSystem "ogx-distribution" "Container image packaging the OGX AI agent framework with pre-installed inference providers, vector stores, tool runtimes, and file processors" {
            ogxServer = container "OGX Server" "AI agent server exposing 8 HTTP APIs on port 8321" "OGX Framework"
            entrypoint = container "Entrypoint Script" "Resolves _FILE secret variants from K8s mounts, launches OGX server" "Bash"
        }

        # Inference Providers (External)
        vllm = softwareSystem "vLLM" "Self-hosted inference engine" "External"
        bedrock = softwareSystem "AWS Bedrock" "AWS managed inference service" "External Cloud"
        watsonx = softwareSystem "IBM WatsonX" "IBM managed AI platform" "External Cloud"
        azureOpenai = softwareSystem "Azure OpenAI" "Microsoft managed inference service" "External Cloud"
        vertexAi = softwareSystem "Google Vertex AI" "Google managed AI platform" "External Cloud"
        openai = softwareSystem "OpenAI" "OpenAI inference API" "External Cloud"
        anthropic = softwareSystem "Anthropic" "Anthropic inference API" "External Cloud"

        # Data Stores
        postgresql = softwareSystem "PostgreSQL" "State persistence for agent data, logs, metadata" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for file artifacts" "External"

        # Vector Stores
        milvus = softwareSystem "Milvus" "Vector database for similarity search" "External"
        qdrant = softwareSystem "Qdrant" "Vector search engine" "External"

        # Tool Services
        braveSearch = softwareSystem "Brave Search" "Web search API" "External Cloud"
        tavilySearch = softwareSystem "Tavily Search" "AI-optimized web search API" "External Cloud"
        mcpServer = softwareSystem "MCP Server" "Model Context Protocol server" "External"

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics collection" "External"

        # Platform
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Manages deployment lifecycle of ogx-distribution" "Internal RHOAI"

        # Relationships
        user -> ogxDistribution "Sends inference/agent requests" "HTTP/8321"
        ogxDistribution -> vllm "Forwards inference requests" "HTTP/HTTPS"
        ogxDistribution -> bedrock "Forwards inference requests" "HTTPS/443"
        ogxDistribution -> watsonx "Forwards inference requests" "HTTPS/443"
        ogxDistribution -> azureOpenai "Forwards inference requests" "HTTPS/443"
        ogxDistribution -> vertexAi "Forwards inference requests" "HTTPS/443"
        ogxDistribution -> openai "Forwards inference requests" "HTTPS/443"
        ogxDistribution -> anthropic "Forwards inference requests" "HTTPS/443"
        ogxDistribution -> postgresql "Stores agent state, logs, metadata" "PostgreSQL/5432"
        ogxDistribution -> s3Storage "Stores file artifacts" "HTTPS/443"
        ogxDistribution -> milvus "Vector similarity search" "gRPC/19530"
        ogxDistribution -> qdrant "Vector similarity search" "HTTP/6333"
        ogxDistribution -> braveSearch "Web search queries" "HTTPS/443"
        ogxDistribution -> tavilySearch "Web search queries" "HTTPS/443"
        ogxDistribution -> mcpServer "Tool execution via MCP" "MCP Protocol"
        ogxDistribution -> otelCollector "Exports traces and metrics" "OTLP"
        rhoaiOperator -> ogxDistribution "Deploys and manages lifecycle"
    }

    views {
        systemContext ogxDistribution "SystemContext" {
            include *
            autoLayout
        }

        container ogxDistribution "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
