workspace {
    model {
        user = person "Application Developer" "Builds LLM-powered applications that need guardrails"
        securityEngineer = person "Security Engineer" "Configures guardrail policies and reviews safety posture"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety layer for LLM applications — intercepts and validates LLM interactions via configurable input/output rail pipelines" {
            server = container "FastAPI Server" "OpenAI-compatible HTTP API with guardrail-specific endpoints (/v1/chat/completions, /v1/checks)" "Python / uvicorn / FastAPI" "WebApp"
            guardrailsEngine = container "Guardrails Engine" "Dispatches to IORails (modern) or LLMRails (legacy) engines based on configuration" "Python Library"
            ioRails = container "IORails Engine" "Modern input/output rail pipeline with engine registry dispatch" "Python Library"
            llmRails = container "LLMRails Engine" "Legacy event-driven Colang pipeline for full conversational guardrails" "Python Library"
            colangRuntime = container "Colang DSL Runtime" "v1.0 (simple flows) and v2.x (concurrent flows, rich state) runtimes" "Python Library"
            guardrailLibrary = container "Guardrail Library" "30+ built-in modules: content safety, jailbreak detection, PII, fact-checking, hallucination detection" "Python Library"
            headerForwarding = container "Header Forwarding" "Maps X-Authorization to Authorization for LLM provider; blocks inbound Authorization forwarding" "Python Module"
            bakedModels = container "Baked-In ML Models" "Six modelcar-sourced models: MiniLM, Snowflake Arctic, spaCy, NLTK, DeBERTa, Granite Guardian HAP" "ONNX / PyTorch"
        }

        llmServer = softwareSystem "LLM Inference Server" "OpenAI-compatible LLM backend (vLLM, TGI, etc.)" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Microsoft Azure OpenAI Service for LLM and embedding inference" "External"
        safetyAPIs = softwareSystem "Third-Party Safety APIs" "External guardrail providers: ActiveFence, Pangea, CrowdStrike, etc." "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "External"
        platformIngress = softwareSystem "Platform Ingress" "OpenShift Route or Istio Gateway for TLS termination" "Infrastructure"

        // User relationships
        user -> nemoGuardrails "Sends chat completions and guardrail check requests"
        securityEngineer -> nemoGuardrails "Configures guardrail policies via Colang configs"

        // Internal relationships
        server -> guardrailsEngine "Dispatches requests"
        guardrailsEngine -> ioRails "Modern pipeline"
        guardrailsEngine -> llmRails "Legacy pipeline"
        ioRails -> colangRuntime "Executes Colang flows"
        llmRails -> colangRuntime "Executes Colang flows"
        ioRails -> guardrailLibrary "Evaluates guardrail modules"
        llmRails -> guardrailLibrary "Evaluates guardrail modules"
        guardrailLibrary -> bakedModels "Local ML inference"
        server -> headerForwarding "Maps auth headers"

        // External relationships
        nemoGuardrails -> llmServer "LLM inference" "HTTPS / Bearer token"
        nemoGuardrails -> azureOpenAI "Alternative LLM/embedding" "HTTPS/443 / API key"
        nemoGuardrails -> safetyAPIs "External safety evaluation" "HTTPS/443 / API keys"
        nemoGuardrails -> otelCollector "Distributed tracing" "gRPC/HTTP (optional)"
        platformIngress -> nemoGuardrails "Routes traffic (TLS terminated)" "HTTP/8000"
        user -> platformIngress "HTTPS requests" "HTTPS/443"
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
            element "Infrastructure" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
        }
    }
}
