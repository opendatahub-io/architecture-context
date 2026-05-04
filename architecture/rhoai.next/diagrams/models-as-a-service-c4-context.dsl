workspace {
    model {
        user = person "Data Scientist" "Creates model references, policies, subscriptions; uses API keys for inference"
        platformAdmin = person "Platform Admin" "Configures Tenant, manages ExternalModels, monitors platform"

        maas = softwareSystem "Models as a Service (MaaS)" "Kubernetes-native platform for managed AI/ML model access with auth, rate limiting, and multi-provider support" {
            controller = container "maas-controller" "Manages CRD lifecycle, deploys platform infrastructure via kustomize, creates Kuadrant policies and Istio resources" "Go Operator (controller-runtime)"
            api = container "maas-api" "API key management, model discovery, subscription selection, Authorino callbacks" "Go HTTP Service (Gin)"
            bbr = container "payload-processing (BBR)" "Envoy ext-proc for model extraction, provider resolution, API translation, credential injection" "Go gRPC Service"
            db = container "PostgreSQL" "API key storage (SHA-256 hashed), management, cleanup" "PostgreSQL" "Database"
        }

        gateway = softwareSystem "MaaS Gateway" "Gateway API ingress (maas-default-gateway) for model endpoints" "Infrastructure"
        kuadrant = softwareSystem "Kuadrant" "API gateway policy engine: AuthPolicy, TokenRateLimitPolicy, RateLimitPolicy" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization: API keys, OIDC, Kubernetes tokens" "External"
        limitador = softwareSystem "Limitador" "Distributed token-based rate limiting" "External"
        kserve = softwareSystem "KServe" "Internal ML model serving (LLMInferenceService)" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh: ServiceEntry, DestinationRule, EnvoyFilter, Telemetry" "External"
        gatewayAPI = softwareSystem "Gateway API" "Traffic routing: Gateway, HTTPRoute" "External"
        openshift = softwareSystem "OpenShift" "Platform: Gateway controller, serving certs, Routes, Authentication" "External"
        extLLM = softwareSystem "External LLM Providers" "Third-party LLM APIs: OpenAI, Anthropic, etc." "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator enables modelsAsService component" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Metrics collection and alerting" "External"
        perses = softwareSystem "Perses" "Dashboard deployment (Grafana alternative)" "External"

        # User interactions
        user -> maas "Creates MaaSAuthPolicy, MaaSSubscription, API keys via kubectl/API"
        user -> gateway "Sends inference requests with API key or token" "HTTPS/443"
        platformAdmin -> maas "Configures Tenant, creates ExternalModel, MaaSModelRef" "kubectl"

        # Internal relationships
        controller -> api "Deploys via kustomize (Tenant reconciler)"
        controller -> bbr "Deploys via kustomize (Tenant reconciler)"
        api -> db "Stores and retrieves API keys" "PostgreSQL/5432"

        # Gateway flow
        gateway -> bbr "Envoy ext-proc for request transformation" "gRPC/9004"
        gateway -> authorino "Request authentication and authorization"
        gateway -> limitador "Token rate limit enforcement"
        gateway -> kserve "Forward inference to internal models" "HTTPS"
        gateway -> extLLM "Forward inference to external providers" "HTTPS/443"

        # Auth callbacks
        authorino -> api "API key validation, subscription selection callbacks" "HTTPS/8443"

        # Controller integrations
        controller -> kuadrant "Creates aggregated AuthPolicy and TokenRateLimitPolicy per model" "Kubernetes API"
        controller -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter for external models" "Kubernetes API"
        controller -> gatewayAPI "Manages HTTPRoutes per model, validates Gateway" "Kubernetes API"
        controller -> openshift "Discovers service account issuer URL for OIDC" "HTTPS/443"

        # Platform dependencies
        rhoaiOperator -> maas "Enables modelsAsService component via DataScienceCluster"
        maas -> prometheus "Exposes controller, BBR, and gateway metrics" "HTTP/8080, 9005, 15090"
        maas -> perses "Deploys dashboards (graceful if CRD missing)" "Kubernetes API"

        # BBR integrations
        bbr -> extLLM "Injects provider credentials, translates API formats"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #f5a623
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
