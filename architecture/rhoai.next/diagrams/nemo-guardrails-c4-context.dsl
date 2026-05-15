workspace {
    model {
        user = person "LLM Application Developer" "Builds applications that use LLMs with safety guardrails"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety guardrails middleware for LLM-based conversational systems; OpenAI-compatible API" {
            server = container "Guardrails Server" "FastAPI server with OpenAI-compatible API, input/output rail enforcement, streaming support" "Python/FastAPI :8000"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0 and v2.x) for defining guardrail flows and dialogue policies" "Python/Lark"
            guardrailsLibrary = container "Guardrails Library" "28+ built-in guardrail implementations: content safety, jailbreak detection, sensitive data, hallucination, topic safety" "Python Modules"
            embeddingsEngine = container "Embeddings Engine" "Multi-provider embedding support: FastEmbed (ONNX), Sentence Transformers, OpenAI, Cohere, NIM" "Python/ONNX"
            knowledgeBase = container "Knowledge Base" "Document indexing and embedding-based retrieval for grounded responses" "Python/Annoy"
            actionsServer = container "Actions Server" "Extensible action dispatcher for custom guardrail logic" "Python/FastAPI :8001"
            tracingSystem = container "Tracing System" "OpenTelemetry-compatible tracing with GenAI semantic conventions" "Python/OpenTelemetry"
            embeddedModels = container "Embedded ML Models" "Pre-baked models: spaCy en_core_web_lg, Sentence Transformers, FastEmbed, NLTK punkt" "ONNX/PyTorch"
        }

        openai = softwareSystem "OpenAI API" "LLM inference provider" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "Microsoft-hosted LLM inference" "External"
        anthropic = softwareSystem "Anthropic API" "Anthropic LLM inference provider" "External"
        cohere = softwareSystem "Cohere API" "LLM inference and embeddings provider" "External"
        nvidiaNim = softwareSystem "NVIDIA NIM" "NVIDIA-hosted LLM inference via OpenAI-compatible API" "External"
        vllm = softwareSystem "vLLM Server" "Self-hosted LLM inference" "Internal"
        redis = softwareSystem "Redis" "Thread conversation state persistence" "Optional"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace aggregation and export" "Optional"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight downloads (build-time only)" "External"

        # System context relationships
        user -> nemoGuardrails "Sends chat completions and guardrail check requests via OpenAI-compatible API" "HTTP/8000"
        nemoGuardrails -> openai "Forwards inference requests" "HTTPS/443 Bearer Token"
        nemoGuardrails -> azureOpenai "Forwards inference requests" "HTTPS/443 API Key"
        nemoGuardrails -> anthropic "Forwards inference requests" "HTTPS/443 API Key"
        nemoGuardrails -> cohere "Forwards inference and embedding requests" "HTTPS/443 Bearer Token"
        nemoGuardrails -> nvidiaNim "Forwards inference requests" "HTTPS/443 Bearer Token"
        nemoGuardrails -> vllm "Forwards inference requests" "HTTP/HTTPS Bearer Token"
        nemoGuardrails -> redis "Persists thread conversation state" "Redis/6379"
        nemoGuardrails -> otelCollector "Exports distributed traces with GenAI semantic conventions" "OTLP/4317-4318"

        # Container relationships
        server -> colangRuntime "Evaluates Colang dialogue flows"
        server -> guardrailsLibrary "Applies input/output safety rails"
        server -> embeddingsEngine "Generates embeddings for content checks"
        server -> knowledgeBase "Retrieves grounded context"
        server -> actionsServer "Dispatches custom actions" "HTTP/8001"
        server -> tracingSystem "Records spans and traces"
        guardrailsLibrary -> embeddedModels "Runs inference for safety checks"
        embeddingsEngine -> embeddedModels "Runs local embedding inference"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #e1d5e7
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
