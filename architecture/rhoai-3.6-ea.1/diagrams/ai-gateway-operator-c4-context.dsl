workspace {
    model {
        admin = person "Platform Admin" "Configures AI Gateway component via AIGateway CR"
        datascientist = person "Data Scientist" "Deploys and consumes ML models via MaaS"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Kubernetes operator managing Gateway API routing, Kuadrant auth/rate-limiting, Istio mesh, and llm-d batch gateway for model-as-a-service workloads" {
            controller = container "AIGateway Controller" "Reconciles AIGateway CR through ordered action chain: init, RBAC migration, upgrade, kustomize render, deploy, status, GC" "Go controller-runtime"
            configLoader = container "Config Loader" "Loads configuration from mounted ConfigMaps and ODH_MODULE_OPERATOR_* environment variables" "Viper"
            kustomizeRenderer = container "Kustomize Renderer" "Renders manifests from /manifests/ directory for deployment" "Kustomize"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator providing SDK primitives and DSCInitialization" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService and LLMInferenceService CRs" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant" "API management providing AuthPolicies and TokenRateLimitPolicies" "External"
        istio = softwareSystem "Istio" "Service mesh for DestinationRules, EnvoyFilters, ServiceEntries" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        llmd = softwareSystem "llm-d Batch Gateway" "Batch inference gateway for LLM workloads" "External"
        prometheus = softwareSystem "Prometheus / Monitoring" "Metrics collection via ServiceMonitors, PodMonitors, PrometheusRules" "External"
        otel = softwareSystem "OpenTelemetry" "Distributed tracing and observability via OpenTelemetryCollectors" "External"
        perses = softwareSystem "Perses" "Dashboard and datasource management for observability" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "Infrastructure"

        admin -> aiGatewayOperator "Creates/updates AIGateway CR via kubectl"
        datascientist -> kserve "Deploys models via InferenceService"

        aiGatewayOperator -> k8sAPI "All resource CRUD operations" "HTTPS/6443, SA Token, TLS 1.2+"
        aiGatewayOperator -> odhOperator "Uses SDK primitives (Go library), watches DSCInitialization"
        aiGatewayOperator -> kserve "Watches InferenceService/LLMInferenceService CRs (read-only)"
        aiGatewayOperator -> gatewayAPI "Creates/manages HTTPRoutes, Gateways, ReferenceGrants"
        aiGatewayOperator -> kuadrant "Creates/manages AuthPolicies, TokenRateLimitPolicies, RateLimitPolicies"
        aiGatewayOperator -> istio "Creates/manages DestinationRules, EnvoyFilters, ServiceEntries"
        aiGatewayOperator -> certManager "Creates/manages Certificate CRs for TLS"
        aiGatewayOperator -> llmd "Creates/manages LLMBatchGateway CRs (when spec.batchGateway.managementState=Managed)"
        aiGatewayOperator -> prometheus "Creates/manages ServiceMonitors, PodMonitors, PrometheusRules"
        aiGatewayOperator -> otel "Creates/manages OpenTelemetryCollectors"
        aiGatewayOperator -> perses "Creates/manages PersesDashboards, PersesDatasources"
    }

    views {
        systemContext aiGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayOperator "Containers" {
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
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
