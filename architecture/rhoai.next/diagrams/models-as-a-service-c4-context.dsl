workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Creates subscriptions, obtains API keys, and sends inference requests to LLM models"
        admin = person "Platform Administrator" "Configures models, auth policies, subscriptions, and Tenant settings"

        maas = softwareSystem "Models as a Service (MaaS)" "Multi-tenant LLM inference gateway with model discovery, API key management, authentication, authorization, and token-based rate limiting" {
            controller = container "maas-controller" "Reconciles MaaS CRDs into HTTPRoutes, AuthPolicies, TokenRateLimitPolicies, and Istio resources; manages Tenant lifecycle and platform deployment" "Go Operator (controller-runtime)"
            api = container "maas-api" "OpenAI-compatible REST API for model listing (/v1/models), subscription management, and API key CRUD with PostgreSQL backend" "Go HTTP Service (Gin)"
            bbr = container "payload-processing (BBR)" "Envoy external processor for request/response transformation: model extraction, provider resolution, API translation, credential injection" "Go gRPC Service (ext_proc)"
            gateway = container "maas-default-gateway" "Gateway API ingress point for all model inference and management traffic" "Gateway API v1"
        }

        kuadrant = softwareSystem "Kuadrant" "Policy framework providing Authorino (AuthN/AuthZ) and Limitador (rate limiting)" "External" {
            authorino = container "Authorino" "Evaluates AuthPolicies: API key validation, Kubernetes TokenReview, OIDC JWT verification" "AuthN/AuthZ Service"
            limitador = container "Limitador" "Enforces TokenRateLimitPolicies: per-subscription token quotas" "Rate Limiter"
        }

        kserve = softwareSystem "KServe" "Serves internal LLM models via LLMInferenceService CRDs with Knative autoscaling" "Internal RHOAI"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh providing mTLS, ServiceEntry, DestinationRule, EnvoyFilter for traffic management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute and Gateway resource management" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for API key hash storage and schema migrations" "External"
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Enables MaaS component via DataScienceCluster and deploys maas-controller" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus (User Workload Monitoring)" "Metrics collection via PodMonitor and ServiceMonitor scraping" "External"
        externalProviders = softwareSystem "External Model Providers" "Third-party LLM APIs: OpenAI, Anthropic, and other providers" "External"

        # User interactions
        datascientist -> maas "Sends inference requests, lists models, manages API keys" "HTTPS/443"
        admin -> maas "Creates MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, Tenant CRDs" "kubectl/HTTPS"

        # MaaS internal
        gateway -> authorino "Authentication and authorization evaluation" "gRPC/5001 mTLS"
        gateway -> bbr "Request/response transformation" "gRPC/9004 TLS"
        gateway -> limitador "Token rate limit enforcement" "gRPC/8081 mTLS"
        authorino -> api "API key validation and subscription selection callbacks" "HTTP/8080"
        controller -> api "Deploys via Tenant reconciler kustomize" "Kubernetes API"
        controller -> bbr "Deploys via Tenant reconciler kustomize" "Kubernetes API"

        # External dependencies
        maas -> kserve "Routes inference to internal models via HTTPRoute" "HTTP(S)/8000"
        maas -> externalProviders "Routes inference to external models via ServiceEntry + TLS origination" "HTTPS/443"
        maas -> istio "ServiceEntry, DestinationRule, EnvoyFilter for mesh configuration" "CRD CRUD"
        maas -> gatewayAPI "HTTPRoute, Gateway resource management" "CRD CRUD"
        api -> postgresql "API key hash CRUD and schema migrations" "TCP/5432"
        maas -> kuadrant "AuthPolicy, TokenRateLimitPolicy, RateLimitPolicy management" "CRD CRUD"
        odhOperator -> maas "Enables modelsasservice component, deploys maas-controller" "DataScienceCluster CRD"
        prometheus -> maas "Scrapes controller, gateway, Authorino, Limitador metrics" "HTTP/8080,15090"
        bbr -> externalProviders "Reads ExternalModel CRDs to resolve providers and inject credentials" "Kubernetes API"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
