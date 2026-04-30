workspace {
    model {
        user = person "Application Developer" "Sends inference requests via OpenAI-compatible API"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Pluggable BBR ext_proc service for payload-level mutations on AI inference requests/responses" {
            extProcServer = container "ext_proc gRPC Server" "Hosts BBR plugin chain, receives request/response bodies from Envoy" "Go Service, 9004/TCP"
            modelProviderResolver = container "model-provider-resolver" "Watches ExternalModel CRDs, resolves model name to provider via in-memory store" "BBR Plugin"
            apiTranslation = container "api-translation" "Translates request/response bodies between OpenAI and provider-native formats" "BBR Plugin"
            apikeyInjection = container "apikey-injection" "Watches labeled Secrets, injects provider-specific auth headers" "BBR Plugin"
            nemoRequestGuard = container "nemo-request-guard" "Evaluates input content against NeMo guardrails" "BBR Plugin"
            nemoResponseGuard = container "nemo-response-guard" "Evaluates output content against NeMo guardrails" "BBR Plugin"
            modelInfoStore = container "modelInfoStore" "In-memory cache of ExternalModel CRD data" "Go RWMutex Map"
            secretStore = container "secretStore" "In-memory cache of API keys from Kubernetes Secrets" "Go RWMutex Map"
        }

        istioGateway = softwareSystem "Istio Gateway" "Service mesh gateway with Envoy proxy for traffic routing and TLS termination" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD and Secret management" "External"
        maas = softwareSystem "Models-as-a-Service (MaaS)" "Provides ExternalModel CRDs defining model-to-provider mappings" "Internal RHOAI"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content safety guardrails for input/output filtering" "Optional External"

        openAI = softwareSystem "OpenAI API" "Cloud inference provider" "External Provider"
        anthropic = softwareSystem "Anthropic API" "Cloud inference provider" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI Service" "Cloud inference provider" "External Provider"
        bedrock = softwareSystem "AWS Bedrock" "Cloud inference provider" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI" "Cloud inference provider" "External Provider"

        # System context relationships
        user -> istioGateway "Sends inference requests" "HTTPS/443"
        istioGateway -> aiGatewayPayloadProcessing "Routes request/response bodies via ext_proc filter" "gRPC/9004 plaintext"
        aiGatewayPayloadProcessing -> k8sAPI "Watches ExternalModel CRDs and labeled Secrets" "HTTPS/443, SA token"
        aiGatewayPayloadProcessing -> nemoGuardrails "Content safety checks" "HTTP POST /v1/guardrail/checks"
        maas -> k8sAPI "Creates ExternalModel CRDs" "HTTPS/443"
        istioGateway -> openAI "Forwards translated requests" "HTTPS/443, Bearer token"
        istioGateway -> anthropic "Forwards translated requests" "HTTPS/443, x-api-key"
        istioGateway -> azureOpenAI "Forwards translated requests" "HTTPS/443, api-key"
        istioGateway -> bedrock "Forwards translated requests" "HTTPS/443, Bearer token"
        istioGateway -> vertexAI "Forwards translated requests" "HTTPS/443, Bearer token"

        # Container relationships
        extProcServer -> modelProviderResolver "Invokes plugin chain" "CycleState"
        modelProviderResolver -> apiTranslation "Passes provider info" "CycleState"
        apiTranslation -> apikeyInjection "Passes translated body" "CycleState"
        modelProviderResolver -> modelInfoStore "Reads model-provider mapping" "in-process"
        apikeyInjection -> secretStore "Reads API keys" "in-process"
        nemoRequestGuard -> nemoGuardrails "Input guardrail check" "HTTP POST"
        nemoResponseGuard -> nemoGuardrails "Output guardrail check" "HTTP POST"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Provider" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Optional External" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
