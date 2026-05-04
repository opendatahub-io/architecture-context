workspace {
    model {
        user = person "Data Scientist / Application Developer" "Creates ExternalModel CRs and sends inference requests to the AI Gateway"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Pluggable BBR plugin host for model resolution, API translation, API key injection, and guardrails enforcement on inference requests" {
            extProcServer = container "ExtProc Server" "gRPC External Processing server hosting BBR plugin pipeline" "Go 1.25, gRPC/9004"
            modelProviderResolver = container "model-provider-resolver Plugin" "Watches ExternalModel CRDs, resolves model names to provider info via in-memory store" "Go BBR Plugin"
            apiTranslation = container "api-translation Plugin" "Translates between OpenAI Chat Completions format and provider-native formats (Anthropic, Azure, Bedrock, Vertex)" "Go BBR Plugin"
            apikeyInjection = container "apikey-injection Plugin" "Watches labeled Secrets, injects provider-specific auth headers" "Go BBR Plugin"
            nemoRequestGuard = container "nemo-request-guard Plugin" "Calls NeMo Guardrails for input content policy enforcement (optional)" "Go BBR Plugin"
            nemoResponseGuard = container "nemo-response-guard Plugin" "Calls NeMo Guardrails for output content policy enforcement (optional)" "Go BBR Plugin"
        }

        envoyGateway = softwareSystem "Gateway API Gateway (Envoy)" "Envoy proxy managed by Gateway API and Istio, terminates TLS, routes inference traffic" "Infrastructure"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter for ExtProc attachment" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute CRDs defining inference gateway" "Infrastructure"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Hosts ExternalModel CRDs and labeled Secrets" "Infrastructure"

        openai = softwareSystem "OpenAI API" "External LLM provider (api.openai.com)" "External Provider"
        anthropic = softwareSystem "Anthropic API" "External LLM provider (api.anthropic.com)" "External Provider"
        azure = softwareSystem "Azure OpenAI API" "External LLM provider" "External Provider"
        bedrock = softwareSystem "AWS Bedrock API" "External LLM provider (bedrock.amazonaws.com)" "External Provider"
        vertex = softwareSystem "Google Vertex AI API" "External LLM provider (aiplatform.googleapis.com)" "External Provider"

        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "Content policy enforcement via guardrail checks" "Internal ODH"
        maasController = softwareSystem "Models-as-a-Service Controller" "Creates ExternalModel CRs for provisioned models" "Internal ODH"

        # User interactions
        user -> envoyGateway "Sends inference requests" "HTTPS/443"
        user -> kubernetesAPI "Creates ExternalModel/ExternalProvider CRs" "kubectl/HTTPS"

        # Gateway to ExtProc
        envoyGateway -> extProcServer "Forwards request/response bodies via ExtProc" "gRPC/9004 plaintext"
        extProcServer -> envoyGateway "Returns mutated request/response" "gRPC/9004 plaintext"
        istio -> envoyGateway "Configures EnvoyFilter for ExtProc attachment" "EnvoyFilter CR"

        # Plugin interactions
        extProcServer -> modelProviderResolver "Processes request through plugin pipeline" "in-process"
        extProcServer -> apiTranslation "Processes request through plugin pipeline" "in-process"
        extProcServer -> apikeyInjection "Processes request through plugin pipeline" "in-process"
        extProcServer -> nemoRequestGuard "Processes request (optional)" "in-process"
        extProcServer -> nemoResponseGuard "Processes response (optional)" "in-process"

        # External dependencies
        modelProviderResolver -> kubernetesAPI "Watches ExternalModel CRDs" "HTTPS/443, SA Bearer token"
        apikeyInjection -> kubernetesAPI "Watches labeled Secrets" "HTTPS/443, SA Bearer token"
        nemoRequestGuard -> nemoGuardrails "Input content policy check" "HTTP plaintext"
        nemoResponseGuard -> nemoGuardrails "Output content policy check" "HTTP plaintext"

        # Provider egress (via Envoy)
        envoyGateway -> openai "Proxies translated inference requests" "HTTPS/443, Bearer token"
        envoyGateway -> anthropic "Proxies translated inference requests" "HTTPS/443, x-api-key"
        envoyGateway -> azure "Proxies translated inference requests" "HTTPS/443, api-key"
        envoyGateway -> bedrock "Proxies translated inference requests" "HTTPS/443, Bearer token"
        envoyGateway -> vertex "Proxies translated inference requests" "HTTPS/443, Bearer token"

        # Internal ODH
        maasController -> kubernetesAPI "Creates ExternalModel CRs" "HTTPS/443"
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
            element "External Provider" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
