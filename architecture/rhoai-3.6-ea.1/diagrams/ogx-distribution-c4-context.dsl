workspace {
    model {
        user = person "Data Scientist / Application Developer" "Sends inference requests, manages models and conversations"

        ogxDistribution = softwareSystem "OGX Distribution" "AI agent and inference gateway service — packages upstream OGX (formerly llama-stack) with configurable inference, vector storage, and tool runtime providers" {
            entrypoint = container "entrypoint.sh" "Resolves _FILE secret env vars from K8s-mounted files, launches ogx run" "Shell Script"
            ogxServer = container "OGX Server" "HTTP server exposing 8 API surfaces: responses, messages, batches, inference, tool_runtime, vector_io, files, file_processors" "Python / OGX Framework" {
                tags "Core"
            }
            authMiddleware = container "Auth Middleware" "OAuth2 token validation via JWKS, conditional on AUTH_ISSUER" "Python Middleware"
        }

        # Internal Platform Dependencies
        postgresql = softwareSystem "PostgreSQL" "Key-value and relational persistence for all OGX state" "Internal Platform" {
            tags "Required"
        }
        vllm = softwareSystem "vLLM" "Remote inference and embedding model serving" "Internal Platform" {
            tags "Conditional"
        }

        # External Inference Providers
        bedrock = softwareSystem "AWS Bedrock" "Remote inference via AWS SDK" "External Cloud" {
            tags "Conditional"
        }
        watsonx = softwareSystem "IBM WatsonX" "Remote inference" "External Cloud" {
            tags "Conditional"
        }
        azure = softwareSystem "Azure / OpenAI / Gemini / Anthropic / Vertex AI" "Additional inference providers" "External Cloud" {
            tags "Conditional"
        }

        # Vector Storage Providers
        milvus = softwareSystem "Milvus" "Remote vector store with mTLS support" "External / Internal" {
            tags "Conditional"
        }
        pgvector = softwareSystem "pgvector" "PostgreSQL-based vector store" "Internal" {
            tags "Conditional"
        }
        qdrant = softwareSystem "Qdrant" "Remote vector store (HTTP/gRPC)" "External / Internal" {
            tags "Conditional"
        }

        # Storage
        s3 = softwareSystem "S3 Storage" "Remote file storage" "External Cloud" {
            tags "Conditional"
        }

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics export" "Internal Platform" {
            tags "Optional"
        }

        # Relationships
        user -> ogxDistribution "Sends HTTP requests to" "HTTP/8321"
        ogxDistribution -> postgresql "Persists all state" "SQL/5432"
        ogxDistribution -> vllm "Proxies inference requests" "HTTP/HTTPS"
        ogxDistribution -> bedrock "Proxies inference requests" "HTTPS/443"
        ogxDistribution -> watsonx "Proxies inference requests" "HTTPS/443"
        ogxDistribution -> azure "Proxies inference requests" "HTTPS/443"
        ogxDistribution -> milvus "Vector operations" "HTTP/gRPC (mTLS configurable)"
        ogxDistribution -> pgvector "Vector operations" "SQL/5432"
        ogxDistribution -> qdrant "Vector operations" "HTTP/6333, gRPC/6334"
        ogxDistribution -> s3 "File storage" "HTTPS/443"
        ogxDistribution -> otelCollector "Exports telemetry" "OTLP"

        # Internal container relationships
        entrypoint -> ogxServer "Resolves secrets, launches"
        ogxServer -> authMiddleware "Validates tokens when AUTH_ISSUER set"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "External / Internal" {
                background #00bcd4
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Core" {
                background #4a90e2
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Conditional" {
                border dashed
            }
            element "Optional" {
                border dotted
            }
        }
    }
}
