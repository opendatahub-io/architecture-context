workspace {
    model {
        admin = person "Platform Admin" "Configures external AI provider routing via CRDs"
        user = person "Data Scientist" "Sends inference requests to external AI models"

        aiGateway = softwareSystem "ai-gateway-payload-processing" "Kubernetes operator managing external AI provider routing via Gateway API and Istio" {
            epController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs into Istio ServiceEntries, DestinationRules, and ExternalName Services" "Go controller-runtime"
            emController = container "ExternalModel Controller" "Reconciles ExternalModel CRs into Gateway API HTTPRoutes for model-to-provider routing" "Go controller-runtime"
            pluginRunner = container "Payload Processor Runner" "llm-d-inference-payload-processor framework with plugin-based request processing pipeline" "Go"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and TLS origination" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing (maas-default-gateway in openshift-ingress)" "Infrastructure"

        openai = softwareSystem "OpenAI API" "External AI inference provider" "External"
        anthropic = softwareSystem "Anthropic API" "External AI inference provider" "External"
        azure = softwareSystem "Azure OpenAI" "External AI inference provider" "External"
        vertexAI = softwareSystem "Vertex AI" "External AI inference provider" "External"

        admin -> aiGateway "Creates ExternalProvider and ExternalModel CRs via kubectl"
        user -> gatewayAPI "Sends inference requests"

        aiGateway -> k8sAPI "Watches/CRUD on CRDs, Services, Secrets, HTTPRoutes, ServiceEntries, DestinationRules" "HTTPS/6443"
        aiGateway -> istio "Creates ServiceEntry (MESH_EXTERNAL) and DestinationRule (SIMPLE TLS)" "Kubernetes API"
        aiGateway -> gatewayAPI "Creates HTTPRoutes for model-to-provider routing" "Kubernetes API"

        gatewayAPI -> istio "Routes inference traffic via HTTPRoute"
        istio -> openai "Forwards inference requests with TLS origination" "HTTPS/443"
        istio -> anthropic "Forwards inference requests with TLS origination" "HTTPS/443"
        istio -> azure "Forwards inference requests with TLS origination" "HTTPS/443"
        istio -> vertexAI "Forwards inference requests with TLS origination" "HTTPS/443"

        epController -> k8sAPI "Watch ExternalProvider, CRUD Services/ServiceEntries/DestinationRules" "HTTPS/6443"
        emController -> k8sAPI "Watch ExternalModel, CRUD HTTPRoutes" "HTTPS/6443"
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
            element "Infrastructure" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}
