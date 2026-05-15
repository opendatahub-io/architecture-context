workspace {
    model {
        datascientist = person "Data Scientist" "Creates subscriptions and uses LLM models via API keys"
        platformadmin = person "Platform Admin" "Configures Tenant, creates MaaSModelRef, MaaSAuthPolicy, MaaSSubscription CRs"

        maas = softwareSystem "Models as a Service (MaaS)" "Subscription-based access control, API key management, token rate limiting, and policy-driven governance for LLM inference services" {
            maasController = container "maas-controller" "Reconciles Tenant, MaaSModelRef, MaaSSubscription, MaaSAuthPolicy, ExternalModel CRs; deploys operands via kustomize SSA; creates Kuadrant policies and Istio resources" "Go Operator (controller-runtime)"
            maasAPI = container "maas-api" "OpenAI-compatible REST API for key management, model discovery, subscription selection; internal Authorino callbacks" "Go REST Service (Gin)" {
                healthHandler = component "Health Handler" "/health endpoint" "Go HTTP Handler"
                modelsHandler = component "Models Handler" "/v1/models - OpenAI-compatible model listing" "Go HTTP Handler"
                apiKeysHandler = component "API Keys Handler" "/v1/api-keys/* - Create, search, revoke API keys" "Go HTTP Handler"
                subscriptionHandler = component "Subscription Handler" "/v1/subscriptions - List and select subscriptions" "Go HTTP Handler"
                internalCallbacks = component "Internal Callbacks" "/internal/v1/* - Authorino validation and subscription selection" "Go HTTP Handler"
                metricsHandler = component "Metrics Handler" "/metrics on :9090 - Prometheus metrics" "Go HTTP Handler"
            }
            payloadProcessing = container "payload-processing" "BBR ext_proc: body-based routing, model resolution, API translation, credential injection" "Go gRPC Service (Envoy ext_proc)"
        }

        maasGateway = softwareSystem "MaaS Gateway" "Gateway API (openshift-default) with TLS termination, HTTPRoute-based model routing" "Infrastructure"

        kuadrant = softwareSystem "Kuadrant" "Policy-driven API management: AuthPolicy (Authorino) for authentication, TokenRateLimitPolicy (Limitador) for rate limiting, TelemetryPolicy for metrics" "External"
        kserve = softwareSystem "KServe" "LLMInferenceService CRDs for model serving backends" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh: EnvoyFilter (ext_proc registration), DestinationRule (TLS origination), Telemetry (per-subscription metrics), ServiceEntry (external models)" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway resources for traffic routing" "External"
        openshift = softwareSystem "OpenShift" "Platform: GatewayClass implementation, OAuth/OIDC provider, Route integration" "External"
        postgresql = softwareSystem "PostgreSQL" "Durable storage for API keys (SHA-256 hashed), migration management" "External"
        extProviders = softwareSystem "External Model Providers" "Third-party LLM APIs: OpenAI, Anthropic, etc." "External"
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Enables MaaS via DataScienceCluster.modelsAsService field; deploys maas-controller" "Internal ODH"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via PodMonitor CRDs" "External"
        perses = softwareSystem "Perses (via COO)" "Optional observability dashboards (PersesDashboard, PersesDatasource)" "External"

        # Relationships
        datascientist -> maasGateway "Creates API keys, lists models, sends inference requests" "HTTPS/443 TLS 1.3"
        platformadmin -> maas "Creates Tenant, MaaSModelRef, MaaSSubscription, MaaSAuthPolicy CRs" "kubectl / HTTPS"

        maasGateway -> kuadrant "Auth and rate limit enforcement" "Wasm → gRPC"
        maasGateway -> payloadProcessing "ext_proc body inspection" "gRPC/9004 TLS"
        maasGateway -> maasAPI "Routes API requests" "HTTP/8080"
        maasGateway -> kserve "Routes inference requests" "HTTPS/443"
        maasGateway -> extProviders "Routes external model requests" "HTTPS/443"

        kuadrant -> maasAPI "API key validation and subscription selection callbacks" "HTTP(S)/8080-8443"

        maasController -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy per model" "CRD Create/Patch"
        maasController -> istio "Creates EnvoyFilter, DestinationRule, Telemetry, ServiceEntry" "CRD Create"
        maasController -> gatewayAPI "Creates HTTPRoute per model and maas-api" "CRD Create"
        maasController -> kserve "Watches LLMInferenceService readiness" "CRD Watch"
        maasController -> openshift "Reads OIDC issuer for external auth" "HTTPS/443"

        maasAPI -> postgresql "API key CRUD (hash-based storage)" "PostgreSQL/5432 TLS"
        payloadProcessing -> extProviders "Proxied inference with injected credentials" "HTTPS/443"

        odhOperator -> maas "Enables/disables via DSC.modelsAsService" "CRD"
        prometheus -> maasAPI "Scrapes metrics" "HTTP/9090"
        prometheus -> maasController "Scrapes metrics" "HTTP/8080"
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

        component maasAPI "MaaSAPIComponents" {
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
            element "Infrastructure" {
                background #e67e22
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
