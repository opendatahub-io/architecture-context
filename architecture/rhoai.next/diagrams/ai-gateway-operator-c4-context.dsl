workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures AI Gateway via opendatahub-operator DSC"
        dataScientist = person "Data Scientist" "Creates batch inference jobs and MaaS subscriptions"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator managing batch inference and Models-as-a-Service sub-components" {
            controller = container "AIGateway Controller" "Watches AIGateway CR, renders kustomize manifests, deploys sub-components via SSA" "Go controller-runtime"
            upgradeHandler = container "Upgrade Handler" "Manages platform version handshake with opendatahub-operator via ConfigMap" "Go"
            teardownCoordinator = container "Teardown Coordinator" "Coordinates graceful MaaS shutdown via annotation protocol" "Go"
        }

        batchGatewayOperator = softwareSystem "Batch Gateway Operator" "Manages LLMBatchGateway CRs for batch LLM inference workloads" "Vendored Sub-Component" {
            bgoController = container "BGO Controller" "Watches LLMBatchGateway CRs and manages batch inference pods" "Go controller-runtime"
            apiServer = container "Batch API Server" "API server for batch inference requests" "Go"
            processor = container "Batch Processor" "Processes batch inference requests" "Go"
            gc = container "Batch GC" "Garbage collector for completed batch jobs" "Go"
        }

        maasController = softwareSystem "MaaS Controller" "Models-as-a-Service controller for multi-tenant model inference" "Vendored Sub-Component" {
            maasCtrl = container "MaaS Controller" "Watches MaaS CRDs, creates HTTPRoutes, AuthPolicies, rate limits" "Go controller-runtime"
            maasAPI = container "MaaS API" "API server for MaaS operations" "Go"
            webhook = container "Validating Webhook" "Validates AITenant, MaaSSubscription, MaaSAuthPolicy resources" "Go"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator that creates AIGateway CR and manages overall lifecycle" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD and watch operations" "Infrastructure"
        kserve = softwareSystem "KServe" "ML model serving platform providing LLMInferenceService" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh for traffic management (DestinationRule, EnvoyFilter, ServiceEntry)" "External"
        kuadrant = softwareSystem "Kuadrant" "API management for AuthPolicy and TokenRateLimitPolicy" "External"
        authorino = softwareSystem "Authorino" "Authentication backend operator for MaaS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute and Gateway resources" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        openTelemetry = softwareSystem "OpenTelemetry" "Observability collector for MaaS telemetry" "External"
        perses = softwareSystem "Perses" "Dashboard and monitoring visualization" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        platformAdmin -> odhOperator "Configures AI Gateway via DSC"
        odhOperator -> aiGatewayOperator "Creates AIGateway CR, writes platformVersion ConfigMap" "HTTPS/443"
        aiGatewayOperator -> kubernetesAPI "SSA manifests, CRD CRUD, RBAC management" "HTTPS/443"
        aiGatewayOperator -> batchGatewayOperator "Deploys when batchGateway.managementState=Managed" "SSA via K8s API"
        aiGatewayOperator -> maasController "Deploys when modelsAsAService.managementState=Managed" "SSA via K8s API"
        aiGatewayOperator -> certManager "Creates Certificate resources" "HTTPS/443"

        dataScientist -> batchGatewayOperator "Creates LLMBatchGateway CRs"
        dataScientist -> maasController "Creates AITenant, MaaSSubscription CRs"

        batchGatewayOperator -> kubernetesAPI "Watches LLMBatchGateway CRs" "HTTPS/443"

        maasController -> gatewayAPI "Creates HTTPRoutes per tenant" "HTTPS/443"
        maasController -> kuadrant "Creates AuthPolicy, TokenRateLimitPolicy per route" "HTTPS/443"
        maasController -> istio "Creates DestinationRule, EnvoyFilter, ServiceEntry" "HTTPS/443"
        maasController -> kserve "Reads LLMInferenceService (model discovery)" "HTTPS/443"
        maasController -> authorino "Checks operator availability" "HTTPS/443"
        maasController -> openTelemetry "Creates OpenTelemetryCollector" "HTTPS/443"
        maasController -> perses "Creates PersesDashboard, PersesDataSource" "HTTPS/443"

        prometheus -> aiGatewayOperator "Scrapes metrics" "HTTPS/8443"
        prometheus -> batchGatewayOperator "Scrapes metrics" "HTTPS/8443"
        prometheus -> maasController "Scrapes metrics" "HTTP/8080"
    }

    views {
        systemContext aiGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayOperator "AGOContainers" {
            include *
            autoLayout
        }

        container batchGatewayOperator "BGOContainers" {
            include *
            autoLayout
        }

        container maasController "MaaSContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Vendored Sub-Component" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #34495e
                color #ffffff
            }
        }
    }
}
