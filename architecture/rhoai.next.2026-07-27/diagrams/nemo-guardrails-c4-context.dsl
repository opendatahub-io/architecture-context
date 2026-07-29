workspace {
    model {
        user = person "Application Developer" "Integrates guardrails into LLM-based conversational systems"
        operator = person "Platform Operator" "Configures and deploys NeMo Guardrails"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "Programmable safety rails for LLM conversational systems with OpenAI-compatible API" {
            guardrailsServer = container "Guardrails Server" "Main FastAPI application exposing OpenAI-compatible chat/completion and guardrail check endpoints" "Python/FastAPI"
            actionsServer = container "Actions Server" "Remote action execution server with /v1/actions/* endpoints" "Python/FastAPI"
            jailbreakServer = container "Jailbreak Detection Server" "Jailbreak heuristic and model-based detection server" "Python/FastAPI"
            alignScoreServer = container "AlignScore Server" "Factual alignment scoring server" "Python/FastAPI"
            guardrailsLibrary = container "Guardrails Library" "Pluggable action framework integrating third-party safety services" "Python Modules"
        }

        openai = softwareSystem "OpenAI API" "LLM inference via OpenAI SDK" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "LLM inference via Azure OpenAI SDK" "External"
        activeFence = softwareSystem "ActiveFence" "Content moderation service" "External"
        ciscoAIDefense = softwareSystem "Cisco AI Defense" "AI content defense and safety service" "External"
        autoAlign = softwareSystem "AutoAlign" "Content alignment verification service" "External"
        clavata = softwareSystem "Clavata" "Content checking and analysis service" "External"

        # User interactions
        user -> nemoGuardrails "Sends chat/completion requests via OpenAI-compatible API" "HTTPS"
        operator -> nemoGuardrails "Configures rails, actions, and guardrail policies" "YAML/Python"

        # Internal interactions
        guardrailsServer -> guardrailsLibrary "Invokes safety rail actions"
        guardrailsServer -> jailbreakServer "Checks for jailbreak attempts" "HTTP"
        guardrailsServer -> alignScoreServer "Verifies factual alignment" "HTTP"
        guardrailsServer -> actionsServer "Executes remote actions" "HTTP"

        # Outbound integrations
        guardrailsServer -> openai "LLM inference requests" "HTTPS/TLS, API Key"
        guardrailsServer -> azureOpenai "LLM inference requests" "HTTPS/443, API Key"
        guardrailsLibrary -> activeFence "Content moderation checks" "HTTPS/443, API Key (aiohttp)"
        guardrailsLibrary -> ciscoAIDefense "AI defense checks" "HTTPS, API Key (httpx)"
        guardrailsLibrary -> autoAlign "Alignment verification" "HTTPS, API Key (aiohttp)"
        guardrailsLibrary -> clavata "Content analysis" "HTTPS, API Key (aiohttp)"
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
