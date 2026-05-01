workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Sends inference requests via unified OpenAI-compatible API"
        platformadmin = person "Platform Admin" "Deploys and configures ExternalModel CRDs and provider credentials"

        aiGatewayPayloadProcessing = softwareSystem "AI Gateway Payload Processing" "Pluggable BBR ext_proc service for payload mutation on AI Gateway data path" {
            extProcServer = container "ext_proc gRPC Server" "Hosts BBR plugin chain, receives request/response bodies from Envoy" "Go Service, gRPC/9004"
            modelProviderResolver = container "model-provider-resolver Plugin" "Resolves model name to provider and credentials via ExternalModel CRDs" "BBR RequestProcessor"
            apiTranslation = container "api-translation Plugin" "Translates between OpenAI Chat Completions and provider-native formats" "BBR Request/ResponseProcessor"
            apikeyInjection = container "apikey-injection Plugin" "Injects provider-specific auth headers from cached Secrets" "BBR RequestProcessor"
            nemoRequestGuard = container "nemo-request-guard Plugin" "Input content safety rails via NeMo Guardrails" "BBR RequestProcessor"
            nemoResponseGuard = container "nemo-response-guard Plugin" "Output content safety rails via NeMo Guardrails" "BBR ResponseProcessor"
            externalModelReconciler = container "ExternalModel Reconciler" "Watches ExternalModel CRDs, populates in-memory model store" "controller-runtime Reconciler"
            secretReconciler = container "Secret Reconciler" "Watches labeled Secrets, populates in-memory secret store" "controller-runtime Reconciler"
        }

        istioGateway = softwareSystem "Istio Gateway (Envoy Proxy)" "Terminates TLS, routes inference traffic, applies EnvoyFilter for ext_proc" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Provides CRD and Secret watch APIs" "External"
        maas = softwareSystem "Models-as-a-Service (MaaS)" "Creates and manages ExternalModel CRDs defining model-to-provider mappings" "Internal RHOAI"
        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "Content safety guardrail checks for input/output filtering" "Optional External"

        openai = softwareSystem "OpenAI API" "Cloud inference provider (api.openai.com)" "External Provider"
        anthropic = softwareSystem "Anthropic API" "Cloud inference provider (api.anthropic.com)" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI Service" "Cloud inference provider ({resource}.openai.azure.com)" "External Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "Cloud inference provider ({region}.bedrock.amazonaws.com)" "External Provider"
        googleVertex = softwareSystem "Google Vertex AI" "Cloud inference provider ({region}-aiplatform.googleapis.com)" "External Provider"

        bbrFramework = softwareSystem "Gateway API Inference Extension (BBR)" "Upstream pluggable body-based routing framework and Helm chart" "External"

        # Relationships
        datascientist -> istioGateway "Sends inference requests" "HTTPS/443"
        platformadmin -> kubernetesAPI "Creates ExternalModel CRDs and Secrets" "kubectl/HTTPS"

        istioGateway -> aiGatewayPayloadProcessing "Sends request/response bodies via ext_proc" "gRPC/9004 plaintext"
        aiGatewayPayloadProcessing -> kubernetesAPI "Watches ExternalModel CRDs and labeled Secrets" "HTTPS/443"
        aiGatewayPayloadProcessing -> nemoGuardrails "Content safety guardrail checks" "HTTP POST /v1/guardrail/checks"

        istioGateway -> openai "Routes translated requests" "HTTPS/443, Bearer token"
        istioGateway -> anthropic "Routes translated requests" "HTTPS/443, x-api-key"
        istioGateway -> azureOpenAI "Routes translated requests" "HTTPS/443, api-key"
        istioGateway -> awsBedrock "Routes translated requests" "HTTPS/443, Bearer token"
        istioGateway -> googleVertex "Routes translated requests" "HTTPS/443, Bearer token"

        maas -> kubernetesAPI "Creates ExternalModel CRDs" "HTTPS/443"

        # Internal container relationships
        extProcServer -> modelProviderResolver "Plugin chain step 2"
        extProcServer -> apiTranslation "Plugin chain step 4"
        extProcServer -> apikeyInjection "Plugin chain step 5"
        extProcServer -> nemoRequestGuard "Plugin chain step 3 (optional)"
        extProcServer -> nemoResponseGuard "Response processing (optional)"
        externalModelReconciler -> kubernetesAPI "Watch ExternalModel CRDs" "HTTPS/443"
        secretReconciler -> kubernetesAPI "Watch Secrets (bbr-managed=true)" "HTTPS/443"
        nemoRequestGuard -> nemoGuardrails "POST /v1/guardrail/checks" "HTTP"
        nemoResponseGuard -> nemoGuardrails "POST /v1/guardrail/checks" "HTTP"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Optional External" {
                background #d6b656
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
