workspace {
    model {
        user = person "Application Developer" "Integrates guardrails into LLM-powered applications"
        platformOp = person "Platform Operator" "Deploys and configures guardrail policies via ConfigMaps"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails for LLM safety: input/output validation, topic control, hallucination detection, sensitive data filtering" {
            server = container "Guardrails Server" "FastAPI HTTP server exposing OpenAI-compatible chat completion and guardrail check endpoints" "Python FastAPI, port 8000"
            llmRails = container "LLMRails Engine" "Core engine orchestrating input/output/dialog/retrieval/tool rail pipelines" "Python"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0 / v2.x) for defining conversational flows and guardrail logic" "Python, Lark parser"
            guardrailLibrary = container "Guardrail Library" "30+ built-in guardrail implementations: content safety, hallucination, injection, PII, topic control" "Python modules"
            embeddingProviders = container "Embedding Providers" "Pluggable embedding backends for similarity search (FastEmbed all-MiniLM-L6-v2 baked-in)" "Python, ONNX Runtime"
            tracingModule = container "Tracing Module" "OpenTelemetry-compatible tracing with span extractors for guardrail execution monitoring" "Python, OpenTelemetry"
        }

        vllm = softwareSystem "vLLM Serving Runtime" "Primary LLM inference backend for RHOAI deployments (OpenAI-compatible)" "Internal RHOAI"
        openai = softwareSystem "OpenAI API" "OpenAI cloud-hosted LLM inference" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "Azure-hosted OpenAI model inference" "External"
        nvidiaNim = softwareSystem "NVIDIA NIM" "NVIDIA AI Endpoints model inference" "External"
        anthropic = softwareSystem "Anthropic API" "Anthropic Claude model inference" "External"
        cohere = softwareSystem "Cohere API" "Cohere model inference" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "Internal Platform"
        configMap = softwareSystem "Kubernetes ConfigMap" "Runtime guardrail configuration (config.yaml + rails.co)" "Kubernetes"

        # User interactions
        user -> nemoGuardrails "Sends chat completion and guardrail check requests" "HTTP/8000"
        platformOp -> configMap "Defines guardrail policies and Colang flows" "kubectl"

        # Container-level interactions
        server -> llmRails "Orchestrates rail pipeline"
        llmRails -> colangRuntime "Interprets Colang flow definitions"
        llmRails -> guardrailLibrary "Invokes guardrail implementations"
        llmRails -> embeddingProviders "Similarity search for content matching"
        server -> tracingModule "Emits OpenTelemetry spans"

        # External dependencies
        nemoGuardrails -> vllm "LLM inference (chat completion + guardrail evaluation)" "HTTPS/443, Bearer Token"
        nemoGuardrails -> openai "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> azureOpenai "LLM inference" "HTTPS/443, api-key header"
        nemoGuardrails -> nvidiaNim "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> anthropic "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> cohere "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> otelCollector "Export traces and metrics" "OTLP gRPC/4317 or HTTP/4318"
        configMap -> nemoGuardrails "Provides guardrail config at /app/config/" "Volume mount"
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
                background #9b59b6
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
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
