workspace {
    model {
        // Actors
        datascientist = person "Data Scientist" "Creates API keys, lists models, submits inference requests"
        platformadmin = person "Platform Admin" "Configures Tenant, models, auth policies, subscriptions"

        // Main system
        maas = softwareSystem "Models as a Service (MaaS)" "Multi-tenant API gateway for serving LLM models with token-based rate limiting, API key management, and fine-grained access control" {
            maasController = container "maas-controller" "Manages Tenant lifecycle, model routing (HTTPRoute), auth policies (Kuadrant AuthPolicy), subscriptions (TokenRateLimitPolicy), ExternalModel networking (Istio)" "Go Operator (controller-runtime)" "Operator"
            maasApi = container "maas-api" "REST API for API key management, model discovery, subscription selection, and Authorino validation callbacks" "Go Service (Gin HTTP)" "Service"
            payloadProcessing = container "payload-processing" "EnvoyFilter external processor for model name extraction, API translation, provider resolution, and credential injection" "Go Service (ext_proc)" "Sidecar"
            postgresqlDb = container "PostgreSQL" "API key hash storage (SHA-256 with per-key salt), schema managed by golang-migrate" "PostgreSQL" "Database"
        }

        // External dependencies
        kuadrant = softwareSystem "Kuadrant / RHCL" "API gateway policy engine providing AuthPolicy and TokenRateLimitPolicy" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization evaluation with credential stripping (via Kuadrant)" "External"
        limitador = softwareSystem "Limitador" "Token-based rate limiting enforcement (via Kuadrant)" "External"
        kserve = softwareSystem "KServe" "LLMInferenceService model serving backend for internal models" "External"
        gatewayApi = softwareSystem "Gateway API" "HTTPRoute-based model endpoint exposure via shared Gateway" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for ServiceEntry, DestinationRule, EnvoyFilter, Telemetry" "External"
        openshift = softwareSystem "OpenShift" "Platform providing Routes, Authentication config, serving certs, monitoring" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning (optional)" "External"

        // Internal ODH dependencies
        platformOperator = softwareSystem "RHOAI/ODH Platform Operator" "Enables MaaS via DataScienceCluster.modelsAsService and deploys maas-controller" "Internal ODH"
        coo = softwareSystem "Cluster Observability Operator" "Perses dashboards and datasources (optional)" "Internal ODH"

        // External services
        extLlmProviders = softwareSystem "External LLM Providers" "OpenAI, Anthropic, and other external model APIs" "External Service"

        // Relationships - Actors
        datascientist -> maas "Creates API keys, lists models, submits inference requests" "HTTPS/443"
        platformadmin -> maas "Configures Tenant, MaaSModelRef, ExternalModel, MaaSAuthPolicy, MaaSSubscription CRs" "kubectl/HTTPS"

        // Relationships - Internal
        maasController -> maasApi "Deploys via Tenant reconciler (kustomize rendering)" "K8s API"
        maasController -> payloadProcessing "Deploys into gateway namespace" "K8s API"
        maasApi -> postgresqlDb "API key hash storage, CRUD, schema migrations" "PostgreSQL/5432"

        // Relationships - External dependencies
        maas -> kuadrant "Creates AuthPolicy, TokenRateLimitPolicy per model" "CRD CRUD"
        maas -> authorino "API key validation callbacks, subscription selection" "HTTPS/8443"
        maas -> limitador "Token rate limit enforcement" "gRPC/mTLS"
        maas -> kserve "Watches LLMInferenceService, discovers HTTPRoutes, probes model endpoints" "CRD Watch + HTTPS/443"
        maas -> gatewayApi "Creates HTTPRoutes for model endpoints" "CRD CRUD"
        maas -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter for external models" "CRD CRUD"
        maas -> openshift "Reads Authentication config (OIDC issuer), uses service-ca certs" "CRD Read"
        maas -> extLlmProviders "Forwards inference requests to external LLM APIs" "HTTPS/443, TLS SIMPLE"

        // Relationships - Platform
        platformOperator -> maas "Deploys maas-controller when modelsAsService enabled" "CRD (DataScienceCluster)"
        maas -> coo "Deploys Perses dashboards (optional)" "CRD CRUD"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                background #50a0d2
                color #ffffff
            }
            element "Sidecar" {
                background #6ab0e2
                color #ffffff
            }
            element "Database" {
                background #9673a6
                color #ffffff
                shape Cylinder
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
