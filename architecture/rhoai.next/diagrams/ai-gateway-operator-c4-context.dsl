workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration via DataScienceCluster"
        dataScientist = person "Data Scientist" "Creates ML models and inference services"

        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Module operator managing AI Gateway sub-components for batch inference, MaaS, and traffic routing" {
            controller = container "AIGateway Controller" "Reconciles AIGateway CR, conditionally deploys sub-components via kustomize + SSA" "Go controller-runtime"
            tlsWatcher = container "SecurityProfileWatcher" "Monitors OpenShift TLS profile changes and triggers graceful restart" "Go"
            configManager = container "Configuration Manager" "Viper-based config from ConfigMap files and env vars" "Go"
        }

        batchGatewayOperator = softwareSystem "batch-gateway-operator" "Manages LLM batch inference gateways (LLMBatchGateway CRs)" "Vendored Sub-Component"
        maasController = softwareSystem "maas-controller" "Models as a Service controller for multi-tenant model inference" "Vendored Sub-Component"
        aiGatewayController = softwareSystem "ai-gateway-controller" "AI Gateway traffic controller with Praxis extproc routing" "Vendored Sub-Component"

        odhOperator = softwareSystem "opendatahub-operator" "Platform operator that creates AIGateway CR and reads status" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute management for traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant" "Auth and rate limiting for MaaS tenants" "External"
        istio = softwareSystem "Istio" "Service mesh for network policies" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring configuration (ServiceMonitor, PrometheusRules)" "External"
        authorino = softwareSystem "Authorino" "Auth infrastructure readiness detection" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Cluster TLS profile and adherence policy" "External"

        platformAdmin -> odhOperator "Configures DataScienceCluster"
        odhOperator -> aiGatewayOperator "Creates AIGateway CR; reads status for DSC aggregation" "HTTPS/6443"
        aiGatewayOperator -> batchGatewayOperator "SSA deploy when batchGateway: Managed" "HTTPS/6443"
        aiGatewayOperator -> maasController "SSA deploy when modelsAsAService: Managed" "HTTPS/6443"
        aiGatewayOperator -> aiGatewayController "SSA deploy with MaaS toggle" "HTTPS/6443"
        aiGatewayOperator -> k8sAPI "CRD watches, resource CRUD, leader election" "HTTPS/6443"
        aiGatewayOperator -> openshiftAPI "TLS profile fetch" "HTTPS/6443"
        aiGatewayOperator -> kserve "LLMInferenceService watch" "HTTPS/6443"

        batchGatewayOperator -> k8sAPI "LLMBatchGateway CR reconciliation" "HTTPS/6443"
        maasController -> certManager "TLS certificate management" "HTTPS/6443"
        maasController -> gatewayAPI "HTTPRoute management" "HTTPS/6443"
        maasController -> kuadrant "AuthPolicy + RateLimitPolicy" "HTTPS/6443"
        aiGatewayController -> istio "DestinationRules, EnvoyFilters" "HTTPS/6443"
        aiGatewayOperator -> prometheusOperator "ServiceMonitor/PrometheusRules CRUD" "HTTPS/6443"
        aiGatewayOperator -> authorino "Auth infrastructure readiness" "HTTPS/6443"
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
            element "Vendored Sub-Component" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
