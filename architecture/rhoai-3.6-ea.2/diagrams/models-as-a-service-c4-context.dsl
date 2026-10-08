workspace {
    model {
        dataScientist = person "Data Scientist" "Creates model subscriptions and API keys for inference access"
        platformAdmin = person "Platform Admin" "Provisions tenants and configures model access policies"

        maas = softwareSystem "Models-as-a-Service" "Multi-tenant platform for managing AI model endpoints as a service with API key management, subscription-based access control, and Gateway API integration" {
            controller = container "maas-controller" "Reconciles AITenant, Config, ExternalModel, MaaSAuthPolicy, MaaSModelRef, MaaSSubscription CRDs; manages tenant lifecycle, Gateway API routing, Kuadrant policies, and self-deployment" "Go Operator (controller-runtime v0.25.0)"
            apiService = container "maas-api" "REST API for model discovery, API key management, subscription operations; handles Authorino API key validation callbacks" "Go HTTP Service (Gin v1.12.0)"
            discoveryService = container "maas-discovery" "Tenant discovery service providing multi-cluster tenant metadata via informer-cached AITenant and Gateway resources" "Go HTTP Service (Gin v1.12.0)"
            webhookServer = container "Validating Webhook" "Validates AITenant, MaaSAuthPolicy, MaaSModelRef, MaaSSubscription CRs on CREATE/UPDATE" "Kubernetes Admission Webhook"
        }

        gatewayAPI = softwareSystem "Gateway API" "Shared data-science-gateway for external API traffic routing via HTTPRoutes" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant/Authorino" "Authentication and authorization enforcement at the gateway; dual auth path (API key + TokenReview); credential stripping" "Internal RHOAI"
        limitador = softwareSystem "Kuadrant/Limitador" "Per-subscription rate limiting via TokenRateLimitPolicy" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService for model state" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "API key metadata storage and validation" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation, RBAC, TokenReview" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection via gRPC OTLP" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "TLS certificate provisioning for metrics endpoints" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing model endpoints" "Internal RHOAI"

        // Person interactions
        dataScientist -> maas "Creates API keys, subscribes to models, sends inference requests" "HTTPS/443"
        platformAdmin -> maas "Creates AITenant CRs, configures model access policies" "kubectl/HTTPS"

        // Internal container relationships
        controller -> apiService "Deploys via Tenant reconciler (embedded kustomize manifests)"
        controller -> webhookServer "Serves admission webhooks"

        // System interactions
        controller -> k8sAPI "Reconciles CRDs, manages namespaces, RBAC, creates HTTPRoutes and AuthPolicies" "HTTPS/6443"
        controller -> gatewayAPI "Creates HTTPRoute resources for model endpoint routing"
        controller -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy resources"
        controller -> limitador "Creates per-subscription rate limit policies"
        controller -> kserve "Watches LLMInferenceService for model state (conditional)" "HTTPS/6443"

        apiService -> postgresql "Stores and validates API keys" "TCP/5432"
        apiService -> k8sAPI "Reads MaaSModelRef, MaaSSubscription CRs; performs TokenReview and SubjectAccessReview" "HTTPS/6443"
        apiService -> otel "Exports distributed traces" "gRPC OTLP"

        kuadrant -> apiService "API key validation callback" "HTTPS/8443"

        discoveryService -> k8sAPI "Watches AITenant and Gateway resources via informer cache" "HTTPS/6443"

        serviceCa -> apiService "Provisions TLS certificates for metrics endpoint"
        serviceCa -> controller "Provisions TLS certificates for metrics and webhook endpoints"

        dashboard -> maas "UI management of model endpoints"
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
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
