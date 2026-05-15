workspace {
    model {
        user = person "Application Developer" "Sends inference requests to AI models via unified OpenAI-compatible API"

        payloadProcessing = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc plugin that mutates inference request/response bodies and headers for multi-provider API translation, credential injection, and content guardrails" {
            extProcServer = container "ext_proc gRPC Server" "BBR framework runner hosting the plugin chain" "Go / BBR Framework" "9004/TCP gRPC"
            modelProviderResolver = container "model-provider-resolver" "Watches ExternalModel CRDs, resolves model names to provider info and credential references" "BBR Plugin"
            apiTranslation = container "api-translation" "Translates between OpenAI Chat Completions and provider-native formats (Anthropic, Vertex, Azure, Bedrock)" "BBR Plugin"
            apikeyInjection = container "apikey-injection" "Watches labeled Secrets, injects provider-specific auth headers" "BBR Plugin"
            nemoRequestGuard = container "nemo-request-guard" "Calls NeMo Guardrails service to enforce input content safety rails" "BBR Plugin"
            externalModelReconciler = container "ExternalModel Reconciler" "controller-runtime reconciler maintaining in-memory model info store" "Go / controller-runtime"
            secretReconciler = container "Secret Reconciler" "controller-runtime reconciler maintaining in-memory secret store" "Go / controller-runtime"
        }

        istioGateway = softwareSystem "Istio Gateway (Envoy)" "Service mesh gateway handling TLS termination, routing, and ext_proc integration" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane providing CRD and Secret API" "External"
        maasController = softwareSystem "MaaS Controller" "Creates ExternalModel CRDs mapping model names to providers and credentials" "Internal RHOAI"
        nemoGuardrails = softwareSystem "NeMo Guardrails Service" "Content safety evaluation service for input rail checks" "External"
        bbrFramework = softwareSystem "Gateway API Inference Extension (BBR)" "Upstream pluggable body-based routing framework for Envoy ext_proc" "External"

        openai = softwareSystem "OpenAI API" "External AI inference provider" "External Provider"
        anthropic = softwareSystem "Anthropic API" "External AI inference provider" "External Provider"
        azureOpenai = softwareSystem "Azure OpenAI" "External AI inference provider" "External Provider"
        vertexAI = softwareSystem "Vertex AI" "External AI inference provider" "External Provider"
        bedrock = softwareSystem "Amazon Bedrock" "External AI inference provider" "External Provider"

        # Relationships
        user -> istioGateway "Sends OpenAI-format inference requests" "HTTPS/443 TLS 1.2+"
        istioGateway -> payloadProcessing "Sends ext_proc gRPC calls for request/response mutation" "gRPC/9004 plaintext"

        extProcServer -> modelProviderResolver "Invokes for each request"
        extProcServer -> apiTranslation "Invokes for request and response"
        extProcServer -> apikeyInjection "Invokes for each request"
        extProcServer -> nemoRequestGuard "Invokes for each request (optional)"

        modelProviderResolver -> externalModelReconciler "Reads in-memory model info store"
        apikeyInjection -> secretReconciler "Reads in-memory secret store"

        externalModelReconciler -> kubernetesAPI "Watches ExternalModel CRDs" "HTTPS/443"
        secretReconciler -> kubernetesAPI "Watches labeled Secrets (bbr-managed=true)" "HTTPS/443"
        maasController -> kubernetesAPI "Creates ExternalModel CRDs"

        nemoRequestGuard -> nemoGuardrails "Evaluates input safety rails" "HTTP POST"

        istioGateway -> openai "Forwards mutated requests" "HTTPS/443 Bearer token"
        istioGateway -> anthropic "Forwards mutated requests" "HTTPS/443 x-api-key"
        istioGateway -> azureOpenai "Forwards mutated requests" "HTTPS/443 api-key"
        istioGateway -> vertexAI "Forwards mutated requests" "HTTPS/443 Bearer token"
        istioGateway -> bedrock "Forwards mutated requests" "HTTPS/443 Bearer token"
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
            element "External Provider" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
