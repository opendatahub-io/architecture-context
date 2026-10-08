workspace {
    model {
        dataScientist = person "Data Scientist / Tenant User" "Consumes inference models via API keys and subscriptions"
        platformAdmin = person "Platform Administrator" "Provisions tenants and manages model availability"

        maas = softwareSystem "Models as a Service" "Multi-tenant platform for managing inference model endpoints with API key lifecycle, rate limiting, and Gateway API-based routing" {
            maasController = container "maas-controller" "Central operator managing tenant lifecycle, model references, subscriptions, auth policies, and self-deploying maas-api per tenant" "Go Operator (controller-runtime)"
            maasAPI = container "maas-api" "Per-tenant HTTP API service for model listing, subscription management, API key CRUD, and tenant discovery" "Go HTTP Service (Gin)" {
                tags "Per-Tenant"
            }
            maasDiscovery = container "maas-discovery" "Cross-namespace tenant enumeration service" "Go HTTP Service"
            webhook = container "Webhook Server" "Validates AITenant, MaaSAuthPolicy, MaaSModelRef, MaaSSubscription on create/update" "Go Admission Webhook"
        }

        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Platform ingress gateway providing per-tenant and per-model routing via HTTPRoutes" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant" "API management platform providing authentication (Authorino) and rate limiting (Limitador)" "Internal Platform" {
            authorino = container "Authorino" "Gateway-level authentication: API key, TokenReview, OIDC JWT. Strips Authorization header before forwarding." "Auth Service"
            limitador = container "Limitador" "Per-subscription token rate limiting via TokenRateLimitPolicy" "Rate Limiter"
        }
        kserve = softwareSystem "KServe" "Serverless ML inference platform providing LLMInferenceService for on-cluster models" "Internal Platform"
        llmD = softwareSystem "llm-d" "LLM inference scheduling providing InferenceObjective CRD for priority routing" "Internal Platform"
        postgresql = softwareSystem "PostgreSQL" "Relational database for API key persistence" "Infrastructure"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation, TokenReview, SAR" "Infrastructure"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster-wide TLS security profile and authentication configuration" "Infrastructure"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Infrastructure"
        externalProviders = softwareSystem "External Inference Providers" "OpenAI, Anthropic, and other external model APIs" "External"

        # User interactions
        dataScientist -> maas "Creates subscriptions, manages API keys, sends inference requests" "HTTPS/443 via Gateway"
        platformAdmin -> maas "Creates AITenant CRs, manages model availability" "kubectl / HTTPS"

        # Internal flows
        maasController -> k8sAPI "CRD reconciliation, namespace/resource management" "HTTPS/6443"
        maasController -> maasAPI "Self-deploys per tenant namespace" "Kustomize render via K8s API"
        maasAPI -> postgresql "API key storage and queries" "TCP/5432"
        maasAPI -> k8sAPI "TokenReview, SubjectAccessReview" "HTTPS/6443"
        maasAPI -> otel "Distributed trace export" "OTLP/gRPC"
        maasDiscovery -> k8sAPI "Tenant enumeration" "HTTPS/6443"

        # Platform integrations
        maas -> gatewayAPI "HTTPRoute CRUD for per-tenant/per-model routing" "HTTPS/8443"
        maas -> kuadrant "AuthPolicy and TokenRateLimitPolicy CRUD" "HTTPS/6443"
        authorino -> maasAPI "API key validation callback" "HTTP/8080"
        maas -> kserve "Watches LLMInferenceService (conditional)" "HTTPS/6443"
        maas -> llmD "InferenceObjective CRUD (conditional)" "HTTPS/6443"
        maas -> openshiftConfig "Reads cluster TLS security profile" "HTTPS/6443"
        gatewayAPI -> externalProviders "Forwards inference to external providers" "HTTPS/443"
        prometheus -> maas "Scrapes metrics" "HTTPS/9090"
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
                background #f8cecc
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
                shape RoundedBox
            }
            element "Infrastructure" {
                background #fff2cc
                shape Cylinder
            }
            element "Per-Tenant" {
                background #d5e8d4
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
