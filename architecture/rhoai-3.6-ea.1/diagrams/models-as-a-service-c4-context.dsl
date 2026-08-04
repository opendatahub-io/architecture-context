workspace {
    model {
        dataScientist = person "Data Scientist" "Creates model subscriptions, generates API keys, and accesses AI models"
        platformAdmin = person "Platform Admin" "Configures tenants, auth policies, and model references"

        maas = softwareSystem "Models-as-a-Service" "Multi-tenant API gateway and controller for managing AI model access, subscriptions, and authentication on RHOAI" {
            maasApi = container "maas-api" "REST API server exposing OpenAI-compatible endpoints for model listing, subscriptions, and API key management" "Go (Gin Framework)" {
                ginRouter = component "Gin HTTP Router" "Routes API requests to handlers" "Gin"
                tenantAuthMW = component "Tenant Auth Middleware" "Validates bearer tokens via TokenReview and SAR" "Go"
                dbClient = component "Database Client" "Manages PostgreSQL connections and queries" "pgx"
                tlsConfig = component "TLS Configuration" "Configurable TLS 1.2+/1.3 with FIPS compliance" "crypto/tls"
                metricsServer = component "Metrics Server" "Exposes Prometheus metrics on port 9090" "prometheus/client_golang"
            }
            maasController = container "maas-controller" "Kubernetes operator managing 8 CRDs for tenant lifecycle, model references, subscriptions, and auth policies" "Go (controller-runtime)" {
                aiTenantCtrl = component "AITenant Controller" "Reconciles tenant resources and namespaces" "controller-runtime"
                modelRefCtrl = component "MaaSModelRef Controller" "Tracks model references with conditional KServe watch" "controller-runtime"
                subscriptionCtrl = component "MaaSSubscription Controller" "Manages model subscription governance" "controller-runtime"
                authPolicyCtrl = component "MaaSAuthPolicy Controller" "Generates Kuadrant AuthPolicy resources" "controller-runtime"
                externalModelCtrl = component "ExternalModel Controller" "Reconciles external model configurations" "controller-runtime"
                tenantConfigCtrl = component "MaasTenantConfig Controller" "Manages per-tenant configuration" "controller-runtime"
                lifecycleCtrl = component "Lifecycle Reconciler" "Orchestrates component deployment lifecycle" "controller-runtime"
                webhookServer = component "Webhook Server" "Validates CRD mutations via admission webhooks" "controller-runtime"
            }
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant/Authorino" "Gateway-level authentication and rate limiting" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService resources" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for API keys, subscriptions, and tenant state" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, auth, and admission" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"

        # Person relationships
        dataScientist -> maas "Lists models, manages subscriptions, generates API keys" "HTTPS/8443 via Gateway"
        platformAdmin -> maas "Configures AITenants, MaaSAuthPolicies, MaaSModelRefs" "kubectl / Kubernetes API"

        # System-level relationships
        maas -> gatewayAPI "Routes external API traffic via HTTPRoute" "Kubernetes API"
        maas -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy for gateway auth" "Kubernetes API"
        maas -> kserve "Conditionally watches LLMInferenceService for model state" "Kubernetes API"
        maas -> postgresql "Stores API keys, subscriptions, tenant metadata" "pgx/5432"
        maas -> k8sAPI "Manages CRDs, TokenReview, SAR, Namespaces, Secrets" "HTTPS/6443"
        maas -> otel "Exports distributed traces" "OTLP/gRPC"

        # Container-level relationships
        dataScientist -> maasApi "API requests via Gateway" "HTTPS/8443"
        maasApi -> postgresql "Queries and stores data" "pgx"
        maasApi -> k8sAPI "TokenReview, SubjectAccessReview, CRD reads" "HTTPS/6443"
        maasController -> k8sAPI "Watches and manages CRDs, core resources" "HTTPS/6443"
        maasController -> kuadrant "Creates AuthPolicy, TokenRateLimitPolicy" "Kubernetes API"
        maasController -> kserve "Conditional LLMInferenceService watch" "Kubernetes API"
        maasController -> gatewayAPI "Creates/manages HTTPRoutes" "Kubernetes API"
        maasController -> otel "Trace export" "OTLP/gRPC"
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

        component maasApi "MaaSAPIComponents" {
            include *
            autoLayout
        }

        component maasController "MaaSControllerComponents" {
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
            element "Software System" {
                background #1168bd
                color #ffffff
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
