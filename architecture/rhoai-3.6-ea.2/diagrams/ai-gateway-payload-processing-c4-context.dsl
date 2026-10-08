workspace {
    model {
        client = person "API Client" "Sends inference requests to AI Gateway"
        platformAdmin = person "Platform Admin" "Configures ExternalModel and ExternalProvider CRs"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy External Processor for AI Gateway inference traffic — resolves models to providers, translates APIs, injects credentials, enforces guardrails" {
            extProcServer = container "ext-proc gRPC Server" "IPP plugin pipeline processing inference request/response headers and bodies" "Go gRPC Service" "9004/TCP"
            dynamicMetadataWrapper = container "DynamicMetadata Wrapper" "Converts pseudo-header metadata into Envoy ProcessingResponse.DynamicMetadata" "gRPC Interceptor"
            modelProviderResolver = container "model-provider-resolver Plugin" "Watches CRDs, resolves model names to provider info, sets routing headers" "IPP Plugin"
            apiTranslation = container "api-translation Plugin" "Translates between OpenAI, Anthropic, and other API formats" "IPP Plugin"
            apikeyInjection = container "apikey-injection Plugin" "Reads Secrets and injects Authorization headers" "IPP Plugin"
            nemoGuard = container "NeMo Guard Plugins" "Enforces NVIDIA NeMo guardrails on request/response content" "IPP Plugin"
            externalModelController = container "ExternalModel Controller" "Reconciles ExternalModel CRs into HTTPRoutes" "Kubernetes Controller"
            externalProviderController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs into Services, ServiceEntries, DestinationRules" "Kubernetes Controller"
            legacyMigrationController = container "Legacy Migration Controller" "Migrates maas.opendatahub.io CRs to inference.opendatahub.io" "Kubernetes Controller"
        }

        envoyGateway = softwareSystem "AI Gateway (Envoy)" "Envoy-based gateway that routes inference traffic via HTTPRoutes" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "API server for CRD watches, Secret reads, resource CRUD" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides ServiceEntry and DestinationRule for external endpoint reachability" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic routing" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "NVIDIA content moderation service" "External"

        openai = softwareSystem "OpenAI" "External LLM provider" "External Provider"
        anthropic = softwareSystem "Anthropic" "External LLM provider" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "External LLM provider" "External Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "External LLM provider" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI" "External LLM provider" "External Provider"

        ippFramework = softwareSystem "llm-d-inference-payload-processor" "Upstream IPP framework: server skeleton, plugin lifecycle, CycleState" "Internal Library"

        # Relationships
        client -> envoyGateway "Sends inference requests" "HTTPS"
        platformAdmin -> kubernetesAPI "Creates ExternalModel/ExternalProvider CRs" "kubectl"

        envoyGateway -> aiGatewayPayloadProcessing "gRPC ExtProc callout" "gRPC/9004"
        aiGatewayPayloadProcessing -> kubernetesAPI "Watches CRDs, reads Secrets, manages resources" "HTTPS/6443"
        aiGatewayPayloadProcessing -> nemoGuardrails "Content moderation checks" "HTTPS"

        externalModelController -> gatewayAPI "Creates HTTPRoutes" "HTTPS/6443"
        externalProviderController -> istio "Creates ServiceEntries, DestinationRules" "HTTPS/6443"

        envoyGateway -> openai "Forwards inference requests" "HTTPS/443 API key"
        envoyGateway -> anthropic "Forwards inference requests" "HTTPS/443 API key"
        envoyGateway -> azureOpenAI "Forwards inference requests" "HTTPS/443 API key"
        envoyGateway -> awsBedrock "Forwards inference requests" "HTTPS/443 SigV4"
        envoyGateway -> vertexAI "Forwards inference requests" "HTTPS/443 OAuth2"

        aiGatewayPayloadProcessing -> ippFramework "Uses server skeleton and plugin framework" "Go library"
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
                background #4a90e2
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
            element "Internal Library" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
