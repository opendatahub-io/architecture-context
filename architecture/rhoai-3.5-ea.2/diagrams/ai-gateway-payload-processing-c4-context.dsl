workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Sends inference requests to models via the AI Gateway"
        admin = person "Platform Admin" "Configures ExternalProvider and ExternalModel CRs"

        agpp = softwareSystem "AI Gateway Payload Processing" "Envoy ext_proc service with embedded controllers for routing inference requests to external LLM providers" {
            extproc = container "ext_proc Server" "gRPC external processor for Envoy - intercepts and transforms inference requests" "Go Service, 9004/TCP gRPC"
            pluginPipeline = container "Plugin Pipeline" "Chained request/response processing plugins" "Go, in-process" {
                modelResolver = component "model-provider-resolver" "Resolves model names to provider endpoints via CRD watches" "IPP Plugin"
                apiTranslation = component "api-translation" "Translates between OpenAI, Anthropic, Azure, Bedrock, Vertex AI formats" "IPP Plugin"
                apikeyInjection = component "apikey-injection" "Injects provider API keys (Bearer, SigV4, per-provider headers)" "IPP Plugin"
                nemoRequestGuard = component "nemo-request-guard" "Evaluates input content safety rails via NeMo Guardrails" "IPP Plugin"
                nemoResponseGuard = component "nemo-response-guard" "Evaluates output content safety rails via NeMo Guardrails" "IPP Plugin"
            }
            epController = container "ExternalProvider Controller" "Creates ExternalName Service, ServiceEntry, DestinationRule per provider" "Go, controller-runtime"
            emController = container "ExternalModel Controller" "Creates HTTPRoute per model for traffic routing" "Go, controller-runtime"
            legacyController = container "Legacy Migration Controller" "Migrates maas.opendatahub.io CRs to inference.opendatahub.io" "Go, controller-runtime"
            healthCheck = container "Health Check" "HTTP health check endpoint" "Go, 9005/TCP HTTP"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic management, TLS origination" "External" {
            gateway = container "Platform Gateway (Envoy)" "Ingress gateway with EnvoyFilter for ext_proc attachment" "Istio Envoy"
            serviceEntry = container "ServiceEntry CRDs" "DNS resolution for external provider FQDNs" "Istio CRD"
            destRule = container "DestinationRule CRDs" "TLS SIMPLE origination to external providers" "Istio CRD"
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing" "External" {
            httpRoute = container "HTTPRoute CRDs" "Route inference traffic to provider ExternalName Services" "Gateway API CRD"
        }

        k8s = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches and resource management" "External"
        nemo = softwareSystem "NeMo Guardrails" "Content safety evaluation service for input/output rails" "External"

        openai = softwareSystem "OpenAI API" "OpenAI Chat Completions API (api.openai.com)" "External Provider"
        anthropic = softwareSystem "Anthropic API" "Anthropic Messages API (api.anthropic.com)" "External Provider"
        azure = softwareSystem "Azure OpenAI" "Azure OpenAI Service ({resource}.openai.azure.com)" "External Provider"
        bedrock = softwareSystem "AWS Bedrock" "AWS Bedrock Runtime (bedrock-runtime.{region}.amazonaws.com)" "External Provider"
        vertex = softwareSystem "Google Vertex AI" "Vertex AI GenerateContent ({region}-aiplatform.googleapis.com)" "External Provider"

        llmdFramework = softwareSystem "llm-d IPP Framework" "Pluggable inference payload processor framework" "External"

        # Relationships
        datascientist -> istio "Sends inference requests" "HTTPS/443, TLS 1.2+"
        admin -> k8s "Creates ExternalProvider/ExternalModel CRs" "HTTPS/443"

        istio -> agpp "Forwards requests via ext_proc" "gRPC/9004, Istio mTLS"
        agpp -> k8s "Watches CRDs, creates resources" "HTTPS/443, SA Token"
        agpp -> nemo "Content safety checks" "HTTP POST"

        istio -> openai "Routes inference traffic" "HTTPS/443, TLS SIMPLE, Bearer Token"
        istio -> anthropic "Routes inference traffic" "HTTPS/443, TLS SIMPLE, x-api-key"
        istio -> azure "Routes inference traffic" "HTTPS/443, TLS SIMPLE, api-key"
        istio -> bedrock "Routes inference traffic" "HTTPS/443, TLS SIMPLE, SigV4"
        istio -> vertex "Routes inference traffic" "HTTPS/443, TLS SIMPLE, Bearer Token"

        agpp -> llmdFramework "Built on" "Go module dependency"

        epController -> serviceEntry "Creates" "HTTPS/443, SA Token"
        epController -> destRule "Creates" "HTTPS/443, SA Token"
        emController -> httpRoute "Creates" "HTTPS/443, SA Token"
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

        component pluginPipeline "PluginPipeline" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
            element "Component" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
