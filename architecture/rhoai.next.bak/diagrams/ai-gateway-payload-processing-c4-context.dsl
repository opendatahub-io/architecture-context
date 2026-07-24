workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to external LLM models via the AI Gateway"

        platformAdmin = person "Platform Admin" "Creates ExternalModel and ExternalProvider CRs to configure model routing"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc filter with embedded controllers. Intercepts inference requests, resolves model-to-provider mappings, translates API formats, injects credentials, and enforces guardrails." {
            extProcServer = container "ext_proc gRPC Server" "Receives request/response bodies from Envoy for mutation via plugin pipeline" "Go / llm-d IPP framework" "9004/TCP"
            pluginPipeline = container "Plugin Pipeline" "Ordered plugins: maas-headers-guard → model-provider-resolver → api-translation → apikey-injection → nemo-guards" "Go plugins"
            externalModelController = container "ExternalModel Controller" "Reconciles ExternalModel CRs, creates HTTPRoute resources for traffic routing" "controller-runtime"
            externalProviderController = container "ExternalProvider Controller" "Reconciles ExternalProvider CRs, creates ExternalName Service + ServiceEntry + DestinationRule" "controller-runtime"
            legacyMigrationController = container "Legacy Migration Controller" "Watches maas.opendatahub.io ExternalModel CRs, creates inference.opendatahub.io equivalents" "controller-runtime"
            modelProviderStore = container "Model-Provider Store" "In-memory cache of ExternalModel/ExternalProvider mappings used by resolver plugin" "Go in-memory"
            secretStore = container "Secret Store" "In-memory cache of labeled Kubernetes Secrets for API key injection" "Go in-memory"
        }

        aiGateway = softwareSystem "AI Gateway" "Istio Envoy Gateway that terminates TLS and routes inference traffic" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides EnvoyFilter, ServiceEntry, DestinationRule for mesh networking and TLS origination" "External"
        gatewayAPI = softwareSystem "Gateway API" "Provides HTTPRoute CRDs for declarative traffic routing" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation, Secret access, and resource creation" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Optional content safety service for evaluating input/output rails" "Internal ODH"

        openAI = softwareSystem "OpenAI API" "External LLM provider (api.openai.com)" "External Provider"
        anthropic = softwareSystem "Anthropic API" "External LLM provider (api.anthropic.com)" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "External LLM provider ({resource}.openai.azure.com)" "External Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "External LLM provider (bedrock-runtime.{region}.amazonaws.com)" "External Provider"
        vertexAI = softwareSystem "Vertex AI" "External LLM provider ({endpoint}.aiplatform.googleapis.com)" "External Provider"

        # Relationships
        user -> aiGateway "Sends inference requests" "HTTPS/443 TLS 1.2+"
        platformAdmin -> k8sAPI "Creates ExternalModel/ExternalProvider CRs" "kubectl HTTPS/443"

        aiGateway -> aiGatewayPayloadProcessing "Forwards requests via ext_proc filter" "gRPC/9004 plaintext"
        aiGatewayPayloadProcessing -> k8sAPI "Watches CRDs, reads Secrets, creates networking resources" "HTTPS/443 mTLS"
        aiGatewayPayloadProcessing -> nemoGuardrails "Evaluates content safety rails" "HTTP POST"
        aiGatewayPayloadProcessing -> istio "Creates ServiceEntry, DestinationRule" "via K8s API"
        aiGatewayPayloadProcessing -> gatewayAPI "Creates HTTPRoute" "via K8s API"

        aiGateway -> openAI "Proxied inference (via ExternalName + DestinationRule)" "HTTPS/443 Bearer Token"
        aiGateway -> anthropic "Proxied inference (translated to Messages API)" "HTTPS/443 x-api-key"
        aiGateway -> azureOpenAI "Proxied inference (path rewritten)" "HTTPS/443 api-key"
        aiGateway -> awsBedrock "Proxied inference (SigV4 signed)" "HTTPS/443 SigV4"
        aiGateway -> vertexAI "Proxied inference (path rewritten)" "HTTPS/443 Bearer OAuth2"

        # Container relationships
        extProcServer -> pluginPipeline "Invokes plugin chain"
        pluginPipeline -> modelProviderStore "Reads model-to-provider mapping"
        pluginPipeline -> secretStore "Reads API keys"
        externalModelController -> modelProviderStore "Updates model mappings"
        externalProviderController -> modelProviderStore "Updates provider mappings"
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
            element "External Provider" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
