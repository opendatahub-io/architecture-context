workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models, manages API keys, queries LLM inference endpoints"
        platformadmin = person "Platform Admin" "Manages AITenant CRs and platform configuration"

        maas = softwareSystem "Models-as-a-Service (MaaS)" "Kubernetes-native platform for exposing LLM inference endpoints with policy management, API key auth, subscriptions, and token rate limiting" {
            maasController = container "maas-controller" "Reconciles MaaS CRDs into Gateway API HTTPRoutes, Kuadrant AuthPolicies, and TokenRateLimitPolicies" "Go Operator (controller-runtime)"
            maasApi = container "maas-api" "Per-tenant API service for API key management, subscription selection, model discovery, and tenant metadata" "Go HTTP Service (Gin)"
            payloadProcessing = container "payload-processing" "Pre/post-auth request/response payload processing via Envoy ext_proc" "Go gRPC Service"
            webhookServer = container "Webhook Server" "Validates AITenant placement, MaaSSubscription/MaaSAuthPolicy namespace initialization" "Go (controller-runtime webhook)"
        }

        kuadrant = softwareSystem "Kuadrant" "API gateway policy engine providing AuthPolicy, TokenRateLimitPolicy, and TelemetryPolicy" "External"
        authorino = softwareSystem "Authorino" "Authentication/authorization enforcement at gateway level; credential stripping and identity injection" "External"
        limitador = softwareSystem "Limitador" "Token rate limiting enforcement per-model per-subscription" "External"
        kserve = softwareSystem "KServe" "LLM inference serving platform (LLMInferenceService CRD)" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute resources for ingress" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "EnvoyFilter for ext_proc pipeline, mTLS, telemetry" "External"
        postgresql = softwareSystem "PostgreSQL" "API key hash storage, CRUD operations, schema migrations" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "CRD operations, TokenReview, SubjectAccessReview, informers" "External"
        oidcProvider = softwareSystem "OpenShift / OIDC Provider" "User authentication via OIDC tokens" "External"
        externalModels = softwareSystem "External Model Providers" "OpenAI, Anthropic, etc. for external LLM inference" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and usage logging" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from controller, API, and payload-processing" "External"
        odhOperator = softwareSystem "ODH/RHOAI Platform Operator" "Platform lifecycle management (DSCInitialization)" "Internal Platform"

        # User interactions
        datascientist -> maas "Inference requests via API key (sk-oai-*), API key management, model discovery" "HTTPS/443"
        platformadmin -> maas "Creates AITenant, MaaSModelRef, MaaSSubscription, MaaSAuthPolicy CRs" "kubectl / HTTPS"

        # MaaS internal relationships
        maasController -> maasApi "Deploys per-tenant instances; revokes API keys on tenant deletion" "HTTPS/8443"
        maasController -> webhookServer "Embedded in controller process" ""

        # MaaS → External dependencies
        maasController -> kuadrant "Creates AuthPolicy, TokenRateLimitPolicy, TelemetryPolicy CRs" "CRD CRUD"
        maasController -> gatewayAPI "Creates HTTPRoutes, validates Gateway references" "CRD CRUD"
        maasController -> istio "Creates EnvoyFilter for ext_proc pipeline, DestinationRules, ServiceEntries" "CRD CRUD"
        maasController -> k8sAPI "CRD reconciliation, namespace/RBAC management, informers" "HTTPS/443"
        maasController -> kserve "Watches LLMInferenceService readiness for MaaSModelRef status" "CRD Watch"
        maasController -> odhOperator "Watches DSCInitialization for platform lifecycle" "CRD Watch"

        maasApi -> postgresql "API key hash CRUD, schema migrations" "TCP/5432 TLS"
        maasApi -> k8sAPI "TokenReview, SubjectAccessReview, MaaS CR informers" "HTTPS/443"
        maasApi -> otlpCollector "Distributed trace export" "gRPC/4317"

        authorino -> maasApi "API key validation callback, subscription selection" "HTTPS/8443"

        payloadProcessing -> istio "Receives ext_proc requests from Envoy via EnvoyFilter" "gRPC/9004 mTLS"

        maas -> externalModels "Proxies inference to external providers via Gateway" "HTTPS/443"
        authorino -> oidcProvider "Validates OIDC/OpenShift tokens" "HTTPS/443"

        prometheus -> maas "Scrapes metrics from controller (8080), API (9090), payload-processing (9005)" "HTTP"
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
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
