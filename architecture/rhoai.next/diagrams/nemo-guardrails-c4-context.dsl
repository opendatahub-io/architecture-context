workspace {
    model {
        user = person "API Consumer" "Application or user sending LLM conversations through guardrail evaluation"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails server that intercepts LLM conversations to enforce safety, topicality, and content policies via configurable rail pipelines" {
            apiServer = container "Guardrails Server" "OpenAI-compatible HTTP API server with guardrail evaluation pipeline" "Python (FastAPI/Uvicorn)" "Service"
            colangV1 = container "Colang v1.0 Runtime" "State-machine-based conversational flow engine for guardrail evaluation" "Python Library"
            colangV2 = container "Colang v2.x Runtime" "Event-driven conversational flow engine with concurrent flow support" "Python Library"
            railActions = container "Rail Action Library" "Pluggable guardrail implementations: content safety, jailbreak detection, topic safety, hallucination, sensitive data, regex" "Python Library"
            llmClient = container "LLM Client Layer" "Multi-provider LLM client with OpenAI-compatible HTTP, LangChain adapter, and TRT-LLM gRPC client" "Python Library"
            embeddingLayer = container "Embedding Provider Layer" "Multi-provider embedding system: FastEmbed (ONNX), SentenceTransformers, OpenAI, Cohere, NIM, Google, Azure" "Python Library"
            knowledgeBase = container "Knowledge Base" "Semantic search over user-provided documents using embedding vectors" "Python Library"
            headerForwarding = container "Header Forwarding" "Remaps X-Authorization to Authorization for upstream LLM calls; enables multi-tenant API key injection" "Python Module"
        }

        openai = softwareSystem "OpenAI API" "LLM inference and embedding requests" "External LLM Provider"
        nim = softwareSystem "NVIDIA NIM" "NVIDIA-hosted or self-hosted LLM inference" "External LLM Provider"
        azureOpenai = softwareSystem "Azure OpenAI" "Microsoft-hosted LLM inference and embeddings" "External LLM Provider"
        anthropic = softwareSystem "Anthropic API" "LLM inference" "External LLM Provider"
        cohere = softwareSystem "Cohere API" "LLM inference and embedding requests" "External LLM Provider"
        googleGemini = softwareSystem "Google Gemini API" "Embedding requests" "External Embedding Provider"
        triton = softwareSystem "Triton Inference Server" "TensorRT-LLM inference via gRPC protocol" "Internal Infrastructure"
        redis = softwareSystem "Redis" "Thread/conversation message persistence (optional)" "Optional Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "Optional Infrastructure"
        externalIngress = softwareSystem "External Ingress" "kube-rbac-proxy / Istio / NetworkPolicy — TLS termination and auth enforcement" "Platform Infrastructure"

        // System context relationships
        user -> externalIngress "Sends LLM conversations" "HTTPS/443 TLS 1.2+"
        externalIngress -> nemoGuardrails "Forwards requests (TLS terminated)" "HTTP/8000 Plaintext"

        nemoGuardrails -> openai "LLM inference and embeddings" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> nim "LLM inference" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> azureOpenai "LLM inference and embeddings" "HTTPS/443 TLS 1.2+ API Key"
        nemoGuardrails -> anthropic "LLM inference" "HTTPS/443 TLS 1.2+ API Key"
        nemoGuardrails -> cohere "LLM inference and embeddings" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> googleGemini "Embedding requests" "HTTPS/443 TLS 1.2+ API Key"
        nemoGuardrails -> triton "TRT-LLM inference" "gRPC Configurable"
        nemoGuardrails -> redis "Message persistence" "Redis/6379 Plaintext"
        nemoGuardrails -> otelCollector "Distributed tracing" "gRPC/4317 OTLP"

        // Container relationships
        apiServer -> colangV1 "Evaluates rails via" "In-process"
        apiServer -> colangV2 "Evaluates rails via" "In-process"
        apiServer -> railActions "Executes guardrail actions" "In-process"
        apiServer -> headerForwarding "Remaps auth headers" "In-process"
        railActions -> llmClient "Calls LLM for rail evaluation" "In-process"
        railActions -> embeddingLayer "Encodes text for similarity" "In-process"
        embeddingLayer -> knowledgeBase "Searches documents" "In-process"
        llmClient -> headerForwarding "Gets forwarded auth headers" "In-process"
    }

    views {
        systemContext nemoGuardrails "SystemContext" {
            include *
            autoLayout
        }

        container nemoGuardrails "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External LLM Provider" {
                background #999999
                color #ffffff
                shape RoundedBox
            }
            element "External Embedding Provider" {
                background #999999
                color #ffffff
                shape RoundedBox
            }
            element "Optional Infrastructure" {
                background #cccccc
                color #333333
                shape RoundedBox
            }
            element "Platform Infrastructure" {
                background #d79b00
                color #ffffff
                shape RoundedBox
            }
            element "Internal Infrastructure" {
                background #666666
                color #ffffff
                shape RoundedBox
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
