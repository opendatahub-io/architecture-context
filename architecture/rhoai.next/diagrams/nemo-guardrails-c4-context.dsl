workspace {
    model {
        user = person "Application Developer" "Integrates LLM guardrails into AI applications"
        operator = person "Platform Operator" "Deploys and configures guardrail policies via ConfigMaps"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit for LLM-based conversational systems, exposed as an OpenAI-compatible FastAPI server" {
            apiServer = container "FastAPI Server" "OpenAI-compatible HTTP server exposing chat completion and guardrail check endpoints" "Python FastAPI, Uvicorn" "Port 8000/TCP"
            llmRailsEngine = container "LLMRails Engine" "Core engine orchestrating input/output/dialog/retrieval/tool rail pipelines" "Python"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0 and v2.x) for defining conversational flows and guardrail logic" "Python, Lark Parser"
            guardrailLibrary = container "Guardrail Library" "30+ built-in guardrail implementations: content safety, hallucination, injection detection, sensitive data, factchecking, topic control" "Python Modules"
            embeddingProviders = container "Embedding Providers" "Pluggable embedding backends (FastEmbed default, baked into container) for similarity search against known patterns" "Python, FastEmbed, ONNX Runtime"
            tracingModule = container "Tracing Module" "OpenTelemetry-compatible tracing with span extractors for guardrail execution monitoring" "Python, OpenTelemetry SDK"
        }

        vllm = softwareSystem "vLLM Serving Runtime" "Primary LLM inference backend for RHOAI deployments" "Internal RHOAI"
        openai = softwareSystem "OpenAI API" "OpenAI model inference" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "Azure-hosted OpenAI model inference" "External"
        nvidiaNim = softwareSystem "NVIDIA NIM" "NVIDIA-hosted model inference" "External"
        anthropic = softwareSystem "Anthropic API" "Anthropic Claude model inference" "External"
        cohere = softwareSystem "Cohere API" "Cohere model inference" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "Internal Platform"
        configMap = softwareSystem "Kubernetes ConfigMap" "Runtime guardrail configuration (config.yaml + rails.co)" "Internal Platform"

        # User relationships
        user -> nemoGuardrails "Sends chat completion and guardrail check requests" "HTTP/8000"
        operator -> configMap "Defines guardrail policies and Colang flows"

        # Internal container relationships
        apiServer -> llmRailsEngine "Routes requests to rail pipeline"
        llmRailsEngine -> colangRuntime "Interprets Colang flow definitions"
        llmRailsEngine -> guardrailLibrary "Executes input/output/tool rails"
        llmRailsEngine -> embeddingProviders "Similarity search for pattern matching"
        apiServer -> tracingModule "Emits OpenTelemetry spans"

        # External relationships
        nemoGuardrails -> vllm "LLM inference for responses and guardrail evaluation" "HTTPS/443, Bearer Token"
        nemoGuardrails -> openai "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> azureOpenai "LLM inference" "HTTPS/443, api-key header"
        nemoGuardrails -> nvidiaNim "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> anthropic "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> cohere "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> otelCollector "Exports traces and metrics" "OTLP gRPC/4317 or HTTP/4318"
        configMap -> nemoGuardrails "Mounted at /app/config/ (config.yaml, rails.co)" "Volume mount"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
