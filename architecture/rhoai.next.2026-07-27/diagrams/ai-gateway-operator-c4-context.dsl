workspace {
    model {
        admin = person "Platform Admin" "Configures AIGateway CR to enable/disable sub-components"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Kubernetes module operator managing batch inference gateway and Models-as-a-Service sub-components with integrated API governance, service mesh, and observability" {
            controller = container "AIGateway Controller" "Reconciles AIGateway CR, manages sub-component lifecycle via kustomize manifests" "Go Operator (controller-runtime 0.24.1)"
            moduleManager = container "ODH Module Manager" "Provides manifests base path resolution and module status reporting" "Go Library (opendatahub-operator/v2)"
            healthEndpoint = container "Health Probes" "/healthz, /readyz on port 8081" "HTTP"
            metricsEndpoint = container "Metrics Endpoint" "Port 8443 with TLS and TokenReview auth" "HTTPS"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTP routing via HTTPRoutes and Gateways" "External"
        kuadrant = softwareSystem "Kuadrant" "API governance with AuthPolicies and RateLimitPolicies" "External"
        istio = softwareSystem "Istio" "Service mesh with DestinationRules, EnvoyFilters, ServiceEntries" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring via ServiceMonitors and PrometheusRules" "External"
        openTelemetry = softwareSystem "OpenTelemetry" "Distributed tracing via OTel Collectors" "External"
        perses = softwareSystem "Perses" "Dashboarding via PersesDashboards" "External"
        authorino = softwareSystem "Authorino" "Authorization engine (read-only integration)" "External"

        dsci = softwareSystem "DSCInitialization" "Platform initialization state" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving with InferenceService and LLMInferenceService" "Internal ODH"
        odhOperator = softwareSystem "opendatahub-operator" "ODH platform operator providing module framework" "Internal ODH"

        batchGateway = softwareSystem "Batch Gateway" "Batch inference gateway (batch.llm-d.ai/llmbatchgateways)" "Managed Sub-Component"
        maas = softwareSystem "Models-as-a-Service" "External model/provider management (maas.opendatahub.io, inference.opendatahub.io)" "Managed Sub-Component"

        admin -> aiGatewayOperator "Creates/Updates AIGateway CR" "kubectl / API"
        aiGatewayOperator -> kubernetesAPI "CRUD resources, watch CRs" "HTTPS/6443, SA Token"
        aiGatewayOperator -> certManager "Manages Certificate CRs" "Kubernetes API"
        aiGatewayOperator -> gatewayAPI "Manages HTTPRoutes" "Kubernetes API"
        aiGatewayOperator -> kuadrant "Manages AuthPolicies, RateLimitPolicies" "Kubernetes API"
        aiGatewayOperator -> istio "Manages DestinationRules, EnvoyFilters, ServiceEntries" "Kubernetes API"
        aiGatewayOperator -> prometheusOperator "Manages ServiceMonitors, PrometheusRules" "Kubernetes API"
        aiGatewayOperator -> openTelemetry "Manages OTel Collectors" "Kubernetes API"
        aiGatewayOperator -> perses "Manages Dashboards, DataSources" "Kubernetes API"
        aiGatewayOperator -> authorino "Reads Authorino CRs" "Kubernetes API"
        aiGatewayOperator -> dsci "Watches DSCInitialization CR" "Kubernetes API"
        aiGatewayOperator -> kserve "Watches InferenceService, LLMInferenceService" "Kubernetes API"
        aiGatewayOperator -> odhOperator "Uses module operator framework" "Go Library"
        aiGatewayOperator -> batchGateway "Deploys/manages lifecycle" "Kustomize Manifests"
        aiGatewayOperator -> maas "Deploys/manages lifecycle" "Kustomize Manifests"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Managed Sub-Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
