workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to external LLM providers via AI Gateway"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "BBR plugin host providing model resolution, API translation, credential injection, and guardrail enforcement for external LLM provider traffic" {
            bbrPluginHost = container "BBR Plugin Host" "Envoy ext_proc filter hosting the plugin pipeline for request/response mutation" "Go Service"
            modelProviderResolver = container "model-provider-resolver" "Resolves model names to provider info via ExternalModel CRD watch" "BBR RequestProcessor Plugin"
            apiTranslation = container "api-translation" "Translates between OpenAI Chat Completions and provider-native API formats" "BBR Request+Response Processor Plugin"
            apikeyInjection = container "apikey-injection" "Injects provider API keys from Kubernetes Secrets into request headers" "BBR RequestProcessor Plugin"
            nemoGuards = container "NeMo Guards" "Enforces content safety guardrails via NeMo Guardrails API" "BBR Request+Response Processor Plugins"
            externalModelController = container "ExternalModel Controller" "Reconciles ExternalModel CRs → creates HTTPRoutes for model routing" "Go Controller (controller-runtime)"
            externalProviderController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs → creates Service, ServiceEntry, DestinationRule" "Go Controller (controller-runtime)"
        }

        istioGateway = softwareSystem "Istio Gateway (Envoy)" "Service mesh ingress gateway with EnvoyFilter for ext_proc attachment" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "API server for CR watches and resource creation" "External"
        maasController = softwareSystem "MaaS Controller" "Models-as-a-Service controller providing ExternalModel CRDs (maas.opendatahub.io)" "Internal RHOAI"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "NVIDIA NeMo content safety guardrail service" "External (Optional)"
        kuadrant = softwareSystem "Kuadrant" "API management with WASM plugin (EnvoyFilter anchor)" "Internal RHOAI (Optional)"

        openai = softwareSystem "OpenAI API" "External LLM provider - api.openai.com" "External Provider"
        anthropic = softwareSystem "Anthropic API" "External LLM provider - api.anthropic.com" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI API" "External LLM provider - *.openai.azure.com" "External Provider"
        bedrock = softwareSystem "AWS Bedrock API" "External LLM provider - bedrock.amazonaws.com" "External Provider"
        vertexAI = softwareSystem "Vertex AI API" "External LLM provider - *-aiplatform.googleapis.com" "External Provider"

        user -> istioGateway "Sends inference requests" "HTTPS/443"
        istioGateway -> bbrPluginHost "Forwards request/response bodies via ext_proc" "gRPC/9004"
        bbrPluginHost -> modelProviderResolver "Resolves model → provider"
        bbrPluginHost -> apiTranslation "Translates API format"
        bbrPluginHost -> apikeyInjection "Injects credentials"
        bbrPluginHost -> nemoGuards "Enforces guardrails"

        modelProviderResolver -> k8sAPI "Watches MaaS ExternalModel CRDs" "HTTPS/443"
        apikeyInjection -> k8sAPI "Watches labeled Secrets" "HTTPS/443"
        nemoGuards -> nemoGuardrails "Content safety checks" "HTTP POST"
        externalModelController -> k8sAPI "Watches ExternalModel CRs, creates HTTPRoutes" "HTTPS/443"
        externalProviderController -> k8sAPI "Watches ExternalProvider CRs, creates Service/ServiceEntry/DestinationRule" "HTTPS/443"

        istioGateway -> openai "Routes translated inference requests" "HTTPS/443"
        istioGateway -> anthropic "Routes translated inference requests" "HTTPS/443"
        istioGateway -> azureOpenAI "Routes translated inference requests" "HTTPS/443"
        istioGateway -> bedrock "Routes translated inference requests" "HTTPS/443"
        istioGateway -> vertexAI "Routes translated inference requests" "HTTPS/443"

        maasController -> k8sAPI "Creates ExternalModel CRDs (maas.opendatahub.io)" "HTTPS/443"
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
                background #f8cecc
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI (Optional)" {
                background #a8d86e
                color #333333
            }
            element "External (Optional)" {
                background #bbbbbb
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
                shape Person
            }
        }
    }
}
