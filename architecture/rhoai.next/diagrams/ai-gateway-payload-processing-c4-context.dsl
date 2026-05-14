workspace {
    model {
        user = person "Application Developer" "Deploys ExternalModel CRs to expose LLM models via Gateway API"
        client = person "Inference Consumer" "Sends inference requests to Gateway API endpoint"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "BBR ExtProc host providing model resolution, API translation, credential injection, and guardrails for Gateway API inference requests" {
            extprocServer = container "ExtProc gRPC Server" "Hosts BBR plugin pipeline, receives request/response bodies from Envoy" "Go Service, 9004/TCP gRPC"
            modelProviderResolver = container "model-provider-resolver" "Watches ExternalModel CRDs, resolves model names to provider info via CycleState" "Go BBR Plugin"
            apiTranslation = container "api-translation" "Translates OpenAI Chat Completions format to/from provider-native formats" "Go BBR Plugin"
            apikeyInjection = container "apikey-injection" "Watches labeled Secrets, injects provider-specific auth headers" "Go BBR Plugin"
            nemoRequestGuard = container "nemo-request-guard" "Enforces input content policies via NeMo Guardrails" "Go BBR Plugin"
            nemoResponseGuard = container "nemo-response-guard" "Enforces output content policies via NeMo Guardrails" "Go BBR Plugin"
            healthCheck = container "Health Check" "Liveness/readiness probe endpoint" "HTTP, 9005/TCP"
        }

        gatewayAPI = softwareSystem "Gateway API (Envoy)" "Kubernetes Gateway API with Envoy proxy for inference traffic routing" "External"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter attachment for ExtProc" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Control plane API for CRD and Secret watches" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "Content policy enforcement service" "Internal Platform"
        maasController = softwareSystem "MaaS Controller" "Creates ExternalModel CRs for models-as-a-service" "Internal Platform"

        openai = softwareSystem "OpenAI API" "LLM inference provider" "External Provider"
        anthropic = softwareSystem "Anthropic API" "LLM inference provider" "External Provider"
        azureOpenai = softwareSystem "Azure OpenAI API" "LLM inference provider" "External Provider"
        bedrock = softwareSystem "AWS Bedrock API" "LLM inference provider" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI API" "LLM inference provider" "External Provider"

        # User interactions
        user -> k8sAPI "Creates ExternalModel/ExternalProvider CRs" "kubectl/HTTPS"
        client -> gatewayAPI "Sends inference requests" "HTTPS/443"

        # Gateway to ExtProc
        gatewayAPI -> aiGatewayPayloadProcessing "Sends request/response bodies via ExtProc" "gRPC/9004 plaintext"
        istio -> gatewayAPI "Attaches ExtProc via EnvoyFilter" "EnvoyFilter CR"

        # Internal container interactions
        extprocServer -> modelProviderResolver "Delegates request processing" "in-process"
        extprocServer -> apiTranslation "Delegates request/response processing" "in-process"
        extprocServer -> apikeyInjection "Delegates request processing" "in-process"
        extprocServer -> nemoRequestGuard "Delegates request processing" "in-process"
        extprocServer -> nemoResponseGuard "Delegates response processing" "in-process"

        # Control plane watches
        modelProviderResolver -> k8sAPI "Watches ExternalModel CRDs" "HTTPS/443 SA Bearer"
        apikeyInjection -> k8sAPI "Watches labeled Secrets" "HTTPS/443 SA Bearer"

        # NeMo calls
        nemoRequestGuard -> nemoGuardrails "POST /v1/guardrail/checks (input)" "HTTP plaintext"
        nemoResponseGuard -> nemoGuardrails "POST /v1/guardrail/checks (output)" "HTTP plaintext"

        # Provider egress (via Envoy)
        gatewayAPI -> openai "Proxies translated inference requests" "HTTPS/443"
        gatewayAPI -> anthropic "Proxies translated inference requests" "HTTPS/443"
        gatewayAPI -> azureOpenai "Proxies translated inference requests" "HTTPS/443"
        gatewayAPI -> bedrock "Proxies translated inference requests" "HTTPS/443"
        gatewayAPI -> vertexAI "Proxies translated inference requests" "HTTPS/443"

        # MaaS integration
        maasController -> k8sAPI "Creates ExternalModel CRs" "HTTPS/443"
    }

    views {
        systemContext aiGatewayPayloadProcessing "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayPayloadProcessing "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Provider" {
                background #f5a623
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6bb3f0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
