workspace {
    model {
        user = person "Application Developer" "Builds LLM-powered applications that need safety guardrails"
        securityEngineer = person "Security Engineer" "Configures guardrail policies and Colang flows"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety proxy for LLM-based conversational applications" {
            server = container "Guardrails Server" "FastAPI + Uvicorn HTTP server exposing OpenAI-compatible API with guardrails" "Python / FastAPI" "Port 8000"
            colangRuntime = container "Colang Runtime" "Programmable dialog language runtime (v1.0 and v2.x) for defining guardrail flows" "Python Library"
            guardrailsLib = container "Guardrails Library" "30+ guardrail integrations (self_check, content_safety, llama_guard, regex, hallucination, etc.)" "Python Library"
            embeddingsEngine = container "Embeddings Engine" "ONNX-based embedding generation for semantic similarity rails" "FastEmbed / ONNX Runtime"
            headerForwarding = container "Header Forwarding" "Maps X-Authorization to Authorization for upstream LLM, filters infrastructure headers" "Python Module"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Platform authentication sidecar for TLS termination and token validation" "Platform"
        upstreamLLM = softwareSystem "Upstream LLM Server" "Chat completion model server (vLLM, NIM, or OpenAI-compatible)" "External"
        redis = softwareSystem "Redis" "Optional thread/conversation persistence store" "External"
        nvidiaTelemetry = softwareSystem "NVIDIA Telemetry" "Anonymous usage statistics collection (opt-out via DO_NOT_TRACK=1)" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model artifact repository (only if models not pre-cached in image)" "External"
        guardrailsConfig = softwareSystem "Guardrails Configuration" "Colang flows, config.yaml, and custom actions on filesystem" "Internal"
        preCachedModels = softwareSystem "Pre-cached ML Models" "sentence-transformers/all-MiniLM-L6-v2 baked into container image" "Internal"

        # External relationships
        user -> nemoGuardrails "Sends OpenAI-compatible chat completion requests" "HTTPS/443 via platform ingress"
        securityEngineer -> guardrailsConfig "Authors Colang flows and guardrail policies" "Filesystem"

        # Platform auth
        user -> kubeRbacProxy "Authenticates via platform token" "HTTPS/443 TLS 1.2+"
        kubeRbacProxy -> nemoGuardrails "Forwards authenticated requests" "HTTP/8000 plaintext (in-pod)"

        # Internal container relationships
        server -> colangRuntime "Invokes rail evaluation" "In-memory"
        colangRuntime -> guardrailsLib "Evaluates configured rails" "In-memory"
        guardrailsLib -> embeddingsEngine "Computes semantic similarity" "In-memory"
        server -> headerForwarding "Maps auth headers for upstream calls" "In-memory"

        # Outbound dependencies
        nemoGuardrails -> upstreamLLM "Forwards chat completion requests after rail evaluation" "HTTPS/443 TLS 1.2+ Bearer Token"
        nemoGuardrails -> redis "Persists thread/conversation state (optional)" "TCP/6379 Redis protocol"
        nemoGuardrails -> nvidiaTelemetry "Reports anonymous usage statistics" "HTTPS/443 TLS 1.2+"
        nemoGuardrails -> huggingFaceHub "Downloads model artifacts (only if not pre-cached)" "HTTPS/443 TLS 1.2+"

        # Internal dependencies
        nemoGuardrails -> guardrailsConfig "Loads Colang flows and config at startup" "Filesystem"
        embeddingsEngine -> preCachedModels "Loads pre-baked ML models" "Filesystem"
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
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Internal" {
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
