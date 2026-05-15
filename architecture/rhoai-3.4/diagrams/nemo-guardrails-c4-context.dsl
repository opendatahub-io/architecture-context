workspace {
    model {
        user = person "Data Scientist / Application" "Sends prompts and receives guardrailed LLM responses"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety guardrails for LLM-based conversational systems" {
            server = container "Guardrails Server" "FastAPI/Uvicorn OpenAI-compatible API server with programmable guardrails" "Python/FastAPI" "Port 8000"
            actionsServer = container "Actions Server" "Secondary server for custom guardrail action execution" "Python/FastAPI" "Port 8001"
            iorailsEngine = container "IORails Engine" "Optimized execution engine for standard safety flows" "Python Module"
            llmrailsEngine = container "LLMRails Engine" "Full Colang runtime engine with v1.0 and v2.x support" "Python Module"
            guardrailsLibrary = container "Guardrails Library" "30+ built-in guardrail types: content safety, hallucination, jailbreak, SDD, self-check" "Python Module"
            colangParser = container "Colang Parser" "Parser and runtime for NVIDIA's Colang DSL" "Python Module"
            embeddingSystem = container "Embedding System" "Multi-provider embedding framework with Annoy vector search and caching" "Python Module"
            lfuCache = container "LFU Cache" "Least Frequently Used cache for LLM responses with SHA-256 keys" "Python Module"
        }

        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform operator managing ingress, auth, and deployment" "Internal RHOAI"

        openai = softwareSystem "OpenAI API" "LLM text generation and chat completions" "External"
        anthropic = softwareSystem "Anthropic API" "LLM text generation via Claude models" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "LLM text generation via Azure-hosted models" "External"
        cohere = softwareSystem "Cohere API" "LLM text generation and embedding" "External"
        selfHostedLLM = softwareSystem "vLLM / NIM / TRT-LLM" "Self-hosted LLM inference endpoints" "External"

        contentSafetyModel = softwareSystem "Content Safety Model" "LLM-based content safety classification" "External"
        jailbreakDetection = softwareSystem "Jailbreak Detection Endpoint" "Heuristic and model-based jailbreak classification" "External"

        redis = softwareSystem "Redis" "Distributed conversation thread state persistence" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and observability" "External"

        user -> nemoGuardrails "Sends chat completions and guardrail checks" "HTTP/8000"
        rhoaiPlatform -> nemoGuardrails "Manages ingress, TLS, auth, deployment" "HTTPRoute/Route"

        nemoGuardrails -> openai "LLM generation, model listing" "HTTPS/443, Bearer Token"
        nemoGuardrails -> anthropic "LLM generation" "HTTPS/443, x-api-key"
        nemoGuardrails -> azureOpenai "LLM generation" "HTTPS/443, api-key"
        nemoGuardrails -> cohere "LLM generation, embedding" "HTTPS/443, Bearer Token"
        nemoGuardrails -> selfHostedLLM "LLM inference" "HTTP(S), configurable"

        nemoGuardrails -> contentSafetyModel "Input/output content safety checks" "HTTP(S), API key"
        nemoGuardrails -> jailbreakDetection "Jailbreak detection checks" "HTTP(S), API key"

        nemoGuardrails -> redis "Thread state persistence" "TCP/6379, optional TLS"
        nemoGuardrails -> otelCollector "Export traces" "OTLP, configurable"

        server -> iorailsEngine "Standard guardrail flows"
        server -> llmrailsEngine "Complex Colang flows"
        iorailsEngine -> guardrailsLibrary "Execute rail checks"
        llmrailsEngine -> colangParser "Parse Colang definitions"
        llmrailsEngine -> guardrailsLibrary "Execute rail checks"
        server -> embeddingSystem "Knowledge base search"
        server -> lfuCache "Cache LLM responses"
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
        }
    }
}
