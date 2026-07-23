workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components and AIGateway lifecycle"
        dataScienceUser = person "Data Science User" "Creates AI tenants, model subscriptions, and batch inference jobs"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator managing batch-gateway-operator and maas-controller sub-components for AI Gateway" {
            controller = container "ai-gateway-operator" "Reconciles AIGateway CR, renders vendored kustomize manifests, deploys sub-components via SSA" "Go (controller-runtime)"
            initContainer = container "copy-manifests" "Copies vendored manifests from image to writable emptyDir" "Init Container"
        }

        batchGatewayOperator = softwareSystem "Batch Gateway Operator" "Manages batch LLM inference gateway workloads (API server, processor, GC, async)" "Sub-Component" {
            bgoController = container "batch-gateway-operator" "Watches LLMBatchGateway CRs and manages batch workloads" "Go Operator"
            bgoAPIServer = container "Batch Gateway API Server" "Handles batch inference API requests" "Go Service"
            bgoProcessor = container "Batch Gateway Processor" "Processes batch inference jobs" "Go Service"
            bgoGC = container "Batch Gateway GC" "Garbage collects completed batch jobs" "Go Service"
            bgoAsync = container "Async Processor" "Handles async batch inference" "Go Service"
        }

        maasController = softwareSystem "MaaS Controller" "Models as a Service: multi-tenant model management with Gateway API routing, auth, and rate limiting" "Sub-Component" {
            maasCtrl = container "maas-controller" "Manages MaaS CRDs, tenant isolation, model routing" "Go Controller"
            maasAPI = container "maas-api" "MaaS API server" "Go Service"
            maasWebhook = container "Webhook Server" "Validates AITenant, MaaSSubscription, MaaSAuthPolicy" "Go Admission Webhook"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator (rhods-operator for RHOAI) that creates AIGateway CR" "Internal Platform"
        kserve = softwareSystem "KServe" "Model inference serving platform with LLMInferenceService" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant" "API management: AuthPolicy, TokenRateLimitPolicy, RateLimitPolicy" "Internal Platform"
        authorino = softwareSystem "Authorino" "Authentication and authorization provider" "Internal Platform"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic routing, mTLS, and network policies" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API (maas-default-gateway in openshift-ingress)" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        openTelemetry = softwareSystem "OpenTelemetry" "Observability and metrics collection" "External"
        perses = softwareSystem "Perses" "Dashboard and datasource management" "External"
        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        postgres = softwareSystem "PostgreSQL" "Database for MaaS tenant data (via maas-db-config secret)" "External"

        # Relationships
        platformAdmin -> odhOperator "Configures platform components"
        odhOperator -> aiGatewayOperator "Creates AIGateway CR" "HTTPS/443"
        dataScienceUser -> batchGatewayOperator "Creates LLMBatchGateway CRs" "kubectl/HTTPS"
        dataScienceUser -> maasController "Creates AITenant, MaaSSubscription CRs" "kubectl/HTTPS"

        aiGatewayOperator -> kubeAPI "Watches CRs, SSA deploys resources" "HTTPS/443"
        aiGatewayOperator -> batchGatewayOperator "Deploys via kustomize SSA (batchGateway=Managed)" "HTTPS/443"
        aiGatewayOperator -> maasController "Deploys via kustomize SSA (modelsAsAService=Managed)" "HTTPS/443"

        batchGatewayOperator -> kubeAPI "Manages batch workloads" "HTTPS/443"
        batchGatewayOperator -> certManager "Creates Certificate resources" "HTTPS/443"

        maasController -> kubeAPI "Manages MaaS resources" "HTTPS/443"
        maasController -> kserve "Watches LLMInferenceService for model discovery" "HTTPS/443"
        maasController -> kuadrant "Creates AuthPolicies, TokenRateLimitPolicies" "HTTPS/443"
        maasController -> authorino "Reads Authorino CR for auth config" "HTTPS/443"
        maasController -> istio "Creates DestinationRules, EnvoyFilters, ServiceEntries" "HTTPS/443"
        maasController -> gatewayAPI "Creates HTTPRoutes to maas-default-gateway" "HTTPS/443"
        maasController -> openTelemetry "Creates OpenTelemetryCollectors" "HTTPS/443"
        maasController -> perses "Creates PersesDashboards, PersesDatasources" "HTTPS/443"
        maasController -> postgres "Stores tenant data via maas-db-config" "TLS"
    }

    views {
        systemContext aiGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container batchGatewayOperator "BatchGatewayContainers" {
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
            element "Sub-Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
