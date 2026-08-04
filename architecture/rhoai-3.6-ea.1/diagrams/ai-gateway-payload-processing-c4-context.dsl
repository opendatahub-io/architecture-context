workspace {
    model {
        user = person "Platform Engineer" "Configures external LLM provider connections and model routing"
        dataScientist = person "Data Scientist" "Sends inference requests through the AI Gateway"

        aiGatewayPayloadProcessing = softwareSystem "ai-gateway-payload-processing" "Kubernetes operator that bridges external LLM provider APIs into the RHOAI AI Gateway by reconciling ExternalProvider and ExternalModel CRDs" {
            epController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs into ExternalName Service, Istio ServiceEntry, and DestinationRule" "Go / controller-runtime"
            emController = container "ExternalModel Controller" "Reconciles ExternalModel CRs into Gateway API HTTPRoute resources with path-prefix routing" "Go / controller-runtime"
            legacyController = container "Legacy Migration Controller" "Optionally watches maas.opendatahub.io ExternalModel CRs for migration" "Go / controller-runtime"
            pluginChain = container "Payload Processor Plugin Chain" "Runtime pipeline: model-provider-resolver, API translation, credential injection" "Go / llm-d library"
        }

        openai = softwareSystem "OpenAI API" "External LLM inference service" "External"
        anthropic = softwareSystem "Anthropic API" "External LLM inference service" "External"
        bedrock = softwareSystem "AWS Bedrock" "External LLM inference service" "External"
        azure = softwareSystem "Azure OpenAI" "External LLM inference service" "External"
        vertexai = softwareSystem "Google Vertex AI" "External LLM inference service" "External"

        istio = softwareSystem "Istio Service Mesh" "Manages egress traffic routing, mTLS, and TLS origination" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing" "External"
        k8s = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"

        user -> aiGatewayPayloadProcessing "Creates ExternalProvider and ExternalModel CRs" "kubectl / API"
        dataScientist -> aiGatewayPayloadProcessing "Sends inference requests" "HTTPS/443"

        aiGatewayPayloadProcessing -> openai "Routes inference requests" "HTTPS/443, API Key"
        aiGatewayPayloadProcessing -> anthropic "Routes inference requests" "HTTPS/443, API Key"
        aiGatewayPayloadProcessing -> bedrock "Routes inference requests" "HTTPS/443, SigV4"
        aiGatewayPayloadProcessing -> azure "Routes inference requests" "HTTPS/443, API Key/OAuth2"
        aiGatewayPayloadProcessing -> vertexai "Routes inference requests" "HTTPS/443, OAuth2"

        aiGatewayPayloadProcessing -> istio "Creates ServiceEntry and DestinationRule for egress" "Kubernetes API"
        aiGatewayPayloadProcessing -> gatewayAPI "Creates HTTPRoute for model routing" "Kubernetes API"
        aiGatewayPayloadProcessing -> k8s "Watches CRDs, manages Services and Secrets" "HTTPS/6443"

        epController -> k8s "CRUD: Service, ServiceEntry, DestinationRule" "HTTPS/6443"
        emController -> k8s "CRUD: HTTPRoute" "HTTPS/6443"
        pluginChain -> k8s "Reads Secrets for credential injection" "HTTPS/6443"
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
