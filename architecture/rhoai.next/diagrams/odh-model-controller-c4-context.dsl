workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via InferenceService"
        platformadmin = person "Platform Admin" "Configures NIM accounts, manages platform settings"
        dashboarduser = person "Dashboard User" "Uses RHOAI Dashboard to manage model serving"

        odmController = softwareSystem "odh-model-controller" "Automates model serving infrastructure for KServe InferenceServices, LLM auth, and NVIDIA NIM" {
            operator = container "odh-model-controller Operator" "Manages InferenceService lifecycle: Routes, monitoring, KEDA, auth policies, NIM integration" "Go Operator (controller-runtime)" "Operator"
            apiServer = container "model-serving-api" "HTTPS gateway discovery API with per-user RBAC authorization" "Go HTTP Server" "APIServer"
        }

        # Internal ODH/RHOAI Components
        kserve = softwareSystem "KServe" "Provides InferenceService, ServingRuntime, LLMInferenceService CRDs" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing model serving" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator providing DataScienceCluster, DSCInitialization CRDs" "Internal ODH"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and InferenceService sync" "Internal ODH"

        # External Dependencies
        kuadrant = softwareSystem "Kuadrant Operator" "Provides AuthPolicy CRD for Gateway API authentication" "External"
        authorino = softwareSystem "Authorino" "TLS bootstrap for EnvoyFilter configuration" "External"
        istio = softwareSystem "Istio / Service Mesh" "Provides EnvoyFilter CRD for proxy configuration" "External"
        keda = softwareSystem "KEDA" "Provides TriggerAuthentication for Prometheus-based autoscaling" "External"
        prometheus = softwareSystem "Prometheus Operator" "Provides ServiceMonitor and PodMonitor CRDs for metrics scraping" "External"
        gatewayAPI = softwareSystem "Gateway API" "Gateway, HTTPRoute CRDs for inference routing" "External"
        knative = softwareSystem "Knative Serving" "Serverless inference autoscaling" "External"
        certManager = softwareSystem "cert-manager" "Optional webhook TLS certificate management" "External"

        # External Services
        openshiftAPI = softwareSystem "OpenShift API" "Routes, Templates, cluster Authentication config" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core API server for all cluster operations" "External"
        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM runtime discovery, API key validation, model data" "External Service"
        nvcr = softwareSystem "nvcr.io Container Registry" "NIM container image pull token acquisition" "External Service"

        # Relationships - Users
        datascientist -> odmController "Creates InferenceService via kubectl" "HTTPS/443"
        platformadmin -> odmController "Creates NIM Account CRs" "HTTPS/443"
        dashboarduser -> rhoaiDashboard "Uses web UI"

        # Relationships - Internal
        rhoaiDashboard -> apiServer "GET /api/v1/gateways" "HTTPS/443 (FIPS)"
        operator -> k8sAPI "All controller operations" "HTTPS/443"
        apiServer -> k8sAPI "SelfSubjectAccessReview + Gateway list" "HTTPS/443"
        operator -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService CRDs"
        operator -> rhodsOperator "Reads DataScienceCluster, DSCInitialization for platform config"
        operator -> modelRegistry "Syncs InferenceService metadata" "HTTP(S)"

        # Relationships - External Dependencies
        operator -> kuadrant "Creates AuthPolicies for Gateway API auth"
        operator -> authorino "Detects TLS bootstrap for EnvoyFilter creation"
        operator -> istio "Creates EnvoyFilters for proxy configuration"
        operator -> keda "Creates TriggerAuthentications for autoscaling"
        operator -> prometheus "Creates ServiceMonitors for metrics scraping"
        operator -> openshiftAPI "Creates Routes, Templates" "HTTPS/443"
        operator -> gatewayAPI "Watches Gateways, manages auth"

        # Relationships - External Services
        operator -> ngcAPI "NIM API key validation, model data" "HTTPS/443"
        operator -> nvcr "NIM pull token acquisition" "HTTPS/443"
    }

    views {
        systemContext odmController "SystemContext" {
            include *
            autoLayout
        }

        container odmController "Containers" {
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
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "APIServer" {
                background #50e3c2
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
