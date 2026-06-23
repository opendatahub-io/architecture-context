workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and consumes AI/ML model endpoints via API keys or OpenShift tokens"
        platformAdmin = person "Platform Admin" "Manages model references, subscriptions, auth policies, and multi-tenant configuration"

        maas = softwareSystem "Models as a Service (MaaS)" "Comprehensive platform for exposing AI/ML models as managed API endpoints with policy management, subscription-based access control, and API key management" {
            maasController = container "maas-controller" "Manages MaaS CRDs, reconciles Kuadrant policies, deploys maas-api, handles multi-tenancy bootstrapping" "Go Operator (controller-runtime)" {
                modelRefReconciler = component "MaaSModelRef Reconciler" "Creates per-model HTTPRoutes, tracks governance readiness" "Go"
                authPolicyReconciler = component "MaaSAuthPolicy Reconciler" "Translates MaaSAuthPolicy into Kuadrant AuthPolicies" "Go"
                subscriptionReconciler = component "MaaSSubscription Reconciler" "Creates TokenRateLimitPolicies from subscription specs" "Go"
                aiTenantReconciler = component "AITenant Reconciler" "Bootstraps per-tenant namespace, RBAC, gateway reference" "Go"
                tenantReconciler = component "Tenant Reconciler" "Full platform reconcile via kustomize pipeline" "Go"
                externalModelReconciler = component "ExternalModel Reconciler" "Translates MaaS ExternalModels to inference-domain CRs" "Go"
                lifecycleReconciler = component "Lifecycle Reconciler" "Creates Config singleton, manages ownership graph" "Go"
                webhookServer = component "Webhook Server" "Validates AITenant, MaaSAuthPolicy, MaaSSubscription namespace" "Go"
            }

            maasAPI = container "maas-api" "OpenAI-compatible REST API for model discovery, API key management, subscription queries, and Authorino validation callbacks" "Go (Gin Framework)" {
                modelsHandler = component "Models Handler" "GET /v1/models - lists accessible models with subscription filtering" "Go"
                apiKeysHandler = component "API Keys Handler" "CRUD for API keys (sk-oai-* format, SHA-256 hashed)" "Go"
                subscriptionHandler = component "Subscriptions Handler" "GET /v1/subscriptions - lists accessible subscriptions" "Go"
                internalValidate = component "Internal Validate" "POST /internal/v1/api-keys/validate - Authorino callback" "Go"
                internalSelect = component "Internal Select" "POST /internal/v1/subscriptions/select - Authorino callback" "Go"
            }

            payloadProcessing = container "payload-processing" "Request/response transformation: model header extraction, API format translation, credential injection" "Envoy ext_proc (gRPC)"
        }

        gatewayAPI = softwareSystem "Gateway API (Envoy Gateway)" "Platform ingress: Gateway CR, HTTPRoute-based traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant" "Authentication and authorization enforcement (AuthPolicy, TokenRateLimitPolicy)" "External" {
            authorino = container "Authorino" "Authentication evaluation engine with HTTP callbacks" "External"
            limitador = container "Limitador" "Token-based rate limiting enforcement" "External"
        }
        kserve = softwareSystem "KServe" "ML model serving platform (LLMInferenceService for model backends)" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "API key storage (api_keys table with schema migrations)" "External"
        openshift = softwareSystem "OpenShift" "Container platform: GatewayClass, service CA, Routes, RBAC, Authentication" "External"
        istio = softwareSystem "Istio / Service Mesh" "EnvoyFilter for ext_proc, DestinationRules, Telemetry, mTLS" "External"
        externalLLM = softwareSystem "External LLM Providers" "OpenAI, Anthropic, and other external model inference APIs" "External"
        certManager = softwareSystem "cert-manager / OpenShift Service CA" "TLS certificate provisioning for services and webhooks" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator: enables modelsAsService component, deploys maas-controller" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor, ServiceMonitor, PrometheusRule" "External"

        # Person interactions
        dataScientist -> maas "Creates API keys, queries models, sends inference requests" "HTTPS/443"
        platformAdmin -> maas "Creates MaaSModelRef, MaaSSubscription, MaaSAuthPolicy, AITenant CRs" "kubectl/HTTPS"

        # MaaS → external systems
        maas -> gatewayAPI "Creates HTTPRoutes for per-model routing" "Kubernetes API"
        maas -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy CRs" "Kubernetes API"
        maas -> kserve "Watches LLMInferenceService for model backend status" "Kubernetes API"
        maas -> postgresql "Stores and validates API keys" "PostgreSQL/5432"
        maas -> openshift "CRD CRUD, namespace management, RBAC, TokenReview" "HTTPS/443"
        maas -> istio "Creates EnvoyFilter, DestinationRule, Telemetry CRs" "Kubernetes API"
        maas -> externalLLM "Proxies inference requests with injected credentials" "HTTPS/443"
        maas -> certManager "Requests TLS certificates via annotations" "Kubernetes API"
        maas -> prometheus "Exposes metrics via PodMonitor/ServiceMonitor" "HTTP/9090"

        # External → MaaS
        odhOperator -> maas "Deploys maas-controller when modelsAsService is enabled" "Kubernetes API"
        kuadrant -> maas "Authorino callbacks for API key validation and subscription selection" "HTTPS/8443"

        # Internal container interactions
        maasController -> maasAPI "Deploys via Tenant reconciler kustomize pipeline" "Kubernetes API"
        maasController -> payloadProcessing "Deploys via Tenant reconciler kustomize pipeline" "Kubernetes API"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
