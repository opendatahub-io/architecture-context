workspace {
    model {
        user = person "Data Scientist / Application" "Sends prompts to LLM-based applications with guardrail protection"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit for LLM safety, security, and content moderation" {
            server = container "NeMo Guardrails Server" "OpenAI-compatible REST API with guardrail-protected LLM interactions" "FastAPI/Uvicorn, Python, Port 8000"
            llmRails = container "LLMRails Engine" "Full Colang runtime with dialog management, knowledge base, and flow control" "Python Module"
            ioRails = container "IORails Engine" "Optimized inference path for input/output-only content safety rails" "Python Module (fork-specific)"
            guardrailsWrapper = container "Guardrails Wrapper" "Auto-selects IORails or LLMRails based on configuration" "Python Module"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime for conversational flow control (v1.0 and v2.x)" "Python Module"
            guardrailLibrary = container "Guardrail Library" "28 built-in guardrail types: content safety, jailbreak detection, PII, hallucination, topic safety, injection prevention" "Python Modules"
            knowledgeBase = container "Knowledge Base" "Embedding-based document search using Annoy approximate nearest neighbor index" "Python Module"
            actionsServer = container "Actions Server" "Optional standalone server for executing guardrail actions remotely" "FastAPI, Port 8001"
        }

        openai = softwareSystem "OpenAI API" "LLM inference and embeddings" "External LLM Provider"
        nim = softwareSystem "NVIDIA NIM" "LLM inference and jailbreak detection" "External LLM Provider"
        anthropic = softwareSystem "Anthropic API" "LLM inference for chat completions" "External LLM Provider"
        azure = softwareSystem "Azure OpenAI" "LLM inference (Azure-hosted)" "External LLM Provider"
        cohere = softwareSystem "Cohere API" "LLM inference and embeddings" "External LLM Provider"
        vertexAI = softwareSystem "Google Vertex AI" "Embeddings and content moderation" "External LLM Provider"
        redis = softwareSystem "Redis" "Thread/conversation state persistence" "Infrastructure (Optional)"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace export" "Infrastructure (Optional)"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Provisions ingress, auth enforcement, and deployment management" "Internal Platform"

        // System context relationships
        user -> nemoGuardrails "Sends chat completions and guardrail check requests" "HTTP/8000"
        nemoGuardrails -> openai "LLM inference, embeddings" "HTTPS/443, Bearer Token"
        nemoGuardrails -> nim "LLM inference, jailbreak detection" "HTTPS/443, Bearer Token"
        nemoGuardrails -> anthropic "LLM inference" "HTTPS/443, x-api-key"
        nemoGuardrails -> azure "LLM inference" "HTTPS/443, api-key header"
        nemoGuardrails -> cohere "LLM inference, embeddings" "HTTPS/443, Bearer Token"
        nemoGuardrails -> vertexAI "Embeddings, content moderation" "HTTPS/443, GCP credentials"
        nemoGuardrails -> redis "Thread persistence" "Redis/6379, Optional TLS"
        nemoGuardrails -> otel "Trace export" "gRPC OTLP/4317"
        rhoaiPlatform -> nemoGuardrails "Provisions ingress, manages deployment" "Kubernetes API"

        // Container relationships
        server -> guardrailsWrapper "Routes requests"
        guardrailsWrapper -> llmRails "Complex dialog flows"
        guardrailsWrapper -> ioRails "Simple I/O rails (optimized)"
        llmRails -> colangRuntime "Executes Colang flows"
        llmRails -> guardrailLibrary "Applies guardrail checks"
        llmRails -> knowledgeBase "Retrieves relevant documents"
        server -> actionsServer "Remote action execution" "HTTP/8001 (optional)"
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
            }
            element "Infrastructure (Optional)" {
                background #fff2cc
                color #333333
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
