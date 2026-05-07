workspace {
    model {
        user = person "Data Scientist / Application" "Sends prompts to LLM-based systems with safety guardrails"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit for LLM safety, security, and content moderation" {
            server = container "Guardrails Server" "OpenAI-compatible REST API for guardrail-protected LLM interactions" "Python FastAPI/Uvicorn, Port 8000"
            guardrailsWrapper = container "Guardrails Wrapper" "Auto-selects IORails or LLMRails engine based on configuration" "Python Module"
            llmRailsEngine = container "LLMRails Engine" "Full Colang runtime with dialog management, KB retrieval, flow control" "Python Module"
            ioRailsEngine = container "IORails Engine" "Optimized inference path for input/output content safety checks" "Python Module (fork-specific)"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime for conversational flow control (v1.0, v2.x)" "Python Module"
            guardrailLibrary = container "Guardrail Library" "28 guardrail type implementations (content safety, jailbreak, PII, hallucination, etc.)" "Python Modules"
            knowledgeBase = container "Knowledge Base" "Embedding-based document search using Annoy approximate nearest neighbor index" "Python Module"
            actionsServer = container "Actions Server" "Optional standalone server for executing guardrail actions remotely" "Python FastAPI, Port 8001"
        }

        openai = softwareSystem "OpenAI API" "LLM inference and embeddings" "External"
        nvidianm = softwareSystem "NVIDIA NIM" "LLM inference and jailbreak detection" "External"
        anthropic = softwareSystem "Anthropic API" "LLM inference" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "LLM inference (Azure-hosted)" "External"
        cohere = softwareSystem "Cohere API" "LLM inference and embeddings" "External"
        vertexAI = softwareSystem "Google Vertex AI" "Embeddings and content moderation" "External"
        redis = softwareSystem "Redis" "Thread/conversation state persistence" "External Optional"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace export" "External Optional"
        platformIngress = softwareSystem "Platform Ingress" "TLS termination, authentication, and routing (Gateway API / kube-rbac-proxy)" "Internal RHOAI"

        user -> platformIngress "Sends requests via HTTPS/443"
        platformIngress -> nemoGuardrails "Forwards to HTTP/8000 with auth header passthrough"
        nemoGuardrails -> openai "LLM inference, embeddings" "HTTPS/443, Bearer Token"
        nemoGuardrails -> nvidianm "LLM inference, jailbreak detection" "HTTPS/443, Bearer Token"
        nemoGuardrails -> anthropic "LLM inference" "HTTPS/443, x-api-key"
        nemoGuardrails -> azureOpenAI "LLM inference" "HTTPS/443, api-key"
        nemoGuardrails -> cohere "LLM inference, embeddings" "HTTPS/443, Bearer Token"
        nemoGuardrails -> vertexAI "Embeddings, content moderation" "HTTPS/443, GCP credentials"
        nemoGuardrails -> redis "Thread persistence" "TCP/6379, Optional TLS"
        nemoGuardrails -> otelCollector "Trace export" "gRPC/4317 OTLP"

        server -> guardrailsWrapper "Routes requests"
        guardrailsWrapper -> llmRailsEngine "Full flow processing"
        guardrailsWrapper -> ioRailsEngine "I/O-only processing"
        llmRailsEngine -> colangRuntime "Executes Colang flows"
        llmRailsEngine -> guardrailLibrary "Applies guardrail checks"
        ioRailsEngine -> guardrailLibrary "Applies I/O rails"
        llmRailsEngine -> knowledgeBase "Retrieves relevant documents"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
