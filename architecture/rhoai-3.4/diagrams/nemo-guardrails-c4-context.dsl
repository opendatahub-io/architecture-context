workspace {
    model {
        user = person "Application Developer" "Builds LLM-powered applications with safety guardrails"
        securityEngineer = person "Security Engineer" "Configures guardrail policies and Colang flows"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit for adding safety, security, and topic controls to LLM-based conversational systems" {
            server = container "Guardrails Server" "OpenAI-compatible FastAPI server with guardrails enforcement" "Python / FastAPI / 8000/TCP"
            llmRailsEngine = container "LLMRails Engine" "Full-featured guardrails engine with LLM generation, dialog flows, and retrieval" "Python"
            ioRailsEngine = container "IORails Engine" "Optimized fast-path engine for pure content safety checks without LLM generation" "Python"
            colangRuntime = container "Colang Runtime" "Executes guardrail flows defined in Colang 1.0/2.x DSL" "Python / Lark Parser"
            guardrailsLibrary = container "Guardrails Library" "11 open-source guardrail modules (self-check, content safety, injection detection, PII, topic safety, regex, hallucination, fact-checking)" "Python"
            knowledgeBase = container "Knowledge Base" "Markdown document chunking with embedding-based relevance search" "Python / Annoy"
            embeddingsSystem = container "Embeddings System" "Pluggable embedding providers (FastEmbed, Sentence Transformers)" "Python / ONNX Runtime"
            actionsServer = container "Actions Server" "Separate FastAPI server for remote action execution" "Python / FastAPI / 8001/TCP"
            tracingAdapter = container "Tracing Adapter" "OpenTelemetry library-mode integration for span export" "Python / OpenTelemetry API"
        }

        upstreamLLM = softwareSystem "Upstream LLM Server" "LLM inference service (OpenAI, NVIDIA NIM, or custom endpoint)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "Internal RHOAI"
        redis = softwareSystem "Redis" "Optional conversation thread persistence" "External"
        rhoaiPlatform = softwareSystem "RHOAI Platform Operator" "Deploys and manages NeMo Guardrails container" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Ingress routing, TLS termination, and authentication" "Internal RHOAI"

        # User relationships
        user -> nemoGuardrails "Sends chat completions and guardrail check requests" "HTTPS via platform gateway"
        securityEngineer -> nemoGuardrails "Defines guardrail flows in Colang DSL" "Configuration files"

        # Internal container relationships
        server -> llmRailsEngine "Delegates complex guardrailed requests"
        server -> ioRailsEngine "Delegates safety-only checks"
        llmRailsEngine -> colangRuntime "Executes Colang flow definitions"
        llmRailsEngine -> guardrailsLibrary "Applies input/output guardrail modules"
        ioRailsEngine -> guardrailsLibrary "Applies content safety modules"
        llmRailsEngine -> knowledgeBase "Retrieves relevant context for RAG"
        knowledgeBase -> embeddingsSystem "Generates embeddings for similarity search"
        server -> actionsServer "Executes remote actions" "HTTP/8001"
        server -> tracingAdapter "Exports trace spans"

        # External relationships
        nemoGuardrails -> upstreamLLM "LLM inference calls via LangChain" "HTTPS/443 Bearer Token"
        nemoGuardrails -> otelCollector "Exports distributed traces" "OTLP gRPC/4317"
        nemoGuardrails -> redis "Persists conversation threads (optional)" "TCP/6379"
        rhoaiPlatform -> nemoGuardrails "Deploys and manages container lifecycle"
        rhoaiGateway -> nemoGuardrails "Routes traffic with TLS termination and auth" "HTTP/8000"
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
        }
    }
}
