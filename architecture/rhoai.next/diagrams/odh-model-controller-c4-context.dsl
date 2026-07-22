workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Configures NIM Accounts, monitors model serving infrastructure"
        dashboardUser = person "Dashboard User" "Uses RHOAI Dashboard to discover gateways and configure LLM endpoints"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes operator and REST API server managing lifecycle, networking, auth, monitoring, and credential injection for KServe model serving" {
            manager = container "odh-model-controller (manager)" "Reconciles InferenceService, LLMInferenceService, ServingRuntime, InferenceGraph, Gateway, NIM Account; runs admission webhooks" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Mutating/Validating admission webhooks for ConnectionsAPI, HardwareProfile, Ray TLS, InferenceGraph namespace isolation, NIM singleton" "Go (embedded in manager, 9443/TCP)"
            modelServingApi = container "model-serving-api" "Gateway discovery API for RHOAI Dashboard with per-request RBAC; LLM-D sample templates" "Go REST API Server (8443/TCP HTTPS FIPS)"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform providing InferenceService, LLMInferenceService, ServingRuntime, InferenceGraph CRDs" "External"
        kuadrant = softwareSystem "Kuadrant Operator" "API management with AuthPolicy CRD for Gateway API authentication" "External"
        authorino = softwareSystem "Authorino" "Authorization backend for Kuadrant AuthPolicies" "External"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter CRD for gateway TLS/auth configuration" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with TriggerAuthentication for Prometheus-based scaling" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "ServiceMonitor and PodMonitor CRDs for metrics collection" "External"
        gatewayAPI = softwareSystem "Gateway API" "Gateway and HTTPRoute CRDs for inference networking" "External"
        openshiftAPI = softwareSystem "OpenShift Platform" "Routes, Templates, Config APIs, Monitoring" "External"
        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM model catalog and API key validation service" "External"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata for InferenceService registration" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster / DSCInitialization" "Platform configuration CRDs for namespace and feature detection" "Internal ODH"
        hardwareProfile = softwareSystem "HardwareProfile" "Resource identifiers, scheduling, and Kueue queue label configuration" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing model serving endpoints and gateway configuration" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job scheduling via queue-name labels injected by HardwareProfile webhook" "External"

        # User interactions
        user -> odhModelController "Creates InferenceService / LLMInferenceService via kubectl" "HTTPS/6443"
        platformAdmin -> odhModelController "Creates NIM Account with API Key Secret" "HTTPS/6443"
        dashboardUser -> rhoaiDashboard "Browses gateways, configures LLM endpoints" "HTTPS"

        # Dashboard → API
        rhoaiDashboard -> modelServingApi "GET /api/v1/gateways (discovers gateways)" "HTTPS/8443 FIPS"

        # Controller → external systems
        manager -> kserve "Watches and reconciles InferenceService, LLMInferenceService, ServingRuntime, InferenceGraph" "CRD Watch"
        manager -> kuadrant "Creates/updates AuthPolicy per LLMInferenceService and Gateway" "CRD CRUD"
        manager -> authorino "Detects TLS bootstrap for EnvoyFilter configuration" "CRD Watch"
        manager -> istio "Creates/updates EnvoyFilter for gateway TLS/auth" "CRD CRUD"
        manager -> keda "Creates TriggerAuthentication for Prometheus-based autoscaling" "CRD CRUD"
        manager -> prometheusOp "Creates ServiceMonitor (per ISVC) and PodMonitor (per Gateway)" "CRD CRUD"
        manager -> gatewayAPI "Watches Gateway and HTTPRoute for reconciliation" "CRD Watch"
        manager -> openshiftAPI "Creates Routes, Templates, RoleBindings" "HTTPS/6443"
        manager -> ngcAPI "Validates API keys, fetches NIM runtime catalog" "HTTPS/443"
        manager -> modelRegistry "Syncs InferenceService registration metadata" "HTTPS"
        manager -> dsc "Reads platform namespace, NIM air-gapped mode" "CRD Watch"
        manager -> hardwareProfile "Resolves resource identifiers and scheduling" "CRD Watch"
        manager -> kueue "Injects queue-name labels via HardwareProfile webhook" "Label injection"

        # Server → K8s
        modelServingApi -> openshiftAPI "SelfSubjectAccessReview, Gateway listing (user token passthrough)" "HTTPS/6443"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
