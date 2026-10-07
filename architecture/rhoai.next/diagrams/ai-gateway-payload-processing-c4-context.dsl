workspace {
    model {
        user = person "ML Platform User" "Sends inference requests to AI Gateway"
        admin = person "Platform Admin" "Configures ExternalModel and ExternalProvider CRDs"

        agpp = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc gRPC service and Kubernetes controllers for multi-provider LLM inference routing" {
            extproc = container "ext_proc gRPC Server" "Runs plugin pipeline on every inference request: model resolution, API translation, credential injection, guardrails" "Go gRPC Service"
            epController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs into Service, ServiceEntry, and DestinationRule resources" "Go Controller"
            emController = container "ExternalModel Controller" "Reconciles ExternalModel CRs into HTTPRoute resources for the platform Gateway" "Go Controller"
            legacyController = container "Legacy Migration Controller" "Migrates maas.opendatahub.io ExternalModel CRs to inference.opendatahub.io resources" "Go Controller"
            healthServer = container "Health gRPC Server" "gRPC health check endpoint for liveness/readiness probes" "Go gRPC Service"
            dynmeta = container "DynamicMetadata Wrapper" "Converts plugin-set pseudo-headers into Envoy DynamicMetadata" "Go Library"
        }

        envoy = softwareSystem "Envoy Proxy (AI Gateway)" "Ingress gateway with ext_proc filter chain" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "API server for CRD watches, Secret reads, resource CRUD" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh for ServiceEntry and DestinationRule management" "Internal Platform"
        gatewayApi = softwareSystem "Gateway API" "Platform ingress Gateway for HTTPRoute attachment" "Internal Platform"
        nemo = softwareSystem "NeMo Guardrails" "Content safety guardrail checks service" "Internal Platform"
        ipp = softwareSystem "llm-d-inference-payload-processor" "Upstream IPP framework providing ext_proc handler and plugin registry" "External Library"

        openai = softwareSystem "OpenAI" "External LLM provider" "External"
        anthropic = softwareSystem "Anthropic" "External LLM provider" "External"
        azure = softwareSystem "Azure OpenAI" "External LLM provider" "External"
        bedrock = softwareSystem "AWS Bedrock" "External LLM provider" "External"
        vertex = softwareSystem "Google Vertex AI" "External LLM provider" "External"

        user -> envoy "Sends inference requests" "HTTPS/443"
        admin -> k8sApi "Creates ExternalModel/ExternalProvider CRDs" "kubectl HTTPS/6443"
        envoy -> extproc "gRPC ext_proc callout" "gRPC/9004"
        extproc -> dynmeta "Wraps responses with DynamicMetadata"
        extproc -> k8sApi "Reads Secrets for credential injection" "HTTPS/6443"
        extproc -> nemo "Content safety checks" "HTTPS"
        envoy -> openai "Forwards inference requests" "HTTPS/443 API key"
        envoy -> anthropic "Forwards inference requests" "HTTPS/443 API key"
        envoy -> azure "Forwards inference requests" "HTTPS/443 API key"
        envoy -> bedrock "Forwards inference requests" "HTTPS/443 SigV4"
        envoy -> vertex "Forwards inference requests" "HTTPS/443 OAuth2"
        epController -> k8sApi "CRUD: Service, ServiceEntry, DestinationRule" "HTTPS/6443"
        emController -> k8sApi "CRUD: HTTPRoute" "HTTPS/6443"
        legacyController -> k8sApi "Watch legacy CRDs, create new CRDs" "HTTPS/6443"
        agpp -> ipp "Uses upstream ext_proc framework" "Go library"
        epController -> istio "Creates ServiceEntry + DestinationRule" "via K8s API"
        emController -> gatewayApi "Creates HTTPRoute" "via K8s API"
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
            element "Internal Platform" {
                background #7ed321
            }
            element "External Library" {
                background #f5a623
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
