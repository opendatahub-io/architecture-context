workspace "ogx-distribution" "RHOAI OGX (formerly Llama Stack) server distribution image - rhoai-3.7-ea.1" {
    model {
        user = person "AI Developer / Application" "Calls OpenAI- and Anthropic-compatible APIs from notebooks, apps and agents"

        ogx = softwareSystem "OGX Distribution (odh-ogx-core-rhel9)" "Pre-configured OGX API server image with env-gated providers for inference, vector storage, files, responses, messages, batches and tools" {
            entrypoint = container "entrypoint.sh" "Resolves *_FILE secrets, selects config, optionally wraps with opentelemetry-instrument" "POSIX sh"
            server = container "OGX Server" "OpenAI/Anthropic-compatible API server on 8321/TCP (plain HTTP, --insecure); optional OAuth2 JWT + owner ABAC" "Python, FastAPI/uvicorn, ogx 1.4.1+rhaiv.0"
            config = container "config.yaml (rh)" "Generated runtime config: APIs, env-gated providers, PostgreSQL storage, auth policy" "YAML"
            buildTooling = container "Build tooling" "build.yaml -> config.yaml, Containerfile, Dockerfile.konflux, lock files, docs" "Python"
            serviceMonitor = container "ServiceMonitor" "Scrapes /metrics every 60s from ogx-operator-managed pods" "Prometheus Operator CR"
        }

        operator = softwareSystem "OGX Operator" "Deploys the image; reads OCI config labels" "Internal RHOAI"
        kserve = softwareSystem "KServe / vLLM (RHAIIS)" "Primary inference and embedding backend" "Internal RHOAI"
        maas = softwareSystem "Models-as-a-Service" "vLLM-compatible governed endpoint" "Internal RHOAI"
        prometheus = softwareSystem "Platform Prometheus" "Metrics scraping" "Internal RHOAI"
        praxis = softwareSystem "Praxis Proxy" "Tenant/user header propagation (test evidence)" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "Hermetic multi-arch image build" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC" "cpu-torch2.13-el9.8 base image and RHEL AI PyPI" "Internal RHOAI"

        postgres = softwareSystem "PostgreSQL" "KV and SQL storage for all state" "External"
        llmApis = softwareSystem "Public LLM APIs" "OpenAI, Anthropic, Azure OpenAI, AWS Bedrock, Vertex AI, Gemini, watsonx" "External"
        vectorDbs = softwareSystem "Vector Stores" "Milvus, pgvector, Qdrant" "External"
        s3 = softwareSystem "S3 Storage" "Optional file storage" "External"
        search = softwareSystem "Brave / Tavily" "Web search tool runtime" "External"
        mcp = softwareSystem "MCP Servers" "Remote tools" "External"
        oidc = softwareSystem "OIDC Issuer / JWKS" "JWT signing keys" "External"
        otel = softwareSystem "OTLP Collector" "Traces and metrics" "External"

        user -> server "Chat, responses, messages, files, vector stores, batches" "HTTP/8321, optional Bearer JWT"
        praxis -> server "Proxies with x-tenant-id / x-user-id" "HTTP/8321"
        entrypoint -> server "exec ogx run --insecure"
        server -> config "Loads"
        buildTooling -> config "Generates"
        prometheus -> serviceMonitor "Uses"
        serviceMonitor -> server "Scrapes /metrics" "HTTP"

        operator -> ogx "Deploys image, reads OCI labels"
        konflux -> ogx "Builds and pushes quay.io/rhoai/odh-ogx-core-rhel9" "HTTPS/443"
        ogx -> aipcc "Base image and hermetic Python packages"

        server -> postgres "KV + SQL state" "PostgreSQL/5432, password"
        server -> kserve "Inference and embeddings" "HTTP/HTTPS 8000 or 443, Bearer"
        server -> maas "Inference" "HTTPS"
        server -> llmApis "Inference" "HTTPS/443, API key / IAM"
        server -> vectorDbs "Vector storage and search" "gRPC/HTTP/PG 19530/5432/6333-6334"
        server -> s3 "File blobs" "HTTPS/443, AWS keys"
        server -> search "Web search" "HTTPS/443, API key"
        server -> mcp "Tool calls" "HTTP/SSE"
        server -> oidc "Fetch JWKS" "HTTPS/443"
        server -> otel "Export telemetry" "OTLP 4317/4318"
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6aa9ee
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
