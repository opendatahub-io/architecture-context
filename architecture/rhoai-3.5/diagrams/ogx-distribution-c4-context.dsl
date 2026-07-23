workspace {
    model {
        user = person "Data Scientist / Developer" "Creates inference requests, RAG workflows, and agentic tasks via OGX APIs"

        ogxDistribution = softwareSystem "OGX Distribution" "Multi-provider AI/ML inference, agent, and RAG server for RHOAI" {
            ogxServer = container "OGX Server" "Handles inference, RAG, agentic workflows, file processing, and batch requests" "Python 3.12 (ogx v1.2.1+rhaiv.0)" "Application"
            entrypoint = container "entrypoint.sh" "Secret resolution (_FILE variants), provider activation, server startup" "Shell Script" "Script"
            embeddedModels = container "Pre-fetched Models" "granite-embedding-125m-english, docling layout, RapidOCR, tiktoken" "ML Artifacts" "Data"
        }

        buildPipeline = softwareSystem "Build Pipeline" "Code generation: config.yaml, Containerfile, lock files, secret verification" "Supporting"

        # Platform components
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing OGX Deployment, Service, HTTPRoute, sidecar injection" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication enforcement sidecar injected by platform" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Platform-managed HTTPRoute with TLS termination" "Internal RHOAI"

        # Storage
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for key-value store, SQL store, file metadata, agent state" "External"

        # Inference providers
        vllm = softwareSystem "vLLM" "Remote LLM inference and embedding generation via OpenAI-compatible API" "External"
        bedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS SDK" "External"
        watsonx = softwareSystem "IBM WatsonX" "Remote LLM inference via WatsonX API" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure API" "External"
        vertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference via Vertex AI API" "External"
        openai = softwareSystem "OpenAI" "Remote LLM inference via OpenAI API" "External"
        gemini = softwareSystem "Google Gemini" "Remote LLM inference via Gemini API" "External"
        anthropic = softwareSystem "Anthropic" "Remote LLM inference via Anthropic API" "External"

        # Vector storage
        milvus = softwareSystem "Milvus" "Remote vector database for RAG workflows" "External"
        qdrant = softwareSystem "Qdrant" "Remote vector database for RAG workflows" "External"

        # Tools and services
        braveSearch = softwareSystem "Brave Search" "Web search tool for agentic workflows" "External"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool for agentic workflows" "External"
        s3 = softwareSystem "AWS S3" "Remote file storage for model artifacts and user files" "External"
        doclingServe = softwareSystem "Docling Serve" "Remote document processing service" "External"
        mcpServer = softwareSystem "MCP Server" "External tool provider via Model Context Protocol" "External"

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export" "External"
        jwksEndpoint = softwareSystem "OAuth2 JWKS Endpoint" "JWT key discovery for token validation" "External"

        # Base image
        aipccBase = softwareSystem "AIPCC CPU Base Image" "quay.io/aipcc/base-images/cpu:3.5.0 (RHEL 9.6 UBI)" "Supporting"

        # Relationships
        user -> gatewayAPI "Sends inference/RAG/agentic requests" "HTTPS/443 TLS 1.2+"
        gatewayAPI -> kubeRBACProxy "Forwards after TLS termination"
        kubeRBACProxy -> ogxDistribution "Forwards authenticated requests" "HTTP/8321"
        rhodsOperator -> ogxDistribution "Deploys and manages" "Kubernetes API"

        ogxDistribution -> postgresql "Stores persistent state" "PostgreSQL/5432 Password"
        ogxDistribution -> vllm "Inference and embedding requests" "HTTP(S) Bearer token"
        ogxDistribution -> bedrock "Inference requests" "HTTPS/443 AWS IAM"
        ogxDistribution -> watsonx "Inference requests" "HTTPS/443 API key"
        ogxDistribution -> azureOpenAI "Inference requests" "HTTPS/443 API key"
        ogxDistribution -> vertexAI "Inference requests" "HTTPS/443 GCP credentials"
        ogxDistribution -> openai "Inference requests" "HTTPS/443 API key"
        ogxDistribution -> gemini "Inference requests" "HTTPS/443 API key"
        ogxDistribution -> anthropic "Inference requests" "HTTPS/443 API key"
        ogxDistribution -> milvus "Vector storage for RAG" "HTTP(S) Token + mTLS"
        ogxDistribution -> qdrant "Vector storage for RAG" "HTTP+gRPC/6333-6334 API key"
        ogxDistribution -> braveSearch "Web search tool calls" "HTTPS/443 API key"
        ogxDistribution -> tavilySearch "Web search tool calls" "HTTPS/443 API key"
        ogxDistribution -> s3 "File storage" "HTTPS/443 AWS IAM"
        ogxDistribution -> doclingServe "Document processing" "HTTP(S) API key"
        ogxDistribution -> mcpServer "External tool execution" "HTTP(S)/SSE"
        ogxDistribution -> otelCollector "Traces and metrics" "OTLP HTTP/gRPC"
        ogxDistribution -> jwksEndpoint "JWT key discovery" "HTTPS/443"

        aipccBase -> ogxDistribution "Provides base image" "Container build"
        buildPipeline -> ogxDistribution "Generates config and container artifacts" "Build-time"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Supporting" {
                background #f5a623
                color #ffffff
            }
            element "Application" {
                background #4a90e2
                color #ffffff
            }
            element "Script" {
                background #6bb5e8
                color #ffffff
            }
            element "Data" {
                background #b8d4e8
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
