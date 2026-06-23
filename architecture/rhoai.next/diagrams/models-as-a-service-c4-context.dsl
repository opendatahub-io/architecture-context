workspace {
    model {
        dataScientist = person "Data Scientist" "Creates models, manages subscriptions, and consumes inference APIs"
        platformAdmin = person "Platform Admin" "Configures tenants, policies, and platform governance"

        maas = softwareSystem "Models as a Service (MaaS)" "Multi-tenant platform for exposing LLM models as governed, subscription-based services with API key management, token rate limiting, and policy-driven authorization" {
            maasController = container "maas-controller" "Reconciles MaaS CRDs into Gateway API HTTPRoutes, Kuadrant policies, Istio resources, and deploys maas-api per tenant" "Go Operator (controller-runtime)"
            maasApi = container "maas-api" "REST API for API key management, model listing (OpenAI-compatible), subscription selection, and Authorino callback handling" "Go REST Service (Gin)"
            payloadProcessing = container "payload-processing" "Post-auth Envoy ext_proc for request/response transformation: API translation, provider credential injection, model resolution" "Go gRPC Service (ext_proc)"
            payloadPreProcessing = container "payload-pre-processing" "Pre-auth Envoy ext_proc for model name extraction from request body to X-Gateway-Model-Name header" "Go gRPC Service (ext_proc)"
            webhookServer = container "Webhook Server" "Validates AITenant, MaaSSubscription, MaaSAuthPolicy CRs on creation" "Kubernetes Validating Webhook"
        }

        kuadrant = softwareSystem "Kuadrant / RHCL" "API management: Authorino for authentication/authorization, Limitador for token rate limiting" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic routing via openshift-default GatewayClass" "External"
        istio = softwareSystem "Istio Service Mesh" "mTLS, DestinationRules for TLS origination, EnvoyFilters for ext_proc, ServiceEntries for external providers" "External"
        postgresql = softwareSystem "PostgreSQL" "API key hash storage (zero-knowledge SHA-256), tenant-scoped CRUD" "External"
        kserve = softwareSystem "KServe" "LLMInferenceService model serving, provides model endpoints and HTTPRoutes" "Internal ODH"
        openshift = softwareSystem "OpenShift" "Platform runtime: service certificates, OAuth, cluster OIDC issuer" "External"
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Component lifecycle management, ModelsAsService feature gate in DataScienceCluster CR" "Internal ODH"

        externalLLM = softwareSystem "External LLM Providers" "OpenAI, Anthropic, and other hosted LLM APIs" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor and ServiceMonitor" "External"

        # User interactions
        dataScientist -> maas "Creates MaaSModelRef, MaaSSubscription, manages API keys" "kubectl / API"
        platformAdmin -> maas "Creates AITenants, MaaSAuthPolicies, configures governance" "kubectl / API"
        dataScientist -> maas "Sends inference requests" "HTTPS/443 Bearer token"

        # MaaS internal
        maasController -> maasApi "Deploys per tenant via kustomize + SSA" "Kubernetes API"
        maasApi -> webhookServer "Co-deployed (shared controller process)" ""

        # MaaS → External
        maas -> kuadrant "Creates AuthPolicies, TokenRateLimitPolicies, TelemetryPolicies; Authorino callbacks for key validation and subscription selection" "CRD CRUD / HTTPS/8443"
        maas -> gatewayAPI "Creates per-model HTTPRoutes, validates Gateway references" "CRD CRUD"
        maas -> istio "Creates ServiceEntries, DestinationRules, EnvoyFilters for ext_proc pipeline" "CRD CRUD"
        maas -> postgresql "API key hash storage: create, validate, revoke, cleanup" "TCP/5432 TLS"
        maas -> kserve "Discovers LLMInferenceService endpoints and HTTPRoutes" "CRD Watch"
        maas -> openshift "Auto-detects cluster OIDC issuer, uses service certificates" "API Read"
        maas -> externalLLM "Forwards inference requests via gateway with injected credentials" "HTTPS/443 TLS 1.2+"
        maas -> prometheus "Exposes metrics (maas-api 9090/TCP, controller 8080/TCP)" "HTTP scrape"

        odhOperator -> maas "Enables via DataScienceCluster ModelsAsService feature gate" "CRD"

        # Gateway flow (runtime)
        gatewayAPI -> payloadPreProcessing "Pre-auth: model name extraction" "gRPC/9004 TLS"
        gatewayAPI -> kuadrant "Auth evaluation (OIDC/API key)" "Internal"
        gatewayAPI -> payloadProcessing "Post-auth: API translation, credential injection" "gRPC/9004 TLS"
    }

    views {
        systemContext maas "SystemContext" {
            include *
            autoLayout
            description "Models as a Service in its ecosystem — multi-tenant LLM governance platform"
        }

        container maas "Containers" {
            include *
            autoLayout
            description "Internal structure of the MaaS platform showing controller, API, and payload processing components"
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
