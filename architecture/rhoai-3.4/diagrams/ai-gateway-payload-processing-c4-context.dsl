workspace {
    model {
        user = person "API Consumer" "Sends inference requests using OpenAI Chat Completions API format"
        platformAdmin = person "Platform Admin" "Configures ExternalModel CRDs and provider API key Secrets"

        payloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc service providing multi-provider API translation, credential injection, and content safety enforcement for the AI Gateway" {
            bbrRuntime = container "BBR Runtime" "Body Based Routing ext_proc gRPC server executing plugin chain" "Go Service (ext_proc)" "9004/TCP gRPC"
            healthEndpoint = container "Health Endpoint" "Liveness/readiness probe endpoint" "Go HTTP" "9005/TCP HTTP"

            modelProviderResolver = component "model-provider-resolver" "Watches ExternalModel CRDs, resolves model names to provider metadata" "BBR Plugin (RequestProcessor)"
            apiTranslation = component "api-translation" "Translates between OpenAI and provider-native formats (Anthropic, Azure, Vertex, Bedrock)" "BBR Plugin (Request+ResponseProcessor)"
            apikeyInjection = component "apikey-injection" "Reconciles labeled Secrets, injects provider-specific auth headers" "BBR Plugin (RequestProcessor)"
            nemoRequestGuard = component "nemo-request-guard" "Calls NeMo Guardrails for content safety enforcement" "BBR Plugin (RequestProcessor)"
        }

        envoyGateway = softwareSystem "Envoy Gateway (Istio)" "Service mesh gateway with ext_proc filter attachment" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD and Secret access" "External"
        maasController = softwareSystem "MaaS Controller" "Creates and manages ExternalModel CRDs for model-as-a-service" "Internal RHOAI"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "NVIDIA content safety evaluation service" "External (Optional)"

        openai = softwareSystem "OpenAI API" "OpenAI inference endpoint" "External Provider"
        anthropic = softwareSystem "Anthropic API" "Anthropic Messages API inference endpoint" "External Provider"
        azure = softwareSystem "Azure OpenAI API" "Azure-hosted OpenAI inference endpoint" "External Provider"
        vertex = softwareSystem "Google Vertex AI" "Google Cloud AI Platform inference endpoint" "External Provider"
        bedrock = softwareSystem "AWS Bedrock" "AWS managed model inference endpoint" "External Provider"

        # Relationships
        user -> envoyGateway "Sends POST /v1/chat/completions" "HTTPS/443, TLS 1.2+"
        platformAdmin -> k8sAPI "Creates ExternalModel CRDs and API key Secrets" "kubectl/HTTPS"

        envoyGateway -> payloadProcessing "Sends request/response bodies via ext_proc" "gRPC/9004, mTLS (Istio)"
        payloadProcessing -> envoyGateway "Returns mutated headers and body" "gRPC/9004, mTLS (Istio)"

        payloadProcessing -> k8sAPI "Watches ExternalModel CRDs and labeled Secrets" "HTTPS/443, TLS 1.2+, SA Token"
        payloadProcessing -> nemoGuardrails "Sends content safety check" "HTTP POST /v1/guardrail/checks"

        maasController -> k8sAPI "Creates ExternalModel CRDs" "HTTPS/443"

        envoyGateway -> openai "Forwards translated request" "HTTPS/443, Bearer"
        envoyGateway -> anthropic "Forwards translated request" "HTTPS/443, x-api-key"
        envoyGateway -> azure "Forwards translated request" "HTTPS/443, api-key"
        envoyGateway -> vertex "Forwards translated request" "HTTPS/443, Bearer"
        envoyGateway -> bedrock "Forwards translated request" "HTTPS/443, Bearer"
    }

    views {
        systemContext payloadProcessing "SystemContext" {
            include *
            autoLayout
        }

        container payloadProcessing "Containers" {
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External (Optional)" {
                background #cc6699
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #6baed6
                color #ffffff
            }
        }
    }
}
