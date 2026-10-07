workspace {
    model {
        admin = person "Platform Administrator" "Creates AITenants and manages the MaaS platform"
        datascientist = person "Tenant User / Data Scientist" "Consumes model endpoints via API keys or OpenShift tokens"

        maas = softwareSystem "Models as a Service (MaaS)" "Centralized inference model endpoint management with multi-tenant isolation, API key auth, and policy-driven authorization" {
            controller = container "maas-controller" "Reconciles tenant lifecycle, model references, subscriptions, auth policies, and per-tenant maas-api deployments" "Go Operator (controller-runtime)"
            api = container "maas-api" "Per-tenant REST API for API key management, model catalog, and subscription queries" "Go HTTP Service (Gin)"
            discovery = container "maas-discovery" "Tenant discovery service exposing tenant metadata via HTTPS" "Go HTTP Service"
            webhook = container "Validating Webhook" "Validates AITenant, MaaSAuthPolicy, MaaSModelRef, MaaSSubscription" "Admission Webhook"
        }

        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based routing through maas-default-gateway and data-science-gateway" "External"
        kuadrant = softwareSystem "Kuadrant/Authorino" "Multi-method authentication (API key, OpenShift token, OIDC) and authorization enforcement" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, TLS enforcement, and external model connectivity" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "API key storage and subscription data persistence" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks and metrics (xks)" "External"
        serviceca = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        modelProviders = softwareSystem "External Model Providers" "OpenAI, Azure, and other external LLM inference APIs" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Parent operator managing MaaS component lifecycle" "Internal RHOAI"

        datascientist -> maas "Sends inference requests and manages API keys" "HTTPS/443"
        admin -> maas "Creates AITenants and configures platform" "kubectl/HTTPS"

        controller -> gatewayAPI "Creates HTTPRoutes for per-tenant routing" "Kubernetes API"
        controller -> kuadrant "Creates AuthPolicies and TokenRateLimitPolicies" "Kubernetes API"
        controller -> istio "Creates DestinationRules, EnvoyFilters, ServiceEntries" "Kubernetes API"
        controller -> kserve "Watches LLMInferenceService for model state" "Kubernetes API"
        controller -> serviceca "Uses for TLS certificate provisioning" "Kubernetes API"
        controller -> certManager "Creates Certificate resources (xks overlay)" "Kubernetes API"

        api -> postgresql "Stores API keys and subscription data" "TCP/5432"
        api -> otel "Exports distributed traces" "OTLP/gRPC"

        maas -> gatewayAPI "Routes inference traffic through gateway" "HTTPS/443"
        gatewayAPI -> kuadrant "Evaluates authentication policies" "Internal"
        gatewayAPI -> modelProviders "Proxies inference to external models" "HTTPS/443"

        odhOperator -> maas "Deploys and manages MaaS component" "Kubernetes API"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
