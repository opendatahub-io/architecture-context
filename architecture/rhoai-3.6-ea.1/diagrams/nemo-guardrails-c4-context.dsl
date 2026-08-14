workspace {
    model {
        user = person "Application Developer" "Integrates LLM guardrails into conversational AI applications"

        nemoGuardrails = softwareSystem "NeMo-Guardrails" "Programmable guardrails for LLM-based conversational systems with OpenAI-compatible API" {
            fastapiServer = container "FastAPI Server" "Serves OpenAI-compatible chat completion and guardrail check APIs via uvicorn" "Python/FastAPI/uvicorn"
            guardrailPipeline = container "Guardrail Pipeline" "Configurable input/output rail processing with YAML/Colang policies" "Python"
            headerForwarding = container "Header Forwarding Module" "Maps X-Authorization to outbound Authorization, excludes K8s auth" "Python"
            nlpModels = container "Pre-fetched NLP Models" "spaCy, sentence-transformers, fastembed models cached in container image" "Python/ONNX"
            guardrailProviders = container "Guardrail Provider Integrations" "ActiveFence, AI Defense, Presidio, Patronus, and other third-party guardrail actions" "Python"
        }

        azureOpenAI = softwareSystem "Azure OpenAI" "Microsoft Azure-hosted OpenAI inference service" "External"
        openAI = softwareSystem "OpenAI API" "OpenAI inference service" "External"
        k8sInfra = softwareSystem "Kubernetes Infrastructure" "Ingress, proxy, and service mesh providing authentication and TLS termination" "External"
        thirdPartyGuardrails = softwareSystem "Third-Party Guardrail APIs" "ActiveFence, AI Defense, Patronus, Pangea, and other content safety providers" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model artifact registry for NLP models (build-time only)" "External"

        user -> nemoGuardrails "Sends chat completions and guardrail check requests" "HTTPS (via K8s ingress)"
        k8sInfra -> nemoGuardrails "Authenticates and forwards requests" "HTTP/8000"
        nemoGuardrails -> azureOpenAI "Sends LLM inference requests" "HTTPS/443"
        nemoGuardrails -> openAI "Sends LLM inference requests" "HTTPS/443"
        nemoGuardrails -> thirdPartyGuardrails "Sends content safety checks" "HTTPS"

        fastapiServer -> guardrailPipeline "Routes requests through configured rails"
        guardrailPipeline -> headerForwarding "Prepares outbound LLM authentication"
        guardrailPipeline -> nlpModels "Uses for content analysis"
        guardrailPipeline -> guardrailProviders "Invokes third-party guardrail actions"
        headerForwarding -> azureOpenAI "Forwards with API key or X-Authorization" "HTTPS/443"
        headerForwarding -> openAI "Forwards with API key or X-Authorization" "HTTPS/443"
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
