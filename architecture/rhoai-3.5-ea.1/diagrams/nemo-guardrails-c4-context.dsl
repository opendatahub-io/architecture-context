workspace {
    model {
        user = person "Data Scientist / Application Developer" "Sends chat completion and guardrail check requests"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails for LLM conversations - input/output safety, topic control, jailbreak detection, hallucination checks" {
            apiServer = container "FastAPI/Uvicorn Server" "OpenAI-compatible HTTP API server on port 8000" "Python / FastAPI"
            guardrailsEngine = container "Guardrails Engine" "Core rails execution pipeline - routes messages through input/output/dialog/retrieval/tool rails" "Python"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime for defining conversational guardrail flows (v1.0, v2.x)" "Python / Lark"
            embeddingsEngine = container "Embeddings Engine" "Pluggable embedding providers - SentenceTransformers, FastEmbed, ONNX Runtime" "Python"
            knowledgeBase = container "Knowledge Base" "RAG-based knowledge base with Annoy index for retrieval-augmented guardrail evaluation" "Python / Annoy"
            guardrailsLibrary = container "Guardrails Library" "Built-in guardrail implementations: content safety, SDD, hallucination, jailbreak, topic safety, regex" "Python"
            tracingModule = container "Tracing Module" "OpenTelemetry-based distributed tracing with span extractors" "Python / OpenTelemetry"
        }

        # External LLM Providers
        openaiAPI = softwareSystem "OpenAI API" "Cloud-hosted LLM inference" "External"
        nvidiaNIM = softwareSystem "NVIDIA NIM" "NVIDIA-hosted or self-hosted LLM inference" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Azure-hosted LLM inference" "External"
        anthropicAPI = softwareSystem "Anthropic API" "Anthropic model inference" "External"
        cohereAPI = softwareSystem "Cohere API" "Cohere model inference" "External"
        vllm = softwareSystem "vLLM / TRT-LLM" "Self-hosted model inference via OpenAI-compatible endpoint" "External"

        # Infrastructure
        redis = softwareSystem "Redis" "Thread/conversation state persistence" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"

        # Platform
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform - provides ingress, TLS, RBAC" "Internal Platform"

        # Relationships - User
        user -> nemoGuardrails "Sends chat completions and guardrail checks" "HTTPS/443 via platform ingress"

        # Relationships - Platform
        rhoaiPlatform -> nemoGuardrails "Routes traffic, provides TLS termination and AuthN" "HTTPRoute/Route → HTTP/8000"

        # Relationships - LLM Providers (egress)
        nemoGuardrails -> openaiAPI "LLM inference for chat completion and rail evaluation" "HTTPS/443, Bearer Token"
        nemoGuardrails -> nvidiaNIM "LLM inference via NIM" "HTTPS/443 or custom, API Key"
        nemoGuardrails -> azureOpenAI "LLM inference via Azure" "HTTPS/443, API Key"
        nemoGuardrails -> anthropicAPI "LLM inference via Anthropic" "HTTPS/443, x-api-key"
        nemoGuardrails -> cohereAPI "LLM inference via Cohere" "HTTPS/443, Bearer Token"
        nemoGuardrails -> vllm "Self-hosted LLM inference" "HTTP/HTTPS, Bearer Token"

        # Relationships - Infrastructure (egress)
        nemoGuardrails -> redis "Thread state persistence" "Redis/6379, optional TLS"
        nemoGuardrails -> otelCollector "Trace and span export" "HTTP/gRPC, configurable"

        # Internal container relationships
        apiServer -> guardrailsEngine "Routes requests to rails pipeline"
        guardrailsEngine -> colangRuntime "Executes Colang flows"
        guardrailsEngine -> embeddingsEngine "Computes semantic similarity"
        guardrailsEngine -> knowledgeBase "Retrieval-augmented evaluation"
        guardrailsEngine -> guardrailsLibrary "Applies configured rails"
        knowledgeBase -> embeddingsEngine "Generates embeddings for RAG"
        apiServer -> tracingModule "Instruments request spans"
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
            element "Internal Platform" {
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
