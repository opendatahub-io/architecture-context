workspace {
    model {
        user = person "Application Developer" "Deploys LLM-powered applications with safety guardrails"
        securityEngineer = person "Security Engineer" "Configures guardrail policies and monitors compliance"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails server that enforces safety, security, and topic-adherence policies on LLM conversations" {
            apiServer = container "FastAPI Server" "OpenAI-compatible REST API with guardrail interception on port 8000/TCP" "Python FastAPI + uvicorn"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0 and v2.x) for defining guardrail flows and dialog policies" "Python Library"
            guardrailLibrary = container "Guardrail Library" "Collection of safety rail implementations: content safety, jailbreak detection, injection detection, PII, hallucination, fact-checking, topic safety" "Python Modules"
            knowledgeBase = container "Knowledge Base" "Document chunking and semantic search via Annoy nearest-neighbor index for RAG-based guardrails" "Python Module + Annoy"
            embeddingProviders = container "Embedding Providers" "Pluggable embedding backends: FastEmbed (default), OpenAI, SentenceTransformers, NIM" "Python Modules"
            tracingSystem = container "Tracing System" "OpenTelemetry and filesystem-based tracing for guardrail execution observability" "Python Module"
        }

        upstreamLLM = softwareSystem "Upstream LLM" "Backend LLM for chat completions (vLLM, TGI, NIM, or OpenAI-compatible)" "External"
        openaiAPI = softwareSystem "OpenAI API" "OpenAI model listing, embeddings, and chat completions" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Azure-hosted OpenAI model completions" "External"
        nvidaNIM = softwareSystem "NVIDIA NIM" "NIM-based jailbreak detection and embeddings" "External"
        ciscoAIDefense = softwareSystem "Cisco AI Defense" "Prompt/response protection via external guardrail service" "External"
        alignScore = softwareSystem "AlignScore Server" "Fact-checking via information alignment scoring" "External"
        redis = softwareSystem "Redis" "Thread message persistence and distributed embedding cache" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives OTLP trace data for distributed observability" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model weights and tokenizer downloads" "External"

        # User interactions
        user -> nemoGuardrails "Sends chat completion requests with safety guardrails" "HTTP/8000"
        securityEngineer -> nemoGuardrails "Configures guardrail policies via Colang files"

        # Internal container interactions
        apiServer -> colangRuntime "Routes requests through guardrail pipeline"
        colangRuntime -> guardrailLibrary "Executes configured safety rails"
        colangRuntime -> knowledgeBase "Performs semantic search for RAG guardrails"
        knowledgeBase -> embeddingProviders "Generates embeddings for document chunks"
        apiServer -> tracingSystem "Sends execution traces"

        # External interactions
        nemoGuardrails -> upstreamLLM "Forwards approved chat completion requests" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> openaiAPI "Model listing, embeddings, completions" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> azureOpenAI "Azure model completions" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> nvidaNIM "Jailbreak detection and embeddings" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> ciscoAIDefense "Prompt/response protection" "HTTPS/443 TLS 1.2+ API Key"
        nemoGuardrails -> alignScore "Fact-checking requests" "HTTP/HTTPS configurable"
        nemoGuardrails -> redis "Thread storage and embedding cache" "Redis/6379"
        nemoGuardrails -> otelCollector "Trace export" "OTLP/4317 gRPC"
        nemoGuardrails -> huggingFaceHub "Model and tokenizer downloads" "HTTPS/443 TLS 1.2+"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
