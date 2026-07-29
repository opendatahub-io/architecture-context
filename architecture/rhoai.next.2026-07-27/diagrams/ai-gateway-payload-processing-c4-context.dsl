workspace {
    model {
        user = person "Data Scientist / Application Developer" "Creates ExternalModel and ExternalProvider resources to route inference requests to external LLM providers"

        aiGateway = softwareSystem "ai-gateway-payload-processing" "Kubernetes controller and Envoy ext_proc service that manages external LLM provider routing via ExternalModel and ExternalProvider CRDs with weighted multi-provider traffic splitting" {
            externalModelCtrl = container "ExternalModel Controller" "Reconciles ExternalModel CRs, creates HTTPRoute resources with weighted traffic splitting" "Go Controller"
            externalProviderCtrl = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs, creates Service, ServiceEntry, DestinationRule" "Go Controller"
            legacyMigrationCtrl = container "Legacy Migration Controller" "Migrates maas.opendatahub.io ExternalModel CRs to inference.opendatahub.io" "Go Controller"
            extProcService = container "ext_proc gRPC Service" "Processes Envoy requests: model-provider resolution, API format translation, credential injection" "Go gRPC Service"
        }

        envoyGateway = softwareSystem "Envoy / Gateway" "API Gateway with ext_proc filter for request processing" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing" "Internal Platform"
        llmdBBR = softwareSystem "llm-d-inference-payload-processor" "BBR runner framework for ext_proc services" "Internal Platform"

        openai = softwareSystem "OpenAI API" "OpenAI LLM inference service" "External Provider"
        anthropic = softwareSystem "Anthropic API" "Anthropic LLM inference service (Messages format)" "External Provider"
        azure = softwareSystem "Azure OpenAI" "Microsoft Azure-hosted OpenAI service" "External Provider"
        vertex = softwareSystem "Google Vertex AI" "Google Cloud Vertex AI inference service" "External Provider"

        user -> aiGateway "Creates ExternalModel/ExternalProvider CRs via kubectl"
        envoyGateway -> extProcService "ext_proc gRPC calls for request/response processing"
        externalModelCtrl -> k8sAPI "Watch ExternalModel CRs, create HTTPRoutes" "HTTPS/6443"
        externalProviderCtrl -> k8sAPI "Watch ExternalProvider CRs, create Service/ServiceEntry/DestinationRule" "HTTPS/6443"
        externalProviderCtrl -> k8sAPI "Read credential Secrets" "HTTPS/6443"
        legacyMigrationCtrl -> k8sAPI "Watch maas.opendatahub.io CRs, create inference.opendatahub.io CRs" "HTTPS/6443"
        aiGateway -> gatewayAPI "Creates HTTPRoute resources against configured Gateway"
        aiGateway -> llmdBBR "Uses BBR runner framework for ext_proc hosting"
        envoyGateway -> openai "Routes inference requests" "HTTPS + API Key"
        envoyGateway -> anthropic "Routes inference requests" "HTTPS + API Key"
        envoyGateway -> azure "Routes inference requests" "HTTPS + API Key/OAuth2"
        envoyGateway -> vertex "Routes inference requests" "HTTPS + OAuth2"
    }

    views {
        systemContext aiGateway "SystemContext" {
            include *
            autoLayout
        }

        container aiGateway "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Provider" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
