workspace {
    model {
        dataScientist = person "Data Scientist" "Discovers and subscribes to AI models via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Configures tenants, models, and authentication policies"

        maas = softwareSystem "Models-as-a-Service" "Multi-tenant model serving gateway providing OpenAI-compatible API access with subscription governance and API key authentication" {
            maasApi = container "maas-api" "Gin-based REST API server exposing OpenAI-compatible endpoints for model discovery, subscription management, and API key lifecycle" "Go / Gin"
            maasController = container "maas-controller" "controller-runtime operator reconciling 8 CRDs for tenant provisioning, Gateway API routing, and Kuadrant AuthPolicy management" "Go / controller-runtime"
            webhookServer = container "Webhook Server" "Validates AITenant, MaaSAuthPolicy, MaaSModelRef, and MaaSSubscription resources" "Kubernetes Admission Webhooks"
            database = container "PostgreSQL Database" "Stores API keys, subscription data, and tenant metadata" "PostgreSQL"
        }

        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant/Authorino" "Authentication and authorization policy enforcement at the gateway" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService resources" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API" "Kubernetes control plane for resource management" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        dataScientist -> maas "Lists models, manages subscriptions, generates API keys" "HTTPS / OpenAI-compatible REST"
        platformAdmin -> maas "Configures tenants, models, auth policies" "kubectl / CRDs"

        # Internal container interactions
        maasApi -> database "Queries/updates subscription and API key data" "pgx / TLS"
        maasController -> webhookServer "Validates CRD mutations" "HTTPS"

        # External dependencies
        gatewayApi -> maasApi "Routes external traffic via HTTPRoute maas-api-route" "HTTPS/8443"
        kuadrant -> maasApi "Validates API keys via callback" "HTTPS"
        maasController -> gatewayApi "Creates/updates HTTPRoute resources" "Kubernetes API"
        maasController -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy" "Kubernetes API"
        maasController -> kserve "Watches LLMInferenceService (conditional)" "Kubernetes API"
        maasApi -> k8sApi "TokenReview, SubjectAccessReview, resource operations" "HTTPS/6443"
        maasController -> k8sApi "CRD reconciliation, resource management" "HTTPS/6443"
        maasApi -> otel "Exports traces" "OTLP/gRPC"
        prometheus -> maasApi "Scrapes metrics" "HTTP/9090"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
