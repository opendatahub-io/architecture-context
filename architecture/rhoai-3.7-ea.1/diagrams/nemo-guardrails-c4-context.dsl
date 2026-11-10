workspace {
    model {
        appDev = person "Application Developer" "Builds LLM apps that call guardrailed chat completions"
        platformAdmin = person "Platform Admin / Data Scientist" "Authors rails configuration (YAML + Colang) and creates NemoGuardrails CRs"

        guardrails = softwareSystem "NeMo-Guardrails" "OpenAI-compatible guardrails proxy applying input, output, dialog, retrieval and tool rails around LLM calls" {
            server = container "Guardrails Server" "FastAPI/uvicorn on 8000/TCP plain HTTP; /v1/chat/completions, /v1/checks, /v1/models, health" "Python 3.12"
            checksRouter = container "Fork Checks Router" "Deprecated /v1/guardrail/checks (sunset 2027-02-01)" "FastAPI APIRouter"
            engine = container "LLMRails Engine" "Executes Colang 1.0/2.x flows and rails" "Python library"
            library = container "Guardrails Library" "Presidio PII, YARA injection, HF/ONNX classifiers, content safety, topic control, regex, f5, polygraf, guardrails_ai" "Python modules"
            headerFwd = container "Header Forwarding" "Forwards X-* headers; maps X-Authorization to provider Authorization" "Python module"
            modelStore = container "Baked-in Models" "MiniLM, Arctic embed, spaCy, NLTK punkt, Wolf Defender, Granite Guardian HAP (offline)" "Filesystem caches"
            configVol = container "Rails Config Volume" "/app/config/CONFIG_ID - YAML, Colang, config.py, actions.py" "Mounted ConfigMap"

            server -> checksRouter "Mounts"
            server -> engine "Gets/caches rails per config_id"
            checksRouter -> engine "Runs rails"
            engine -> library "Invokes rails"
            library -> modelStore "Loads local models"
            engine -> headerFwd "Builds outbound headers"
            server -> configVol "Loads config per request; exec config.py at startup"
        }

        trustyai = softwareSystem "TrustyAI Service Operator" "Deploys the guardrails image via NemoGuardrails CR (Deployment, Service, Route, config)" "Internal RHOAI"
        modelServing = softwareSystem "KServe / vLLM" "OpenAI-compatible main and rails LLM endpoints" "Internal RHOAI"
        llamaStack = softwareSystem "Llama Stack / Client Apps" "Consumers of the guardrails API" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Traces/metrics sink (optional)" "External"
        openai = softwareSystem "OpenAI / Azure OpenAI" "Optional external LLM and embeddings" "External"
        saas = softwareSystem "Guardrail SaaS (f5, polygraf, guardrails_ai)" "Optional third-party rails" "External"
        aipcc = softwareSystem "AIPCC Base Images + RHAI Modelcars" "cpu-torch2.13-el9.8 base and build-time model images" "Build"

        appDev -> llamaStack "Builds"
        llamaStack -> guardrails "Calls /v1/chat/completions, /v1/checks" "HTTP/8000"
        appDev -> guardrails "Calls via operator Route" "HTTPS/443"
        platformAdmin -> trustyai "Creates NemoGuardrails CR and rails config"
        trustyai -> guardrails "Deploys image, mounts config"
        guardrails -> modelServing "Generation and LLM-based rails; Bearer env key or X-Authorization" "HTTP/HTTPS"
        guardrails -> otel "Exports OTLP when OTEL_EXPORTER_OTLP_ENDPOINT set" "gRPC/HTTP 4317/4318"
        guardrails -> openai "Optional LLM/embeddings; API key env" "HTTPS/443"
        guardrails -> saas "Optional external rails; API key env" "HTTPS/443"
        aipcc -> guardrails "Provides base image and baked models (build time)"

        llamaStack -> server "Guarded completions" "HTTP/8000"
        headerFwd -> modelServing "OpenAI-compatible requests" "HTTP/HTTPS"
        trustyai -> configVol "Mounts ConfigMap"
    }

    views {
        systemContext guardrails "SystemContext" {
            include *
            autoLayout
        }

        container guardrails "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Build" {
                background #f5a623
            }
            element "Person" {
                shape person
            }
        }
    }
}
