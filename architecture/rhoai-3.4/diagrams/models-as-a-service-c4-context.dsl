workspace {
    model {
        dataScientist = person "Data Scientist" "Creates models, manages API keys, and consumes inference endpoints"
        appDeveloper = person "Application Developer" "Integrates LLM inference into applications via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Configures Tenant CR, manages subscriptions and auth policies"

        maas = softwareSystem "Models as a Service (MaaS)" "Multi-tenant platform for exposing LLM models as OpenAI-compatible API endpoints with API key management, authorization, and rate limiting" {
            maasController = container "maas-controller" "Manages CRDs (Tenant, MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, ExternalModel), creates Kuadrant policies, deploys platform via Kustomize/SSA" "Go Operator (controller-runtime)" {
                tenantReconciler = component "Tenant Reconciler" "Deploys maas-api and payload-processing via Kustomize rendering and Server-Side Apply" "Go"
                modelRefReconciler = component "MaaSModelRef Reconciler" "Validates HTTPRoutes, updates status with model endpoint" "Go"
                authPolicyReconciler = component "MaaSAuthPolicy Reconciler" "Aggregates per-model AuthPolicy (Kuadrant) from individual MaaSAuthPolicy CRs" "Go"
                subscriptionReconciler = component "MaaSSubscription Reconciler" "Aggregates per-model TokenRateLimitPolicy from individual MaaSSubscription CRs" "Go"
                externalModelReconciler = component "ExternalModel Reconciler" "Creates Service, ServiceEntry, DestinationRule, HTTPRoute for external LLM providers" "Go"
            }

            maasAPI = container "maas-api" "REST API for model discovery, API key lifecycle, and internal Authorino callbacks" "Go REST Service (Gin)" {
                modelsHandler = component "Models Handler" "OpenAI-compatible /v1/models endpoint with model discovery" "Go"
                apiKeysHandler = component "API Keys Handler" "CRUD for API keys (sk-oai-* format) with SHA-256 hashing" "Go"
                subscriptionHandler = component "Subscription Handler" "Subscription listing and selection" "Go"
                internalCallbacks = component "Internal Callbacks" "Authorino HTTP callbacks for key validation and subscription resolution" "Go"
            }

            payloadProcessing = container "payload-processing" "Envoy ext_proc for request transformation: model extraction, provider resolution, API translation, credential injection" "Go gRPC Service (Envoy ext_proc)"
        }

        kuadrant = softwareSystem "Kuadrant" "Policy engine providing authentication (Authorino), authorization (OPA), and rate limiting (Limitador)" "External" {
            authorino = container "Authorino" "Identity verification, API key validation via HTTP callback, OPA authorization" "Go"
            limitador = container "Limitador" "Token-based rate limit enforcement" "Rust"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform with LLMInferenceService support" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based ingress with OpenShift Gateway Controller" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, EnvoyFilter injection, and external service routing" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for API key storage (hash, metadata, subscriptions)" "External"
        openshift = softwareSystem "OpenShift" "Cluster platform providing Gateway controller, service-ca, OAuth, and OIDC" "External"
        externalLLM = softwareSystem "External LLM Providers" "Third-party model APIs (OpenAI, Anthropic, etc.) accessed via Istio ServiceEntry" "External"
        perses = softwareSystem "Perses" "Observability dashboards (optional, requires Cluster Observability Operator)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from controller, payload-processing, Envoy, Authorino, Limitador" "External"

        # User interactions
        dataScientist -> maas "Creates models, manages API keys, runs inference" "HTTPS/443"
        appDeveloper -> maas "Sends inference requests via OpenAI-compatible API" "HTTPS/443 Bearer sk-oai-*"
        platformAdmin -> maas "Configures Tenant, MaaSAuthPolicy, MaaSSubscription CRs" "kubectl"

        # MaaS to dependencies
        maas -> kuadrant "AuthPolicy and TokenRateLimitPolicy management, API key validation callbacks" "CRD + HTTPS/8443"
        maas -> kserve "Watches LLMInferenceService status, routes inference traffic" "CRD watch + HTTPS"
        maas -> gatewayAPI "Creates HTTPRoutes, validates Gateway existence" "CRD"
        maas -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter, Telemetry" "CRD"
        maas -> postgresql "Stores API key hashes, metadata, subscription bindings" "TCP/5432"
        maas -> openshift "Reads cluster OIDC audience, uses service-ca for TLS certs" "HTTPS/6443"
        maas -> externalLLM "Routes inference to external providers via ServiceEntry" "HTTPS/443"
        maas -> perses "Creates PersesDashboard and PersesDatasource CRs" "CRD"
        prometheus -> maas "Scrapes metrics from controller (8080), payload-processing (9005), Envoy (15090)" "HTTP"

        # Internal interactions
        kuadrant -> maasAPI "HTTP callbacks for API key validation and subscription resolution" "HTTPS/8443"
        maasController -> maasAPI "Deploys via Tenant reconciler (Kustomize + SSA)" "Kubernetes API"
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

        component maasController "MaaSController" {
            include *
            autoLayout
        }

        component maasAPI "MaaSAPI" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
