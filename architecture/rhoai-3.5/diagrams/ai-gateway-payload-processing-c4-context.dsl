workspace {
    model {
        datascientist = person "Data Scientist / API Consumer" "Creates ExternalModel/ExternalProvider CRs and sends inference requests through the platform Gateway"

        platformAdmin = person "Platform Admin" "Configures provider credentials (Secrets) and deploys the payload processing service"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc service with pluggable IPP plugins for multi-provider LLM routing, API translation, credential injection, metering, and content guardrails" {
            extProcService = container "ext_proc Service" "Handles request/response mutations through plugin pipeline: maas-headers-guard → model-extractor → model-provider-resolver → stream-usage-enforcer → api-translation → apikey-injection" "Go gRPC Service (9004/TCP)"
            externalModelController = container "ExternalModel Controller" "Reconciles ExternalModel CRs to create HTTPRoute resources for per-model traffic routing" "Go controller-runtime"
            externalProviderController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs to create ExternalName Service, Istio ServiceEntry, and DestinationRule for TLS origination" "Go controller-runtime"
            legacyMigrationController = container "Legacy Migration Controller" "Watches maas.opendatahub.io ExternalModel CRs and creates corresponding inference.opendatahub.io resources" "Go controller-runtime"
            infoStore = container "infoStore" "In-memory model→provider mapping populated by controllers, read by plugins" "Go map (namespace/name keyed)"
            secretStore = container "secretStore" "In-memory credential cache populated by label-filtered Secret watches, read by apikey-injection plugin" "Go map (namespace/name keyed)"
        }

        platformGateway = softwareSystem "Platform Gateway (Envoy)" "maas-default-gateway — Envoy-based ingress gateway with ext_proc filter" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management via ServiceEntry and DestinationRule CRDs" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "CRD watches, Secret reads, resource CRUD" "Internal Platform"
        maasController = softwareSystem "maas-controller" "Reads ExternalModel status.httpRouteName to attach policies" "Internal Platform"

        openai = softwareSystem "OpenAI API" "api.openai.com — LLM inference (GPT models)" "External Provider"
        anthropic = softwareSystem "Anthropic API" "api.anthropic.com — LLM inference (Claude models)" "External Provider"
        bedrock = softwareSystem "AWS Bedrock" "bedrock-runtime.{region}.amazonaws.com — LLM inference" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI" "{region}-aiplatform.googleapis.com — LLM inference" "External Provider"
        meteringService = softwareSystem "Metering Service" "Token balance checks and usage event reporting (CloudEvents)" "Internal Platform"
        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "NVIDIA NeMo content guardrail checks (input/output rails)" "Internal Platform"

        datascientist -> platformGateway "Sends inference requests" "HTTPS/443"
        datascientist -> k8sAPI "Creates ExternalModel/ExternalProvider CRs" "kubectl"
        platformAdmin -> k8sAPI "Creates labeled Secrets with provider credentials" "kubectl"

        platformGateway -> aiGatewayPayloadProcessing "Invokes ext_proc filter for request/response mutations" "gRPC/9004 (Istio mTLS)"
        aiGatewayPayloadProcessing -> k8sAPI "Watches CRDs, reads Secrets, creates networking resources" "HTTPS/6443"
        aiGatewayPayloadProcessing -> istio "Creates ServiceEntry + DestinationRule for external provider routing" "CRD"
        aiGatewayPayloadProcessing -> openai "Routes inference requests" "HTTPS/443 (API Key)"
        aiGatewayPayloadProcessing -> anthropic "Routes inference requests" "HTTPS/443 (API Key)"
        aiGatewayPayloadProcessing -> bedrock "Routes inference requests" "HTTPS/443 (SigV4)"
        aiGatewayPayloadProcessing -> vertexAI "Routes inference requests" "HTTPS/443 (OAuth2)"
        aiGatewayPayloadProcessing -> meteringService "Balance checks and usage reporting" "HTTP"
        aiGatewayPayloadProcessing -> nemoGuardrails "Content guardrail checks" "HTTP"
        maasController -> aiGatewayPayloadProcessing "Reads ExternalModel status for policy attachment" "CRD status"
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
                background #f8cecc
                shape RoundedBox
            }
            element "Internal Platform" {
                background #d5e8d4
                shape RoundedBox
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
