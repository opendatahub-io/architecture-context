workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to external LLMs via unified OpenAI-compatible API"
        admin = person "Platform Admin" "Configures ExternalProvider and ExternalModel CRDs"

        payloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc service with pluggable IPP plugins for request/response mutation, API translation, credential injection; plus Kubernetes controllers for dynamic networking resource management" {
            extProcService = container "ext_proc gRPC Service" "Processes inference request/response streams from Envoy for mutation via plugin pipeline" "Go, llm-d IPP Framework" "9004/TCP"
            healthService = container "Health Check" "Liveness and readiness probes" "HTTP" "9005/TCP"

            headersGuard = component "maas-headers-guard" "Strips internal x-maas-* headers from incoming requests" "IPP RequestProcessor"
            modelResolver = component "model-provider-resolver" "Resolves model name to provider info via in-memory CRD cache" "IPP RequestProcessor"
            apiTranslation = component "api-translation" "Translates between OpenAI and provider-native formats (Anthropic, Azure, Bedrock, Vertex)" "IPP RequestProcessor + ResponseProcessor"
            apikeyInjection = component "apikey-injection" "Injects provider API credentials from Kubernetes Secrets" "IPP RequestProcessor"
            nemoGuards = component "nemo-request/response-guard" "Optional NeMo Guardrails integration for content safety" "IPP Processor (optional)"

            epController = container "ExternalProvider Controller" "Creates ExternalName Service, Istio ServiceEntry, DestinationRule per provider" "controller-runtime Reconciler"
            emController = container "ExternalModel Controller" "Creates Gateway API HTTPRoutes with path-prefix and header matching" "controller-runtime Reconciler"
            legacyController = container "Legacy Migration Controller" "Migrates maas.opendatahub.io CRs to inference.opendatahub.io" "controller-runtime Reconciler"
        }

        aiGateway = softwareSystem "AI Gateway" "Istio Gateway with EnvoyFilter for ext_proc attachment and HTTPRoute-based traffic routing" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane for CRD watches and resource management" "Infrastructure"
        istio = softwareSystem "Istio / Envoy" "Service mesh providing mTLS, ext_proc filter attachment, ServiceEntry, DestinationRule" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic routing for Kubernetes" "Infrastructure"

        openai = softwareSystem "OpenAI" "External LLM provider — Chat Completions API" "External"
        anthropic = softwareSystem "Anthropic" "External LLM provider — Messages API" "External"
        azureOpenAI = softwareSystem "Azure OpenAI Service" "External LLM provider — Chat Completions API" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "External LLM provider — OpenAI-compatible API" "External"
        vertexAI = softwareSystem "Google Vertex AI" "External LLM provider — OpenAI-compatible API" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Optional content safety guardrail service" "External (optional)"

        # Relationships
        user -> aiGateway "Sends inference requests" "HTTPS/443"
        admin -> k8sAPI "Creates ExternalProvider/ExternalModel CRDs" "HTTPS/443"

        aiGateway -> payloadProcessing "Sends request/response streams via ext_proc" "gRPC/9004, mTLS"
        payloadProcessing -> k8sAPI "Watches CRDs, creates networking resources" "HTTPS/443, SA token"

        aiGateway -> openai "Proxies inference requests" "HTTPS/443, Bearer Token"
        aiGateway -> anthropic "Proxies inference requests" "HTTPS/443, x-api-key"
        aiGateway -> azureOpenAI "Proxies inference requests" "HTTPS/443, api-key"
        aiGateway -> awsBedrock "Proxies inference requests" "HTTPS/443, AWS SigV4"
        aiGateway -> vertexAI "Proxies inference requests" "HTTPS/443, Bearer Token"

        payloadProcessing -> nemoGuardrails "Content safety checks (optional)" "HTTP, plaintext"

        epController -> k8sAPI "Creates Service, ServiceEntry, DestinationRule" "HTTPS/443"
        emController -> k8sAPI "Creates HTTPRoute" "HTTPS/443"
        legacyController -> k8sAPI "Creates inference.opendatahub.io CRs" "HTTPS/443"
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
            element "External (optional)" {
                background #bbbbbb
                color #ffffff
                border dashed
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
