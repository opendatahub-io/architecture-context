workspace {
    model {
        dataScientist = person "Data Scientist" "Creates models, manages API keys, and consumes inference endpoints"
        platformAdmin = person "Platform Admin" "Provisions tenants, configures models and subscriptions"

        maas = softwareSystem "Models as a Service (MaaS)" "Managed platform for exposing LLM inference endpoints with API key management, subscription-based rate limiting, and multi-tenant isolation" {
            maasController = container "maas-controller" "Reconciles MaaS CRDs into Kubernetes resources (HTTPRoutes, AuthPolicies, TokenRateLimitPolicies, NetworkPolicies)" "Go Operator (controller-runtime)"
            maasAPI = container "maas-api" "User-facing REST API for API key management, model discovery, subscription listing, and tenant metadata" "Go HTTP Service (Gin)"
            payloadProcessing = container "payload-processing" "Envoy ext_proc filter for model name extraction, API translation, token counting, and credential injection" "gRPC External Processor"
            webhooks = container "Admission Webhooks" "Validates AITenant gateway uniqueness, namespace enablement for MaaSAuthPolicy and MaaSSubscription" "Go (controller-runtime)"
        }

        kuadrant = softwareSystem "Kuadrant / RHCL" "Policy engine for authentication, authorization, and rate limiting" "External" {
            authorino = container "Authorino" "Token and API key validation, authorization evaluation" "AuthN/AuthZ Service"
            limitador = container "Limitador" "Token-based rate limit enforcement" "Rate Limiter"
        }

        kserve = softwareSystem "KServe" "Serverless ML model serving (LLMInferenceService CRD)" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway for model and API routing" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh: ServiceEntry, DestinationRule, EnvoyFilter, Telemetry" "External"
        postgresql = softwareSystem "PostgreSQL" "API key storage, validation, and lifecycle management" "External"
        otel = softwareSystem "OpenTelemetry" "Distributed tracing and usage log collection" "External"
        prometheus = softwareSystem "Prometheus / Monitoring" "Metrics scraping, alerting, and dashboards" "External"
        externalModels = softwareSystem "External Model Providers" "Third-party LLM APIs (e.g., OpenAI, Azure)" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys and manages MaaS controller" "Internal Platform"
        openShiftAuth = softwareSystem "OpenShift Authentication" "Cluster OIDC issuer for token audience validation" "External"

        # Relationships
        dataScientist -> maas "Creates API keys, lists models, sends inference requests" "HTTPS/443"
        platformAdmin -> maas "Creates AITenants, MaaSModelRefs, MaaSSubscriptions" "kubectl/HTTPS/6443"
        rhodsOperator -> maas "Deploys maas-controller when MaaS is enabled" "Kubernetes API"

        maasController -> gatewayAPI "Creates HTTPRoutes for model and API routing" "Kubernetes API"
        maasController -> kuadrant "Creates AuthPolicies and TokenRateLimitPolicies" "Kubernetes API"
        maasController -> istio "Creates ServiceEntries, DestinationRules, EnvoyFilters" "Kubernetes API"
        maasController -> kserve "Watches LLMInferenceService for model backend resolution" "Kubernetes API (read-only)"
        maasController -> openShiftAuth "Auto-detects OIDC issuer for token audience" "Kubernetes API (read-only)"

        maasAPI -> postgresql "Stores and validates API keys (SHA-256 hashed)" "TCP/5432"
        maasAPI -> otel "Exports distributed traces" "gRPC/4317"

        authorino -> maasAPI "Validates API keys, selects subscriptions" "HTTPS/8443"
        limitador -> gatewayAPI "Enforces token rate limits at gateway" "In-process"
        payloadProcessing -> externalModels "Injects credentials for external model providers" "HTTPS/443"

        maas -> externalModels "Proxies inference requests to external LLM providers" "HTTPS/443, TLS origination"
        maas -> prometheus "Exposes metrics via ServiceMonitors" "HTTP/9090, HTTP/8080"
    }

    views {
        systemContext maas "SystemContext" {
            include *
            autoLayout
        }

        container maas "Containers" {
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
            element "Person" {
                shape Person
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
