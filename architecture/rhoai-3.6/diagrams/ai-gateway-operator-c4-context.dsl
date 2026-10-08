workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components via opendatahub-operator"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator managing lifecycle of AI Gateway sub-components (batch-gateway, MaaS, ai-gateway-controller)" {
            controller = container "ai-gateway-operator" "Reconciles AIGateway CR, renders and deploys vendored kustomize manifests, manages RBAC escalation" "Go Operator (controller-runtime v0.24.1)"
            initContainer = container "copy-manifests" "Copies vendored kustomize manifests from image to shared emptyDir volume" "Init Container"
        }

        odhOperator = softwareSystem "opendatahub-operator" "Platform operator that orchestrates RHOAI component modules" "Internal RHOAI"
        batchGatewayOp = softwareSystem "batch-gateway-operator" "Manages LLM batch inference gateways via llm-d" "Vendored Sub-Component"
        maasController = softwareSystem "maas-controller" "Models as a Service multi-tenant model access controller" "Vendored Sub-Component"
        aiGatewayController = softwareSystem "ai-gateway-controller" "Gateway-level traffic routing, guardrails (Praxis extproc), Kuadrant policy enforcement" "Vendored Sub-Component"

        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for sub-component endpoints" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute management for AI gateway traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant" "Auth policies, rate limit policies, telemetry policies" "External"
        istio = softwareSystem "Istio" "Service mesh: DestinationRules, EnvoyFilters, ServiceEntries" "External"
        prometheusOp = softwareSystem "prometheus-operator" "ServiceMonitors, PodMonitors, PrometheusRules for observability" "External"
        authorino = softwareSystem "Authorino" "Auth integration for MaaS" "External"
        opentelemetry = softwareSystem "OpenTelemetry Operator" "Distributed tracing via OpenTelemetryCollectors" "External"
        perses = softwareSystem "Perses" "Monitoring dashboards and datasources" "External"
        kserve = softwareSystem "KServe" "Model serving platform (LLMInferenceService)" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all reconciliation operations" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Database for MaaS tenant data (in infrastructure namespace)" "Infrastructure"
        openshiftAPI = softwareSystem "OpenShift APIServer" "TLS profile resolution and cluster configuration" "Infrastructure"

        platformAdmin -> odhOperator "Configures AI Gateway via DSC/AIGateway CR"
        odhOperator -> aiGatewayOperator "Deploys as module; injects RELATED_IMAGE env vars and ConfigMap config" "HTTPS/6443"
        aiGatewayOperator -> k8sAPI "Reconciles: CRD CRUD, Deployment management, RBAC escalation, status updates" "HTTPS/6443"
        aiGatewayOperator -> batchGatewayOp "Deploys when batchGateway.managementState=Managed" "Kustomize manifests"
        aiGatewayOperator -> maasController "Deploys when modelsAsAService.managementState=Managed; coordinates graceful teardown" "Kustomize manifests"
        aiGatewayOperator -> aiGatewayController "Co-deploys with maas-controller" "Kustomize manifests"
        aiGatewayOperator -> openshiftAPI "Resolves cluster TLS profile for metrics serving" "HTTPS/6443"

        batchGatewayOp -> certManager "TLS certificate provisioning" "HTTPS/443"
        batchGatewayOp -> gatewayAPI "HTTPRoute management for batch inference" "HTTPS/6443"
        maasController -> kuadrant "Auth and rate limit policies" "HTTPS/6443"
        maasController -> authorino "Auth integration" "HTTPS/6443"
        maasController -> postgresql "Tenant data storage" "TCP/5432"
        aiGatewayController -> istio "Traffic routing via DestinationRules" "HTTPS/6443"
        aiGatewayController -> kuadrant "Rate limiting policies" "HTTPS/6443"
        aiGatewayOperator -> prometheusOp "Deploys monitoring resources" "HTTPS/6443"
        aiGatewayOperator -> opentelemetry "Deploys tracing collectors" "HTTPS/6443"
        aiGatewayOperator -> perses "Deploys dashboards" "HTTPS/6443"
        aiGatewayOperator -> kserve "Reads LLMInferenceService state (RBAC escalation)" "HTTPS/6443"
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
            element "Vendored Sub-Component" {
                background #4ecdc4
                color #ffffff
            }
        }
    }
}
