workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models via InferenceService and LLMInferenceService resources"
        admin = person "Platform Admin" "Configures NIM Accounts and manages model serving infrastructure"
        dashboard_user = person "Dashboard User" "Uses RHOAI Dashboard to deploy models via Gateway API"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes operator managing model serving infrastructure lifecycle for KServe InferenceServices and LLMInferenceServices" {
            controller = container "odh-model-controller" "Reconciles InferenceService, LLMInferenceService, ServingRuntime, NIM Account CRDs" "Go Operator (controller-runtime)" {
                isvcReconciler = component "InferenceService Reconciler" "Orchestrates sub-reconcilers for route, metrics, monitoring, KEDA, RBAC" "Go"
                llmReconciler = component "LLMInferenceService Reconciler" "Manages AuthPolicy for Gateway API authentication" "Go"
                gatewayReconciler = component "Gateway Reconciler" "Bootstraps EnvoyFilter and AuthPolicy per Gateway" "Go"
                nimController = component "NIM Account Controller" "Manages NVIDIA NIM lifecycle: API keys, pull secrets, templates" "Go"
                secretController = component "Secret Controller" "Aggregates data connection secrets with CA certs into storage-config" "Go"
                podWebhook = component "Pod Webhook" "Injects Ray TLS volumes and init containers" "Go"
            }
            apiServer = container "model-serving-api" "HTTPS API for gateway discovery with bearer token passthrough RBAC" "Go HTTPS Server" {
                gatewayHandler = component "Gateway Discovery Handler" "Lists and filters Gateway API gateways by user RBAC" "Go"
                authMiddleware = component "Auth Middleware" "Passes bearer tokens through to K8s API for SAR" "Go"
            }
        }

        # External Dependencies
        kserve = softwareSystem "KServe" "Provides InferenceService, ServingRuntime, LLMInferenceService CRDs and model serving runtime" "External"
        kuadrant = softwareSystem "Kuadrant" "Provides AuthPolicy CRD for Gateway API authentication" "External"
        authorino = softwareSystem "Authorino" "Authorization service performing TokenReview and SubjectAccessReview" "External"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter CRD for TLS configuration" "External"
        keda = softwareSystem "KEDA" "Provides TriggerAuthentication CRD for Prometheus-based autoscaling" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Provides ServiceMonitor and PodMonitor CRDs for metrics collection" "External"
        gatewayAPI = softwareSystem "Gateway API" "Provides Gateway and HTTPRoute CRDs for LLMInferenceService routing" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management" "External"

        # Internal Platform
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator providing DataScienceCluster and DSCInitialization CRDs" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for model deployment and gateway selection" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and version tracking" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Exposes services via Route resources" "OpenShift"

        # External Services
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "Infrastructure"
        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM API key validation, runtime catalog, model metadata" "External Service"
        nvcrRegistry = softwareSystem "nvcr.io" "NVIDIA container registry for NIM inference runtime images" "External Service"

        # Relationships - User interactions
        user -> odhModelController "Creates InferenceService / LLMInferenceService via kubectl"
        admin -> odhModelController "Creates NIM Account resources"
        dashboard_user -> rhoaiDashboard "Selects gateway for model deployment"

        # Relationships - System interactions
        rhoaiDashboard -> odhModelController "GET /api/v1/gateways" "HTTPS/443"
        odhModelController -> k8sAPI "CRD reconciliation, resource CRUD, RBAC checks" "HTTPS/443"
        odhModelController -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService CRDs" "K8s API"
        odhModelController -> kuadrant "Creates AuthPolicy resources for Gateway API auth" "K8s API"
        odhModelController -> istio "Creates EnvoyFilter for Gateway-to-Authorino TLS" "K8s API"
        odhModelController -> keda "Creates TriggerAuthentication for autoscaling" "K8s API"
        odhModelController -> prometheusOp "Creates ServiceMonitor per InferenceService" "K8s API"
        odhModelController -> gatewayAPI "Watches/updates Gateway, HTTPRoute resources" "K8s API"
        odhModelController -> openshiftRouter "Creates Routes for traditional InferenceServices" "K8s API"
        odhModelController -> rhodsOperator "Reads DataScienceCluster, DSCInitialization config" "K8s API"
        odhModelController -> ngcAPI "Validates NIM API keys, fetches runtime catalog" "HTTPS/443"
        odhModelController -> nvcrRegistry "Verifies NIM image pull authentication" "HTTPS/443"
        odhModelController -> modelRegistry "Optional: registers InferenceServices with model metadata" "HTTPS/443"
        odhModelController -> authorino "EnvoyFilter configures TLS to Authorino gRPC" "gRPC/50051"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout
        }

        container odhModelController "Containers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component apiServer "APIServerComponents" {
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
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
