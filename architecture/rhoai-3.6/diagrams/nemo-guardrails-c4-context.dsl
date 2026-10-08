workspace {
    model {
        user = person "Application Developer" "Builds LLM-powered applications with safety guardrails"
        operator = person "Platform Operator" "Deploys and configures NeMo Guardrails on RHOAI"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails toolkit for LLM-based conversational systems providing input/output rail enforcement, jailbreak detection, content safety, and fact-checking" {
            server = container "FastAPI Server" "OpenAI-compatible API server with config-driven multi-rail pipelines" "Python / FastAPI / uvicorn" "Service"
            ioRails = container "IORails Dispatcher" "Input/output rail dispatch for modern guardrail configurations" "Python" "Component"
            llmRails = container "LLMRails Engine" "Legacy event-driven Colang v1.0 pipeline with full LLM interaction" "Python" "Component"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0 event-driven, v2.x declarative)" "Python" "Component"
            guardrailsLibrary = container "Guardrails Library" "30+ built-in guardrail types: jailbreak, content safety, PII, fact-checking, hallucination, prompt injection" "Python" "Component"
            actionsServer = container "Actions Server" "Standalone action execution server for remote action dispatch" "Python / FastAPI" "Service"
            cli = container "CLI" "Command-line interface for server management, chat, and evaluation" "Python / Typer" "CLI"
            bakedModels = container "Baked-in ML Models" "MiniLM, Snowflake Arctic, spaCy, NLTK punkt, DeBERTa, Granite Guardian HAP" "ONNX / PyTorch" "Data Store"
        }

        llmProvider = softwareSystem "OpenAI-compatible LLM" "LLM inference endpoint for guardrail generation and chat completion" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Azure-specific LLM and embedding provider" "External"
        thirdPartySaaS = softwareSystem "Third-Party Guardrail SaaS" "Optional external guardrail evaluations (ActiveFence, AI Defense, Pangea, Patronus, CrowdStrike, F5, etc.)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "External"

        # User relationships
        user -> nemoGuardrails "Sends chat completions and guardrail checks via" "REST API / HTTP"
        operator -> nemoGuardrails "Deploys and configures via" "YAML config / env vars"

        # Internal relationships
        server -> ioRails "Dispatches to" "Internal"
        server -> llmRails "Delegates to (legacy)" "Internal"
        ioRails -> guardrailsLibrary "Runs input/output rails" "Internal"
        llmRails -> colangRuntime "Executes Colang flows" "Internal"
        llmRails -> guardrailsLibrary "Uses rail implementations" "Internal"
        guardrailsLibrary -> bakedModels "Runs local ML inference" "ONNX / PyTorch"
        cli -> server "Manages" "HTTP"

        # External relationships
        nemoGuardrails -> llmProvider "LLM inference" "HTTPS/443, Bearer Token"
        nemoGuardrails -> azureOpenAI "Azure LLM and embeddings" "HTTPS/443, API Key"
        nemoGuardrails -> thirdPartySaaS "Optional external evaluations" "HTTPS/443, API Key"
        nemoGuardrails -> otelCollector "Exports traces and metrics" "OTLP gRPC/HTTP"
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
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #6baed6
                color #ffffff
            }
            element "Data Store" {
                background #d5e8d4
                color #333333
            }
            element "CLI" {
                background #6baed6
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
