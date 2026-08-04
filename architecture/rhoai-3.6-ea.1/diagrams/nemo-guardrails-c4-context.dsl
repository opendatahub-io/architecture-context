workspace {
    model {
        clientApp = person "Client Application" "Sends chat completion and guardrail check requests to the guardrails server"

        nemoGuardrails = softwareSystem "NeMo-Guardrails" "Middleware-proxy guardrails server that intercepts and validates LLM interactions, enforcing programmable safety rails on input prompts and output responses" {
            fastapiServer = container "FastAPI Server" "Main HTTP server exposing OpenAI-compatible API endpoints and guardrail checks" "Python FastAPI / Uvicorn (Port 8000)"
            inputRails = container "Input Rails Pipeline" "Evaluates user and system messages against configurable input guardrail policies" "Python Module"
            outputRails = container "Output Rails Pipeline" "Evaluates LLM responses against configurable output guardrail policies" "Python Module"
            jailbreakDetection = container "Jailbreak Detection" "Detects jailbreak attempts using heuristic and ML-based methods" "Python Server (Port 1337)"
            alignScore = container "AlignScore Fact-Checker" "Validates factual accuracy of LLM responses" "Python Server (Port 5000)"
            presidio = container "Presidio PII Detection" "Detects and anonymizes personally identifiable information" "Python Library (in-process)"
            configLoader = container "Configuration Loader" "Scans config directory for YAML-based guardrail configurations" "Python Module"
        }

        llmProvider = softwareSystem "Upstream LLM Provider" "LLM inference service configured via MAIN_MODEL_BASE_URL and MAIN_MODEL_ENGINE" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Microsoft Azure-hosted OpenAI models for inference and embeddings" "External"
        activeFence = softwareSystem "ActiveFence" "External content moderation guardrail service" "External"
        aiDefense = softwareSystem "AI Defense" "External AI safety guardrail service" "External"
        otherProviders = softwareSystem "Other Guardrail Providers" "Cleanlab, Fiddler, Pangea, Patronus, PolicyAI, Polygraf, and others" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives traces and metrics from instrumented application" "External"
        redis = softwareSystem "Redis" "Optional thread persistence datastore" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model repository for pre-fetched ML models" "External"

        clientApp -> nemoGuardrails "Sends chat/completion/check requests" "HTTP/8000"
        nemoGuardrails -> llmProvider "Proxies validated requests with forwarded Authorization header" "HTTPS"
        nemoGuardrails -> azureOpenAI "LLM inference and embeddings" "HTTPS/443 (API Key)"
        nemoGuardrails -> activeFence "Content moderation checks" "HTTPS (API Key)"
        nemoGuardrails -> aiDefense "AI safety checks" "HTTPS (API Key)"
        nemoGuardrails -> otherProviders "External guardrail evaluations" "HTTPS (API Keys)"
        nemoGuardrails -> otelCollector "Exports traces and metrics" "OTLP (gRPC/HTTP)"
        nemoGuardrails -> redis "Persists conversation threads" "TCP (optional)"
        nemoGuardrails -> huggingFace "Downloads ML models (build-time)" "HTTPS"

        fastapiServer -> inputRails "Routes incoming messages"
        fastapiServer -> outputRails "Routes LLM responses"
        inputRails -> jailbreakDetection "Checks for jailbreak patterns"
        inputRails -> presidio "Scans for PII"
        outputRails -> alignScore "Validates factual accuracy"
        configLoader -> fastapiServer "Provides guardrail configurations"
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
                shape Person
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
