workspace {
    model {
        user = person "Data Scientist / Application Developer" "Sends prompts to LLM-based applications with safety guardrails"
        platformAdmin = person "Platform Admin" "Configures guardrail policies and Colang flows via ConfigMaps"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit for adding safety, security, and content moderation to LLM-based conversational systems" {
            server = container "NeMo Guardrails Server" "OpenAI-compatible REST API server for guardrail-protected LLM interactions" "Python/FastAPI/Uvicorn, Port 8000"
            llmRailsEngine = container "LLMRails Engine" "Core engine managing Colang runtimes, LLM calls, and rail execution pipelines" "Python Module"
            ioRailsEngine = container "IORails Engine" "Optimized inference path for input/output-only content safety rails" "Python Module"
            guardrailsWrapper = container "Guardrails Wrapper" "Top-level interface auto-selecting IORails or LLMRails based on configuration" "Python Module"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0/v2.x) for conversational flow control" "Python Module"
            guardrailLibrary = container "Guardrail Library" "28 guardrail type implementations (content safety, jailbreak, PII, hallucination, etc.)" "Python Modules"
            knowledgeBase = container "Knowledge Base" "Embedding-based document search using Annoy ANN index" "Python Module"
            actionsServer = container "Actions Server" "Optional standalone server for executing guardrail actions remotely" "Python/FastAPI, Port 8001"
        }

        openai = softwareSystem "OpenAI API" "LLM inference and embeddings" "External"
        nim = softwareSystem "NVIDIA NIM" "LLM inference via NVIDIA endpoints" "External"
        anthropic = softwareSystem "Anthropic API" "LLM inference for chat completions" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "LLM inference (Azure-hosted models)" "External"
        cohere = softwareSystem "Cohere API" "LLM inference and embeddings" "External"
        vertexAi = softwareSystem "Google Vertex AI" "Embeddings and content moderation" "External"
        redis = softwareSystem "Redis" "Thread/conversation state persistence" "External Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Trace export for distributed observability" "External Infrastructure"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / OpenShift Route with TLS termination and auth" "Internal RHOAI"

        # User interactions
        user -> platformIngress "Sends LLM requests with Bearer token" "HTTPS/443"
        platformIngress -> nemoGuardrails "Forwards requests with auth header" "HTTP/8000"
        platformAdmin -> nemoGuardrails "Configures guardrail policies via ConfigMaps" "Kubernetes API"

        # Internal container relationships
        server -> guardrailsWrapper "Routes requests to appropriate engine"
        guardrailsWrapper -> llmRailsEngine "Complex flows with dialog management"
        guardrailsWrapper -> ioRailsEngine "Simple I/O-only content safety checks"
        llmRailsEngine -> colangRuntime "Executes Colang flow definitions"
        llmRailsEngine -> guardrailLibrary "Applies configured guardrail checks"
        llmRailsEngine -> knowledgeBase "Retrieves relevant documents for context"

        # External dependencies
        nemoGuardrails -> openai "LLM inference, embeddings, guardrail evaluation" "HTTPS/443, Bearer Token"
        nemoGuardrails -> nim "LLM inference, jailbreak detection" "HTTPS/443, Bearer Token"
        nemoGuardrails -> anthropic "LLM inference" "HTTPS/443, x-api-key"
        nemoGuardrails -> azureOpenai "LLM inference" "HTTPS/443, api-key header"
        nemoGuardrails -> cohere "LLM inference and embeddings" "HTTPS/443, Bearer Token"
        nemoGuardrails -> vertexAi "Embeddings and content moderation" "HTTPS/443, GCP credentials"
        nemoGuardrails -> redis "Thread/session persistence" "TCP/6379, username/password"
        nemoGuardrails -> otelCollector "Trace export" "gRPC/4317 OTLP"
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
            element "External Infrastructure" {
                background #6c8ebf
                color #ffffff
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
        }
    }
}
