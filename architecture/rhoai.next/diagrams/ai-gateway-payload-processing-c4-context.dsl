workspace {
    model {
        user = person "Data Scientist / Developer" "Creates ExternalModel and ExternalProvider CRs to route inference requests to external LLM providers"

        agpp = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc filter and Kubernetes controller that routes, translates, authenticates, and meters inference requests to external LLM providers via the AI Gateway" {
            extProcServer = container "ext_proc gRPC Server" "Envoy external processing filter endpoint" "Go Service" "9004/TCP gRPC"
            pluginPipeline = container "Plugin Pipeline" "Chained plugins: maas-headers-guard, model-provider-resolver, stream-usage-enforcer, api-translation, apikey-injection" "IPP Framework"
            externalModelController = container "ExternalModel Controller" "Watches ExternalModel CRs, creates HTTPRoute resources for Gateway API routing" "Go Controller (controller-runtime)"
            externalProviderController = container "ExternalProvider Controller" "Watches ExternalProvider CRs, creates Service/ServiceEntry/DestinationRule for Istio mesh routing" "Go Controller (controller-runtime)"
            legacyMigrationController = container "Legacy Migration Controller" "Migrates maas.opendatahub.io/v1alpha1 CRDs to inference.opendatahub.io/v1alpha1" "Go Controller"
        }

        istioGateway = softwareSystem "Istio Gateway (Envoy)" "Service mesh gateway with EnvoyFilter attachment for ext_proc" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD watch, resource creation, and Secret access" "External"
        ippFramework = softwareSystem "llm-d IPP Framework" "Inference Payload Processor providing ext_proc server, plugin lifecycle, CycleState, and runner" "External"

        openai = softwareSystem "OpenAI API" "Chat Completions API (api.openai.com)" "External LLM Provider"
        anthropic = softwareSystem "Anthropic API" "Messages API (api.anthropic.com)" "External LLM Provider"
        azure = softwareSystem "Azure OpenAI API" "Azure-hosted OpenAI inference ({resource}.openai.azure.com)" "External LLM Provider"
        vertex = softwareSystem "Vertex AI API" "Gemini GenerateContent and OpenAI-compat ({region}-aiplatform.googleapis.com)" "External LLM Provider"
        bedrock = softwareSystem "AWS Bedrock API" "Bedrock InvokeModel OpenAI-compat (bedrock-runtime.{region}.amazonaws.com)" "External LLM Provider"

        meteringService = softwareSystem "External Metering Service" "Token budget enforcement and CloudEvents usage reporting" "Internal"
        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "Content safety filtering — input and output rails" "Internal"

        user -> agpp "Creates ExternalModel/ExternalProvider CRs via kubectl"
        istioGateway -> agpp "Sends inference requests via ext_proc gRPC/9004" "gRPC"
        agpp -> k8sAPI "Watches CRDs, creates HTTPRoutes/Services/ServiceEntries/DestinationRules, reads Secrets" "HTTPS/443"
        agpp -> openai "Routes translated inference requests" "HTTPS/443, Bearer Token"
        agpp -> anthropic "Routes translated inference requests" "HTTPS/443, x-api-key"
        agpp -> azure "Routes translated inference requests" "HTTPS/443, api-key header"
        agpp -> vertex "Routes translated inference requests" "HTTPS/443, OAuth2 Bearer"
        agpp -> bedrock "Routes translated inference requests" "HTTPS/443, AWS SigV4"
        agpp -> meteringService "Budget check (GET) and usage events (POST)" "HTTP/HTTPS"
        agpp -> nemoGuardrails "Content filtering (input/output rails)" "HTTP/HTTPS"
        agpp -> ippFramework "Uses as Go module dependency for ext_proc server and plugin framework" "Go import"
    }

    views {
        systemContext agpp "SystemContext" {
            include *
            autoLayout
        }

        container agpp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External LLM Provider" {
                background #f5a623
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
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
