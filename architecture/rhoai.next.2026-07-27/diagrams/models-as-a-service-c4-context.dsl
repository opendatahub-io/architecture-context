workspace {
    model {
        user = person "Data Scientist / Platform User" "Creates tenants, subscribes to models, manages API keys"
        admin = person "Platform Admin" "Configures MaaS platform, manages tenants"

        maas = softwareSystem "Models-as-a-Service" "Multi-tenant model serving platform providing subscription-based access to ML models via Gateway API" {
            manager = container "Manager" "Runs 7 CRD controllers: AITenant, Deployment, ExternalModel, MaaSAuthPolicy, MaaSModelRef, MaaSSubscription, MaasTenantConfig" "Go Operator (controller-runtime)"
            maasApi = container "maas-api" "REST API server for tenant, model, subscription, and API key management" "Go (Gin framework)"
            webhooks = container "Admission Webhooks" "Validates AITenant, MaaSAuthPolicy, MaaSSubscription resources" "ValidatingWebhookConfiguration"
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing (HTTPRoute, Gateway)" "External"
        kuadrant = softwareSystem "Kuadrant" "API management: AuthPolicy and TokenRateLimitPolicy enforcement" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, TokenReview, SubjectAccessReview" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for tenant and subscription data" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP/gRPC" "External"
        osAuth = softwareSystem "OpenShift Authentication" "Cluster authentication configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from :9090 endpoint" "External"

        user -> maas "Creates subscriptions, manages API keys" "HTTPS/443 via Gateway"
        admin -> maas "Manages tenants and platform config" "kubectl / HTTPS"

        maas -> gatewayAPI "Creates/manages HTTPRoute resources for model routing" "Kubernetes API"
        maas -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy" "Kubernetes API"
        maas -> kserve "Watches LLMInferenceService state (conditional)" "Kubernetes API"
        maas -> k8sAPI "CRD watches, CRUD, TokenReview, SubjectAccessReview" "HTTPS/6443"
        maas -> postgresql "Stores tenant/subscription data" "DB connection"
        maas -> otel "Exports traces" "OTLP/gRPC"
        maas -> osAuth "Reads cluster authentication config" "Kubernetes API"
        prometheus -> maas "Scrapes metrics" "HTTP/9090"

        manager -> k8sAPI "Watches CRDs, manages Gateway/Kuadrant resources" "HTTPS/6443"
        maasApi -> k8sAPI "TokenReview, SubjectAccessReview" "HTTPS/6443"
        maasApi -> postgresql "Queries tenant data" "DB credentials from maas-db-config secret"
        maasApi -> otel "Exports traces" "OTLP/gRPC"
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
