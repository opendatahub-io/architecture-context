workspace {
    model {
        client = person "Client Application" "Sends chat completions and guardrail check requests"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable guardrails for LLM-based conversational systems — input/output filtering, jailbreak detection, fact-checking, topic control" {
            server = container "FastAPI Server" "OpenAI-compatible API surface on port 8000; delegates to guardrail engines" "Python / FastAPI / uvicorn"
            guardrailsEngine = container "Guardrails Engine" "Orchestrates input rails → dialog → output rails pipeline" "Python"
            colangRuntime = container "Colang Runtime" "Domain-specific language runtime (v1.0/v2.x) for guardrail rules and conversational flows" "Python / Lark parser"
            builtInModels = container "Built-in ML Models" "MiniLM, Snowflake Arctic, spaCy, NLTK, DeBERTa, Granite Guardian HAP — pre-downloaded via modelcar images" "PyTorch / ONNX / Transformers"
            headerForwarding = container "Header Forwarding" "X-Authorization → Authorization mapping; inbound Authorization never forwarded" "Python / contextvars"
            checksEndpoint = container "Checks Endpoint" "Fork-specific /v1/checks for standalone guardrail evaluation without LLM" "Python / FastAPI"
        }

        llmProvider = softwareSystem "OpenAI-compatible LLM" "Backend LLM for guardrail-mediated text generation" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Alternative LLM provider for embeddings and completions" "External"
        hfClassifier = softwareSystem "Remote HF Classifier" "Remote HuggingFace model classification endpoints" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"

        # External relationships
        client -> nemoGuardrails "POST /v1/chat/completions, /v1/checks" "HTTP/8000"
        nemoGuardrails -> llmProvider "LLM inference requests" "HTTPS/443, Bearer token"
        nemoGuardrails -> azureOpenAI "Embeddings and completions" "HTTPS/443, API key"
        nemoGuardrails -> hfClassifier "Remote classification" "HTTPS, configurable TLS/mTLS"
        nemoGuardrails -> otelCollector "Trace export" "gRPC/HTTP, optional"

        # Internal relationships
        server -> guardrailsEngine "Delegates guardrail evaluation"
        server -> checksEndpoint "Fork-specific check endpoint"
        server -> headerForwarding "Auth passthrough to LLM"
        guardrailsEngine -> colangRuntime "Evaluates Colang rules"
        guardrailsEngine -> builtInModels "Local ML inference"
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
