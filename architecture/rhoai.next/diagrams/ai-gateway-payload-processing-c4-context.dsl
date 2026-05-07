workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and invokes ML models via unified API"
        platformAdmin = person "Platform Admin" "Configures ExternalModel/ExternalProvider CRDs and API key Secrets"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "BBR ExtProc plugin host that resolves models, translates APIs, injects credentials, and enforces guardrails for inference requests" {
            extProcServer = container "ExtProc Server" "gRPC server receiving request/response bodies from Envoy for mutation" "Go gRPC Service" "9004/TCP"
            modelProviderResolver = container "model-provider-resolver Plugin" "Watches ExternalModel CRDs, resolves model names to provider info via CycleState" "Go BBR Plugin"
            apiTranslation = container "api-translation Plugin" "Translates between OpenAI Chat Completions and provider-native formats (Anthropic, Azure, Bedrock, Vertex)" "Go BBR Plugin"
            apikeyInjection = container "apikey-injection Plugin" "Watches labeled Secrets, injects provider-specific auth headers into requests" "Go BBR Plugin"
            nemoRequestGuard = container "nemo-request-guard Plugin" "Calls NeMo Guardrails to enforce input content policies" "Go BBR Plugin"
            nemoResponseGuard = container "nemo-response-guard Plugin" "Calls NeMo Guardrails to enforce output content policies" "Go BBR Plugin"
            modelInfoStore = container "modelInfoStore" "In-memory model→provider mapping cache (RWMutex)" "Go In-Memory Store"
            secretStore = container "secretStore" "In-memory API key credential cache (RWMutex)" "Go In-Memory Store"
            healthCheck = container "Health Check" "Liveness/readiness probe endpoint" "HTTP Service" "9005/TCP"
        }

        gatewayAPI = softwareSystem "Gateway API (Envoy)" "Kubernetes Gateway API with Envoy proxy handling TLS termination and traffic routing" "External"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter attachment for ExtProc integration" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Control plane for CRD watches and Secret access" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "Content moderation service for input/output policy enforcement" "Internal RHOAI"
        maasController = softwareSystem "MaaS Controller" "Creates ExternalModel CRs for managed model deployments" "Internal RHOAI"

        openai = softwareSystem "OpenAI API" "External LLM inference provider (api.openai.com)" "External Provider"
        anthropic = softwareSystem "Anthropic API" "External LLM inference provider (api.anthropic.com)" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI API" "External LLM inference provider" "External Provider"
        bedrock = softwareSystem "AWS Bedrock API" "External LLM inference provider (bedrock.amazonaws.com)" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI API" "External LLM inference provider (aiplatform.googleapis.com)" "External Provider"

        # User interactions
        dataScientist -> gatewayAPI "Sends inference requests via unified OpenAI API" "HTTPS/443"
        platformAdmin -> kubernetesAPI "Creates ExternalModel, ExternalProvider CRDs and API key Secrets" "kubectl/HTTPS"

        # Gateway ↔ Payload Processing
        gatewayAPI -> aiGatewayPayloadProcessing "Sends request/response bodies for mutation" "gRPC ExtProc/9004 plaintext"
        istio -> gatewayAPI "Attaches EnvoyFilter to insert ExtProc into pipeline" "EnvoyFilter CR"

        # Payload Processing → K8s API
        aiGatewayPayloadProcessing -> kubernetesAPI "Watches ExternalModel CRDs and labeled Secrets" "HTTPS/443 SA Bearer token"

        # Payload Processing → NeMo
        aiGatewayPayloadProcessing -> nemoGuardrails "Content policy checks" "HTTP plaintext"

        # MaaS → CRDs
        maasController -> kubernetesAPI "Creates ExternalModel CRs" "HTTPS/443"

        # Gateway → External Providers (after mutation)
        gatewayAPI -> openai "Proxies translated inference requests" "HTTPS/443 Bearer token"
        gatewayAPI -> anthropic "Proxies translated inference requests" "HTTPS/443 x-api-key"
        gatewayAPI -> azureOpenAI "Proxies translated inference requests" "HTTPS/443 api-key"
        gatewayAPI -> bedrock "Proxies translated inference requests" "HTTPS/443 Bearer token"
        gatewayAPI -> vertexAI "Proxies translated inference requests" "HTTPS/443 Bearer token"

        # Internal container relationships
        extProcServer -> modelProviderResolver "ProcessRequest()" "in-process"
        extProcServer -> apiTranslation "ProcessRequest/Response()" "in-process"
        extProcServer -> apikeyInjection "ProcessRequest()" "in-process"
        extProcServer -> nemoRequestGuard "ProcessRequest() (optional)" "in-process"
        extProcServer -> nemoResponseGuard "ProcessResponse() (optional)" "in-process"
        modelProviderResolver -> modelInfoStore "Read model→provider mapping" "in-memory"
        apikeyInjection -> secretStore "Read API key credentials" "in-memory"
        modelProviderResolver -> kubernetesAPI "Watch ExternalModel CRs" "HTTPS/443"
        apikeyInjection -> kubernetesAPI "Watch labeled Secrets" "HTTPS/443"
        nemoRequestGuard -> nemoGuardrails "POST /v1/guardrail/checks" "HTTP plaintext"
        nemoResponseGuard -> nemoGuardrails "POST /v1/guardrail/checks" "HTTP plaintext"
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
                background #e57373
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #64b5f6
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
