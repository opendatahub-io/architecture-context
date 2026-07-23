workspace {
    model {
        user = person "API Consumer" "Application or data scientist sending inference requests to external LLM models"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc service with pluggable IPP pipeline for request/response mutation, API translation, credential injection, and multi-provider routing" {
            extProcService = container "ext_proc Service" "gRPC server receiving Envoy external processing callbacks" "Go / llm-d IPP Framework" "9004/TCP"
            pluginPipeline = container "IPP Plugin Pipeline" "Ordered chain: maas-headers-guard → model-provider-resolver → stream-usage-enforcer → api-translation → apikey-injection" "Go Plugins"
            externalProviderCtrl = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs: creates Service, ServiceEntry, DestinationRule per provider" "Go / controller-runtime"
            externalModelCtrl = container "ExternalModel Controller" "Reconciles ExternalModel CRs: creates HTTPRoute per model with weighted provider routing" "Go / controller-runtime"
            legacyMigrationCtrl = container "Legacy Migration Controller" "Migrates maas.opendatahub.io ExternalModel CRs to inference.opendatahub.io resources" "Go / controller-runtime"
            infoStore = container "infoStore" "In-memory model/provider cache populated by controller reconcilers" "Go sync.Map"
            secretStore = container "secretStore" "In-memory credential cache from labeled Kubernetes Secrets" "Go sync.Map"
        }

        aiGateway = softwareSystem "AI Gateway" "Istio Gateway + Envoy data plane that routes inference traffic" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, ServiceEntry, DestinationRule for TLS origination" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches and resource management" "External"
        maasController = softwareSystem "maas-controller" "Reads ExternalModel status to attach gateway policies" "Internal RHOAI"

        openai = softwareSystem "OpenAI API" "External LLM inference provider" "External Provider"
        anthropic = softwareSystem "Anthropic API" "External LLM inference provider" "External Provider"
        bedrock = softwareSystem "AWS Bedrock" "External LLM inference provider (SigV4 auth)" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI" "External LLM inference provider (OAuth2 auth)" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "External LLM inference provider" "External Provider"

        meteringService = softwareSystem "External Metering Service" "Token balance enforcement and usage tracking" "Optional External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content safety evaluation for input/output rails" "Optional External"

        # Relationships
        user -> aiGateway "Sends inference requests" "HTTPS/443"
        aiGateway -> aiGatewayPayloadProcessing "Forwards via ext_proc filter" "gRPC/9004 (Istio mTLS)"
        aiGatewayPayloadProcessing -> aiGateway "Returns mutated headers/body" "gRPC/9004"

        aiGatewayPayloadProcessing -> k8sAPI "Watches CRDs, creates resources" "HTTPS/443 (SA Token)"
        aiGatewayPayloadProcessing -> istio "Creates ServiceEntry + DestinationRule" "Kubernetes API"
        aiGatewayPayloadProcessing -> gatewayAPI "Creates HTTPRoute per ExternalModel" "Kubernetes API"
        maasController -> aiGatewayPayloadProcessing "Reads ExternalModel.status" "Kubernetes API"

        aiGateway -> openai "Forwards translated inference request" "HTTPS/443 (API Key)"
        aiGateway -> anthropic "Forwards translated inference request" "HTTPS/443 (API Key)"
        aiGateway -> bedrock "Forwards translated inference request" "HTTPS/443 (SigV4)"
        aiGateway -> vertexAI "Forwards translated inference request" "HTTPS/443 (OAuth2)"
        aiGateway -> azureOpenAI "Forwards translated inference request" "HTTPS/443 (API Key)"

        aiGatewayPayloadProcessing -> meteringService "Balance check + usage report" "HTTP/HTTPS"
        aiGatewayPayloadProcessing -> nemoGuardrails "Content safety evaluation" "HTTP/HTTPS"

        # Internal container relationships
        extProcService -> pluginPipeline "Invokes plugin chain per request"
        pluginPipeline -> infoStore "Reads model/provider data"
        pluginPipeline -> secretStore "Reads credentials"
        externalProviderCtrl -> infoStore "Populates provider data"
        externalModelCtrl -> infoStore "Populates model data"
        externalProviderCtrl -> k8sAPI "Creates Service, ServiceEntry, DestinationRule"
        externalModelCtrl -> k8sAPI "Creates HTTPRoute"
        legacyMigrationCtrl -> k8sAPI "Creates new-API CRs from legacy CRs"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Provider" {
                background #f5a623
                color #ffffff
            }
            element "Optional External" {
                background #e1d5e7
                color #333333
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
