workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures RHOAI platform components via DSC"
        dataScientist = person "Data Scientist" "Creates batch inference jobs and MaaS subscriptions"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator that manages batch-gateway-operator and maas-controller sub-components for AI Gateway functionality" {
            controller = container "AIGateway Controller" "Watches AIGateway CR and deploys sub-components via kustomize + SSA" "Go (controller-runtime)"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP :8081"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics" "HTTPS :8443"

            batchGatewayOperator = container "batch-gateway-operator" "Manages LLMBatchGateway CRs for batch LLM inference workloads" "Go Operator (vendored)"
            maasController = container "maas-controller" "Manages multi-tenant model inference (AITenant, MaaSSubscription, etc.)" "Go Operator (vendored)"
            maasWebhook = container "MaaS Validating Webhook" "Validates AITenant, MaaSSubscription, MaaSAuthPolicy resources" "HTTPS :9443"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator that creates AIGateway CR and manages DSC lifecycle" "Internal RHOAI"
        dsci = softwareSystem "DSCInitialization" "Cluster-scoped configuration for monitoring namespace and platform settings" "Internal RHOAI"

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing (Gateway, HTTPRoute)" "External"
        kuadrant = softwareSystem "Kuadrant" "API management with AuthPolicy and TokenRateLimitPolicy" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management (DestinationRule, EnvoyFilter, ServiceEntry)" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for TLS (Certificate CRs)" "External"
        kserve = softwareSystem "KServe" "Model serving platform (LLMInferenceService)" "Internal RHOAI"
        authorino = softwareSystem "Authorino" "Authentication provider for Kuadrant" "External"
        opentelemetry = softwareSystem "OpenTelemetry" "Distributed tracing and telemetry collection" "External"
        perses = softwareSystem "Perses" "Observability dashboards and data sources" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting (ServiceMonitor, PodMonitor, PrometheusRule)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD and watch operations" "External"

        # Relationships - Platform Admin
        platformAdmin -> odhOperator "Configures AI Gateway via DataScienceCluster"
        odhOperator -> aiGatewayOperator "Creates AIGateway CR" "HTTPS/443"

        # Relationships - Data Scientist
        dataScientist -> kubernetesAPI "Creates LLMBatchGateway / MaaS resources" "kubectl/HTTPS"

        # Internal flows
        controller -> batchGatewayOperator "Deploys when batchGateway: Managed" "Kustomize SSA"
        controller -> maasController "Deploys when modelsAsAService: Managed" "Kustomize SSA"
        controller -> dsci "Reads monitoring namespace" "HTTPS/443"
        maasController -> maasWebhook "Serves admission requests" "HTTPS/9443"

        # External dependencies
        aiGatewayOperator -> kubernetesAPI "CRD watch, resource CRUD, SSA" "HTTPS/443"
        batchGatewayOperator -> gatewayAPI "Manages HTTPRoutes" "K8s API"
        batchGatewayOperator -> certManager "Manages Certificate CRs" "K8s API"
        maasController -> gatewayAPI "Manages HTTPRoutes" "K8s API"
        maasController -> kuadrant "Manages AuthPolicy, TokenRateLimitPolicy" "K8s API"
        maasController -> istio "Manages DestinationRule, EnvoyFilter, ServiceEntry" "K8s API"
        maasController -> kserve "Watches LLMInferenceService" "K8s API"
        maasController -> authorino "Watches Authorino instances" "K8s API"
        maasController -> opentelemetry "Manages OpenTelemetryCollectors" "K8s API"
        maasController -> perses "Manages dashboards and data sources" "K8s API"
        aiGatewayOperator -> prometheus "Creates ServiceMonitor, PodMonitor" "K8s API"
        prometheus -> metricsEndpoint "Scrapes metrics" "HTTPS/8443"
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
        }
    }
}
