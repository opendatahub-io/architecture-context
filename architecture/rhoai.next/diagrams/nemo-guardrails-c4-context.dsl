workspace {
    model {
        user = person "Application Developer" "Builds LLM-powered applications that require safety guardrails"
        securityEngineer = person "Security Engineer" "Configures guardrail policies and safety rules"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety guardrails for LLM-based conversational systems, exposing an OpenAI-compatible API" {
            server = container "FastAPI Server" "OpenAI-compatible REST API server (uvicorn :8000)" "Python / FastAPI"
            llmRailsEngine = container "LLMRails Engine" "Orchestrates config loading, runtime init, action dispatch, and LLM calls" "Python"
            colangRuntime = container "Colang Runtime" "DSL runtime (v1.0 imperative + v2.x declarative) for defining guardrail flows" "Python"
            actionDispatcher = container "Action Dispatcher" "Extensible action system with filesystem-based discovery and decorator registration" "Python"
            guardrailsLibrary = container "Guardrails Library" "27+ built-in guardrail implementations (content safety, PII, jailbreak, hallucination, etc.)" "Python"
            knowledgeBase = container "Knowledge Base" "Document indexing and embedding-based semantic search for RAG guardrails" "Python"
        }

        llmService = softwareSystem "LLM Inference Service" "Upstream LLM for chat completion and safety classification (vLLM, NIM, OpenAI)" "External"
        platformOperator = softwareSystem "RHOAI Platform Operator" "rhods-operator — manages deployment lifecycle, creates Service/ConfigMap" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "AI trustworthiness platform — NeMo Guardrails is part of TrustyAI suite" "Internal RHOAI"

        externalGuardrails = softwareSystem "External Guardrail APIs" "16 optional providers: ActiveFence, Cisco AI Defense, CrowdStrike, Pangea, Patronus, etc." "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        redis = softwareSystem "Redis" "Thread/conversation state persistence for multi-turn conversations" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained NLP model downloads (build-time only)" "External"

        # Relationships
        user -> nemoGuardrails "Sends chat completions and guardrail check requests" "HTTPS/443 via platform ingress"
        securityEngineer -> nemoGuardrails "Configures guardrail policies via Colang files and config.yaml" "ConfigMap volume mount"

        nemoGuardrails -> llmService "Forwards chat requests and safety classification prompts" "HTTPS/443, Bearer Token"
        nemoGuardrails -> externalGuardrails "Invokes optional external safety checks" "HTTPS/443, API Key / Bearer Token"
        nemoGuardrails -> otelCollector "Exports distributed traces" "OTLP/4317 gRPC or 4318 HTTP"
        nemoGuardrails -> redis "Persists thread/conversation state" "Redis/6379, Password Auth"

        platformOperator -> nemoGuardrails "Deploys and manages lifecycle" "Kubernetes API"
        trustyAI -> nemoGuardrails "Includes as component in TrustyAI suite" "Deployment context"

        # Internal container relationships
        server -> llmRailsEngine "Routes API requests"
        llmRailsEngine -> colangRuntime "Selects and executes Colang flows"
        llmRailsEngine -> actionDispatcher "Dispatches guardrail actions"
        actionDispatcher -> guardrailsLibrary "Executes built-in guardrails"
        llmRailsEngine -> knowledgeBase "RAG-based guardrail queries"
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
                color #000000
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
                background #5b9bd5
                color #ffffff
            }
        }
    }
}
