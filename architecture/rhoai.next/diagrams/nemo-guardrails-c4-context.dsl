workspace {
    model {
        user = person "Application Developer" "Deploys LLM-based applications with guardrails"
        platformOp = person "Platform Operator" "Configures and deploys NeMo Guardrails on RHOAI"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit that adds safety controls to LLM-based conversational systems" {
            server = container "NeMo Guardrails Server" "FastAPI/uvicorn service exposing OpenAI-compatible API with guardrails applied" "Python 3.12 / FastAPI"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime for defining guardrail flows (v1.0 and v2.x)" "Python Library"
            guardrailsLibrary = container "Guardrails Library" "~14 open-source guardrail modules: content safety, hallucination detection, PII detection, injection detection, topic safety, regex filtering" "Python Library"
            embeddingEngine = container "Embedding Engine" "FastEmbed and Sentence Transformers for semantic similarity, pre-downloaded at build time" "Python Library / ONNX Runtime"
            langchainIntegration = container "LangChain LLM Integration" "Abstracts LLM provider calls, manages prompts and callbacks" "LangChain >=0.2.14"
            tracingSystem = container "Tracing System" "OpenTelemetry-compatible tracing with pluggable adapters" "Python Library"
        }

        llmProvider = softwareSystem "LLM Provider" "External LLM inference service (OpenAI, NVIDIA NIM, Azure, Anthropic, Cohere, vLLM)" "External"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform managing deployment and ingress" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend for observability" "External"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model registry for embedding models (build-time only)" "External"

        # User interactions
        user -> nemoGuardrails "Sends chat messages with guardrails via API" "HTTP/8000"
        platformOp -> rhoaiPlatform "Deploys and configures guardrails service"

        # System interactions
        rhoaiPlatform -> nemoGuardrails "Deploys and manages lifecycle"
        nemoGuardrails -> llmProvider "LLM inference for guardrail evaluation and response generation" "HTTPS/443 Bearer Token"
        nemoGuardrails -> otelCollector "Exports traces and spans (optional)" "gRPC/HTTP TLS"
        nemoGuardrails -> huggingFaceHub "Downloads embedding models (build-time only)" "HTTPS/443"

        # Container interactions
        server -> colangRuntime "Evaluates input/output against Colang flows"
        colangRuntime -> guardrailsLibrary "Invokes guardrail modules"
        guardrailsLibrary -> embeddingEngine "Semantic similarity for knowledge base retrieval"
        server -> langchainIntegration "LLM calls via abstraction layer"
        langchainIntegration -> llmProvider "REST API calls" "HTTPS/443"
        server -> tracingSystem "Emits trace spans"
        tracingSystem -> otelCollector "Exports traces" "gRPC/HTTP"
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
