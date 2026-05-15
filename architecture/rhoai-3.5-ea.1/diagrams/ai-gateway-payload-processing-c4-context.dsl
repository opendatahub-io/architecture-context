workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Sends inference requests to models via a unified OpenAI-compatible API"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "BBR ext-proc plugins for request/response mutation, API translation, auth injection, and content moderation for external LLM providers" {
            bbrPluginService = container "BBR Plugin Service" "Runs 5 BBR plugins as a gRPC ext-proc server: model resolution, API translation, API key injection, NeMo request/response guards" "Go Service (ext-proc)" "9004/TCP gRPC, 9005/TCP health"
            externalModelController = container "ExternalModel Controller" "Watches ExternalModel CRDs and creates Gateway API HTTPRoutes for inference routing" "Go Controller (controller-runtime)"
            externalProviderController = container "ExternalProvider Controller" "Watches ExternalProvider CRDs and creates Service (ExternalName), Istio ServiceEntry, and DestinationRule for TLS origination" "Go Controller (controller-runtime)"
        }

        gateway = softwareSystem "Gateway (Envoy)" "Kubernetes Gateway API-based inference gateway with ext-proc filter for BBR processing" "Infrastructure"
        istio = softwareSystem "Istio" "Service mesh providing ServiceEntry, DestinationRule for TLS origination, and EnvoyFilter for ext-proc attachment" "Infrastructure"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "HTTPRoute and Gateway CRDs for inference request routing" "Infrastructure"
        bbrFramework = softwareSystem "Gateway API Inference Extension (BBR)" "Upstream body-based routing framework providing plugin lifecycle and ext-proc server" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "API server for CRD watches, Secret access, and resource management" "Infrastructure"

        nemoGuardrails = softwareSystem "NeMo Guardrails" "NVIDIA content moderation service for input/output rails validation" "External"

        openai = softwareSystem "OpenAI API" "External LLM provider" "External"
        anthropic = softwareSystem "Anthropic API" "External LLM provider" "External"
        azureOpenAI = softwareSystem "Azure OpenAI API" "External LLM provider" "External"
        awsBedrock = softwareSystem "AWS Bedrock API" "External LLM provider" "External"
        vertexAI = softwareSystem "Google Vertex AI API" "External LLM provider" "External"

        datascientist -> gateway "Sends inference requests (HTTPS/443)"
        gateway -> aiGatewayPayloadProcessing "Forwards via ext-proc filter (gRPC/9004)"

        bbrPluginService -> k8sAPI "Watches ExternalModel CRs and Secrets (HTTPS/443)"
        bbrPluginService -> nemoGuardrails "Content moderation checks (HTTP)"
        externalModelController -> k8sAPI "Watches ExternalModel CRs, creates HTTPRoutes (HTTPS/443)"
        externalProviderController -> k8sAPI "Watches ExternalProvider CRs, creates Services/ServiceEntries/DestinationRules (HTTPS/443)"

        gateway -> openai "Routes inference requests (HTTPS/443, TLS origination via Istio)"
        gateway -> anthropic "Routes inference requests (HTTPS/443, TLS origination via Istio)"
        gateway -> azureOpenAI "Routes inference requests (HTTPS/443, TLS origination via Istio)"
        gateway -> awsBedrock "Routes inference requests (HTTPS/443, TLS origination via Istio)"
        gateway -> vertexAI "Routes inference requests (HTTPS/443, TLS origination via Istio)"

        aiGatewayPayloadProcessing -> istio "Creates ServiceEntry, DestinationRule for external provider TLS origination"
        aiGatewayPayloadProcessing -> gatewayAPI "Creates HTTPRoutes for model routing"
        aiGatewayPayloadProcessing -> bbrFramework "Uses as plugin framework (Go library)"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
