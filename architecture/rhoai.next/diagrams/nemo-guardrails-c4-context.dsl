workspace {
    model {
        dataScientist = person "Data Scientist / AI Developer" "Deploys LLM-powered applications with safety guardrails"
        platformAdmin = person "Platform Admin" "Configures guardrails policies and deploys NeMo Guardrails service"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety guardrails for LLM-based conversational systems" {
            server = container "NeMo Guardrails Server" "FastAPI + Uvicorn HTTP server exposing OpenAI-compatible guardrails API" "Python / FastAPI" "Service"
            colangRuntime = container "Colang Runtime" "Declarative flow execution engine for guardrail definitions (v1.0 transcript-based, v2.x state-machine)" "Python" "Runtime"
            railActionSystem = container "Rail Action System" "Extensible action dispatcher for guardrail checks" "Python" "Framework" {
                selfCheck = component "Self-Check Rails" "Input/output/facts validation via LLM prompts"
                contentSafety = component "Content Safety" "Multilingual content safety classification"
                hallucinationDetection = component "Hallucination Detection" "Multi-completion hallucination detection"
                sdd = component "Sensitive Data Detection" "PII detection via Presidio (spaCy + en_core_web_lg)"
                jailbreakDetection = component "Jailbreak Detection" "Heuristic and model-based jailbreak detection"
                injectionDetection = component "Injection Detection" "YARA rule-based injection pattern matching"
                topicSafety = component "Topic Safety" "LLM-based topic classification and filtering"
                factChecking = component "Fact Checking" "AlignScore NLI-based fact verification"
            }
            knowledgeBase = container "Knowledge Base Engine" "Vector similarity search using FastEmbed / all-MiniLM-L6-v2" "Python / ONNX" "Engine"
            llmProviderFramework = container "LLM Provider Framework" "Pluggable LLM backends via LLMModel/LLMFramework protocols" "Python" "Framework"
        }

        upstreamLLM = softwareSystem "Upstream LLM Provider" "Primary LLM backend (OpenAI, NVIDIA NIM, vLLM, Azure OpenAI, HuggingFace)" "External"
        contentSafetyModel = softwareSystem "Content Safety Model" "Dedicated model for content safety classification" "External"
        jailbreakService = softwareSystem "Jailbreak Detection Service" "Heuristic-based jailbreak detection endpoint" "External"
        alignScoreService = softwareSystem "AlignScore Service" "Fact-checking via AlignScore NLI model" "External"
        redis = softwareSystem "Redis" "Optional thread message persistence" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model artifact repository (pre-fetched at build time)" "External"
        nvidiaTelemetry = softwareSystem "NVIDIA Telemetry" "Anonymous usage statistics (can be disabled)" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator managing ingress and deployment" "Internal RHOAI"

        # Relationships
        dataScientist -> nemoGuardrails "Sends chat completions and guardrail checks via HTTP API"
        platformAdmin -> nemoGuardrails "Configures guardrails via Colang files and YAML configs"
        rhoaiOperator -> nemoGuardrails "Manages deployment, creates HTTPRoute/Route for ingress"

        nemoGuardrails -> upstreamLLM "LLM generation, content safety, topic detection" "HTTPS/443, Bearer Token"
        nemoGuardrails -> contentSafetyModel "Content safety classification" "HTTPS/443, Bearer Token"
        nemoGuardrails -> jailbreakService "Heuristic jailbreak detection" "HTTP/1337"
        nemoGuardrails -> alignScoreService "Fact-checking via AlignScore NLI" "HTTP/5000"
        nemoGuardrails -> redis "Thread message persistence (optional)" "TCP/6379, Optional TLS"
        nemoGuardrails -> otelCollector "Distributed tracing export" "OTLP gRPC/HTTP"
        nemoGuardrails -> huggingFaceHub "Model downloads (pre-fetched at build)" "HTTPS/443"
        nemoGuardrails -> nvidiaTelemetry "Anonymous usage telemetry" "HTTPS/443"

        # Internal container relationships
        server -> colangRuntime "Executes guardrail flows"
        colangRuntime -> railActionSystem "Dispatches rail actions"
        railActionSystem -> llmProviderFramework "LLM calls for rail checks"
        railActionSystem -> knowledgeBase "Retrieval-augmented guardrails"
        server -> llmProviderFramework "Main LLM generation"
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

        component railActionSystem "RailActions" {
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
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #9b59b6
                color #ffffff
            }
            element "Framework" {
                background #f5a623
                color #ffffff
            }
            element "Engine" {
                background #4caf50
                color #ffffff
            }
        }
    }
}
