workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models and LLM inference services on RHOAI"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and NIM accounts"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes operator and API server managing KServe model serving lifecycle, LLM inference auth, and NIM accounts" {
            controller = container "odh-model-controller" "9 reconcilers managing InferenceService, LLMInferenceService, Gateway, ServingRuntime, InferenceGraph, ConfigMap, Secret, Pod, and NIM Account lifecycles" "Go Operator (controller-runtime)" {
                isvcReconciler = component "InferenceServiceReconciler" "Manages KServe raw deployment InferenceService lifecycle with 6 sub-reconcilers" "Go"
                llmReconciler = component "LLMInferenceServiceReconciler" "Manages LLM inference service AuthPolicy creation" "Go"
                gatewayReconciler = component "GatewayReconciler" "Authorino TLS bootstrap and auth policy on Gateway resources" "Go"
                runtimeReconciler = component "ServingRuntimeReconciler" "Ray TLS cert distribution and Prometheus federation" "Go"
                nimReconciler = component "NIMAccountReconciler" "NVIDIA NIM API key validation, template generation, catalog sync" "Go"
                configmapReconciler = component "ConfigMapReconciler" "CA certificate bundle aggregation" "Go"
                secretReconciler = component "SecretReconciler" "Storage credential composition from data connections" "Go"
                podReconciler = component "PodReconciler" "Per-pod Ray TLS certificate generation" "Go"
                webhookServer = component "Webhook Server" "3 mutating + 3 validating admission webhooks" "Go"
            }
            apiServer = container "model-serving-api" "Gateway discovery API with FIPS TLS and SelfSubjectAccessReview auth" "Go HTTP Server" {
                gatewayHandler = component "Gateway Handler" "Lists available Gateway API gateways filtered by namespace permissions" "Go"
                authMiddleware = component "Auth Middleware" "SelfSubjectAccessReview-based authorization" "Go"
                certReloader = component "Cert Reloader" "Zero-downtime FIPS TLS certificate rotation via fsnotify" "Go"
            }
        }

        kserve = softwareSystem "KServe" "ML inference serving platform providing InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph CRDs" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web console for RHOAI platform management" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys and configures components" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and version tracking" "Internal RHOAI"

        kuadrant = softwareSystem "Kuadrant" "API management with AuthPolicy CRDs for Gateway API authentication" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization backend for Kuadrant AuthPolicies" "External"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter CRDs for proxy configuration" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with TriggerAuthentication for Prometheus-based scaling" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "ServiceMonitor and PodMonitor CRDs for metrics collection" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute resources for ingress" "External"
        openshiftRouting = softwareSystem "OpenShift Routing" "OpenShift Routes for external service exposure" "External"
        certManager = softwareSystem "cert-manager / OpenShift service-ca" "TLS certificate provisioning for webhooks and API server" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and admission control" "External"

        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA GPU Cloud API for NIM model catalog and API key validation" "External SaaS"
        nvidiaRegistry = softwareSystem "NVIDIA Container Registry" "nvcr.io container registry for NIM image validation" "External SaaS"

        # Relationships - Users
        dataScientist -> odhModelController "Creates InferenceService and LLMInferenceService via kubectl/dashboard"
        dataScientist -> rhoaiDashboard "Uses web console to manage inference services"
        platformAdmin -> odhModelController "Creates NIM Account resources"

        # Relationships - Internal RHOAI
        odhModelController -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph CRDs" "HTTPS/6443"
        rhoaiDashboard -> odhModelController "Queries available gateways for LLM inference routing" "HTTPS/8443"
        rhodsOperator -> odhModelController "Deploys and configures via kustomize manifests"
        odhModelController -> modelRegistry "Registers InferenceService model versions" "HTTP(S)/configurable"

        # Relationships - External Dependencies
        odhModelController -> kuadrant "Creates AuthPolicy resources for Gateway API auth" "HTTPS/6443"
        odhModelController -> authorino "Discovers installation, checks TLS config" "HTTPS/6443"
        odhModelController -> istio "Creates EnvoyFilter for Authorino TLS bootstrap" "HTTPS/6443"
        odhModelController -> keda "Creates TriggerAuthentication for Prometheus-based autoscaling" "HTTPS/6443"
        odhModelController -> prometheusOp "Creates ServiceMonitor and PodMonitor resources" "HTTPS/6443"
        odhModelController -> openshiftRouting "Creates OpenShift Routes for inference services" "HTTPS/6443"
        odhModelController -> gatewayAPI "Watches Gateway resources, manages auth" "HTTPS/6443"
        odhModelController -> kubernetesAPI "CRD watches, resource CRUD, leader election, admission webhooks" "HTTPS/6443"
        certManager -> odhModelController "Provisions TLS certificates for webhook and API server"

        # Relationships - External SaaS
        odhModelController -> nvidiaNGC "Validates NIM API keys, fetches model catalog" "HTTPS/443"
        odhModelController -> nvidiaRegistry "Validates NIM image manifests" "HTTPS/443"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External SaaS" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
