workspace {
    model {
        dataScientist = person "Data Scientist" "Creates model references, manages subscriptions, deploys inference endpoints"
        platformAdmin = person "Platform Admin" "Configures tenants, auth policies, and subscription rate limits"
        apiConsumer = person "API Consumer" "Invokes model inference via OpenAI-compatible API with Bearer token or API key"

        maas = softwareSystem "Models as a Service (MaaS)" "Kubernetes-native platform for managing inference model endpoints with policy-based access control, API key management, and token-based rate limiting" {
            maasController = container "maas-controller" "Manages MaaS CRDs, reconciles Kuadrant policies, deploys maas-api platform workloads via Tenant reconciler" "Go Operator (controller-runtime)" {
                modelRefReconciler = component "MaaSModelRefReconciler" "Discovers model backends, creates HTTPRoutes for Gateway API routing"
                authPolicyReconciler = component "MaaSAuthPolicyReconciler" "Translates user/group access rules into Kuadrant AuthPolicy CRs with CEL expressions"
                subscriptionReconciler = component "MaaSSubscriptionReconciler" "Translates token rate limits into Kuadrant TokenRateLimitPolicy CRs"
                tenantReconciler = component "TenantReconciler" "Kustomize-based platform deploy pipeline for maas-api infrastructure"
                aiTenantReconciler = component "AITenantReconciler" "Bootstraps tenant slices: namespace, Tenant CR, RBAC"
                externalModelReconciler = component "ExternalModelReconciler" "Creates ServiceEntry, DestinationRule, HTTPRoute for external providers"
                webhookServer = component "Webhook Server" "Validates AITenant, MaaSSubscription, MaaSAuthPolicy resources"
            }
            maasAPI = container "maas-api" "OpenAI-compatible model discovery, API key lifecycle management, subscription selection, Authorino callbacks" "Go HTTP Service (Gin)" {
                modelDiscovery = component "Model Discovery" "GET /v1/models - OpenAI-compatible model listing with access validation"
                apiKeyManager = component "API Key Manager" "CRUD + validation for API keys with SHA-256 hashing"
                subscriptionSelector = component "Subscription Selector" "Authorino callback for subscription-based routing"
                internalCallbacks = component "Internal Callbacks" "NetworkPolicy-protected endpoints for Authorino evaluation"
            }
            payloadProcessing = container "payload-processing" "Envoy ext_proc gRPC service for request/response processing pipeline" "Go gRPC Service"
        }

        kuadrant = softwareSystem "Kuadrant / RHCL" "Policy engine: AuthPolicy, TokenRateLimitPolicy, TelemetryPolicy" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization service with HTTP callback support" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for API key storage and lifecycle management" "External"
        gatewayAPI = softwareSystem "OpenShift Gateway API" "Gateway controller for HTTPRoute traffic routing (openshift-ingress)" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "EnvoyFilter, DestinationRule, ServiceEntry, Telemetry" "External"
        kserve = softwareSystem "KServe" "LLMInferenceService backend for internally-hosted model endpoints" "External"
        odhOperator = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator that enables/disables MaaS via DataScienceCluster" "Internal ODH"
        externalLLM = softwareSystem "External LLM Providers" "OpenAI, Anthropic, and other external inference providers" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from maas-api (9090/TCP) and maas-controller (8080/TCP)" "External"
        coo = softwareSystem "Cluster Observability Operator" "Optional Perses dashboards and datasources for observability" "External"

        # User interactions
        apiConsumer -> maas "Invokes model inference" "HTTPS/443 (Bearer token / API key)"
        dataScientist -> maas "Creates MaaSModelRef, ExternalModel CRs" "kubectl / API"
        platformAdmin -> maas "Configures Tenant, AITenant, MaaSAuthPolicy, MaaSSubscription" "kubectl / API"

        # MaaS → External systems
        maas -> kuadrant "Creates AuthPolicy, TokenRateLimitPolicy, TelemetryPolicy CRs" "CRD Create/Update"
        maas -> authorino "HTTP callbacks for API key validation and subscription selection" "HTTPS/8443"
        maas -> postgresql "Stores and queries API keys" "PostgreSQL/5432 TLS"
        maas -> gatewayAPI "Creates HTTPRoutes, references Gateway" "CRD Create/Update"
        maas -> istio "Creates EnvoyFilter, DestinationRule, ServiceEntry, Telemetry" "CRD Create/Update"
        maas -> kserve "Reads LLMInferenceService to discover model endpoints" "CRD Watch"
        maas -> externalLLM "Proxies inference requests to external providers" "HTTPS/443"

        # External → MaaS
        odhOperator -> maas "Enables/disables MaaS component" "DataScienceCluster CRD"
        authorino -> maas "AuthPolicy evaluation callbacks" "HTTPS/8443"
        prometheus -> maas "Scrapes metrics" "HTTP/9090, HTTP/8080"
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

        component maasController "ControllerComponents" {
            include *
            autoLayout
        }

        component maasAPI "APIComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
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
