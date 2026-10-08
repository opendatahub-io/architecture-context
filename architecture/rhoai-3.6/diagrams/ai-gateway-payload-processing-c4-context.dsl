workspace {
    model {
        user = person "API Consumer" "Application or data scientist invoking LLM inference through the AI Gateway"
        operator = person "Platform Operator" "Configures ExternalModel and ExternalProvider CRDs, provisions credential Secrets"

        payloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext-proc filter and Kubernetes controller that routes, authenticates, and translates requests across external LLM providers" {
            extProcServer = container "ext-proc gRPC Server" "Envoy External Processing filter with plugin pipeline for provider resolution, API translation, credential injection, and guardrails" "Go gRPC Service"
            dynamicMetadata = container "dynamicmetadata Wrapper" "Intercepts ext-proc responses to inject Envoy DynamicMetadata via pseudo-headers" "Go gRPC Interceptor"
            externalProviderCtrl = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs to create Service, ServiceEntry, and DestinationRule" "Go Controller"
            externalModelCtrl = container "ExternalModel Controller" "Reconciles ExternalModel CRs to create HTTPRoute resources" "Go Controller"
            legacyMigrationCtrl = container "Legacy Migration Controller" "Converts maas.opendatahub.io CRs to inference.opendatahub.io CRs" "Go Controller"
        }

        envoyGateway = softwareSystem "AI Gateway (Envoy)" "Envoy proxy serving as the inference gateway with ext_proc filter" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing mTLS, ServiceEntry, and DestinationRule" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API providing HTTPRoute-based traffic routing" "Internal RHOAI"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content safety guardrail service" "Internal RHOAI"
        meteringService = softwareSystem "External Metering" "Balance checking and usage reporting service" "Internal RHOAI"
        kubernetes = softwareSystem "Kubernetes API" "Cluster API server for CRD and resource management" "Platform"

        openai = softwareSystem "OpenAI" "External LLM provider" "External"
        anthropic = softwareSystem "Anthropic" "External LLM provider" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "External LLM provider" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "External LLM provider" "External"
        gcpVertex = softwareSystem "GCP Vertex AI" "External LLM provider" "External"

        # Relationships
        user -> envoyGateway "Sends inference requests" "HTTPS/443"
        operator -> kubernetes "Creates ExternalModel, ExternalProvider CRDs" "kubectl / HTTPS"

        envoyGateway -> payloadProcessing "ext_proc callout per request" "gRPC/9004"
        payloadProcessing -> kubernetes "CRUD on CRDs, Services, HTTPRoutes, Secrets" "HTTPS/6443"
        payloadProcessing -> nemoGuardrails "Content guardrail checks" "HTTPS"
        payloadProcessing -> meteringService "Usage reporting" "HTTP"

        envoyGateway -> openai "Routes inference requests (after ext-proc)" "HTTPS/443"
        envoyGateway -> anthropic "Routes inference requests (after ext-proc)" "HTTPS/443"
        envoyGateway -> azureOpenAI "Routes inference requests (after ext-proc)" "HTTPS/443"
        envoyGateway -> awsBedrock "Routes inference requests (after ext-proc)" "HTTPS/443"
        envoyGateway -> gcpVertex "Routes inference requests (after ext-proc)" "HTTPS/443"

        payloadProcessing -> istio "Creates ServiceEntry + DestinationRule" "HTTPS/6443"
        payloadProcessing -> gatewayAPI "Creates HTTPRoute resources" "HTTPS/6443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
