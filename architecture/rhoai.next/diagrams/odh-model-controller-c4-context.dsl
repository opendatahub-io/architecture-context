workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService resources"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and NIM accounts"
        dashboardUser = person "Dashboard / CLI User" "Discovers Gateways for model deployment"

        odmcSystem = softwareSystem "odh-model-controller" "Kubernetes operator extending KServe with RHOAI-specific model serving capabilities" {
            odmcOperator = container "odh-model-controller" "Reconciles InferenceService, LLMInferenceService, InferenceGraph, ServingRuntime, NIM Account resources" "Go Operator (controller-runtime)" {
                isvcController = component "InferenceService Controller" "Manages InferenceService lifecycle with 9 sub-reconcilers" "Go Controller"
                llmisvcController = component "LLMInferenceService Controller" "Manages AuthPolicy for LLMInferenceService HTTPRoutes" "Go Controller"
                gatewayController = component "Gateway Controller" "Creates EnvoyFilters and AuthPolicies on Gateways" "Go Controller"
                nimController = component "NIM Account Controller" "Validates NGC API keys, syncs model catalogs, creates pull secrets" "Go Controller"
                igController = component "InferenceGraph Controller" "Validates InferenceGraph service URL references" "Go Controller"
                srController = component "ServingRuntime Controller" "Manages ServingRuntime authorization" "Go Controller"
                webhookServer = component "Webhook Server" "Mutating and validating admission webhooks" "Go HTTP Server"
            }
            msaServer = container "model-serving-api" "REST API for Gateway discovery with RBAC enforcement" "Go HTTP Server" {
                gwHandler = component "Gateway Handler" "GET /api/v1/gateways endpoint" "HTTP Handler"
                authMiddleware = component "Auth Middleware" "Bearer token extraction and SSAR check" "HTTP Middleware"
                gwDiscovery = component "Gateway Discovery" "Lists and filters Gateways by namespace selector and RBAC" "Business Logic"
            }
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService, ServingRuntime, LLMInferenceService CRDs" "External Dependency"
        kuadrant = softwareSystem "Kuadrant Operator" "Authentication/authorization policy management for Gateway API" "External Dependency"
        authorino = softwareSystem "Authorino Operator" "Authorization service; TLS bootstrap status checked by controller" "External Dependency"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing EnvoyFilter CRD for TLS bootstrap" "External Dependency"
        gatewayAPI = softwareSystem "Gateway API" "Provides Gateway and HTTPRoute CRDs for ingress management" "External Dependency"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via TriggerAuthentication CRD" "External Dependency"
        prometheusOp = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor and PodMonitor CRDs" "External Dependency"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management for webhooks" "External Dependency"
        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM model catalog, API key validation, registry tokens" "External Service"
        nvcrRegistry = softwareSystem "nvcr.io" "NVIDIA container registry for NIM image manifests" "External Service"
        modelRegistry = softwareSystem "Model Registry" "Stores InferenceService metadata" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator providing DataScienceCluster CRD" "Internal ODH"
        osDashboard = softwareSystem "ODH Dashboard" "Web UI for model serving management" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "Infrastructure"
        openshiftAuth = softwareSystem "OpenShift Authentication" "Provides ServiceAccountIssuer auto-detection" "Infrastructure"

        # User relationships
        dataScientist -> odmcSystem "Creates InferenceService / LLMInferenceService via kubectl"
        platformAdmin -> odmcSystem "Creates NIM Account resources"
        dashboardUser -> msaServer "Discovers available Gateways" "HTTPS/443"

        # Internal relationships
        odmcOperator -> k8sAPI "Watch CRDs, CRUD supporting resources" "HTTPS/6443"
        msaServer -> k8sAPI "SelfSubjectAccessReview, list Gateways" "HTTPS/6443"

        # External dependency relationships
        odmcOperator -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph CRDs" "via K8s API"
        odmcOperator -> kuadrant "Watches Kuadrant CR, creates AuthPolicy resources" "via K8s API"
        odmcOperator -> authorino "Watches Authorino CR for TLS status" "via K8s API"
        odmcOperator -> istio "Creates EnvoyFilter for Authorino TLS bootstrap" "via K8s API"
        odmcOperator -> gatewayAPI "Watches Gateway, HTTPRoute resources" "via K8s API"
        odmcOperator -> keda "Creates TriggerAuthentication for autoscaling" "via K8s API"
        odmcOperator -> prometheusOp "Creates ServiceMonitor, PodMonitor" "via K8s API"

        # External service relationships
        odmcOperator -> ngcAPI "Validates API keys, fetches model catalog" "HTTPS/443"
        odmcOperator -> nvcrRegistry "Validates registry access, token exchange" "HTTPS/443"
        odmcOperator -> modelRegistry "Syncs InferenceService metadata" "HTTPS/443"

        # Internal platform relationships
        odmcOperator -> rhodsOperator "Watches DataScienceCluster, DSCInitialization" "via K8s API"
        odmcOperator -> openshiftAuth "Reads Authentication CR for ServiceAccountIssuer" "via K8s API"
        osDashboard -> msaServer "Discovers Gateways for UI" "HTTPS/443"
    }

    views {
        systemContext odmcSystem "SystemContext" {
            include *
            autoLayout
        }

        container odmcSystem "Containers" {
            include *
            autoLayout
        }

        component odmcOperator "OperatorComponents" {
            include *
            autoLayout
        }

        component msaServer "APIServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
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
