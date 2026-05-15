workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService resources"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures NIM accounts and serving runtimes"

        odhModelController = softwareSystem "odh-model-controller" "Automates model serving infrastructure — networking, monitoring, autoscaling, security, and NIM integration" {
            controller = container "odh-model-controller" "Manages InferenceService, LLMInferenceService, NIM Account lifecycle" "Go Operator (controller-runtime)" {
                servingControllers = component "Serving Controllers" "InferenceService, InferenceGraph, ServingRuntime reconcilers" "Go"
                subReconcilers = component "Sub-Resource Reconcilers" "Route, Metrics, ServiceMonitor, KEDA, RBAC reconcilers" "Go"
                llmControllers = component "LLM Controllers" "LLMInferenceService, Gateway, AuthPolicy reconcilers" "Go"
                nimSubsystem = component "NIM Subsystem" "Account controller with validation, template, pull-secret handlers" "Go"
                coreControllers = component "Core Controllers" "ConfigMap (CA), Secret (storage-config), Pod (Ray TLS) controllers" "Go"
                webhooks = component "Admission Webhooks" "Mutating/validating webhooks for ISVC, IG, NIM Account, Pods" "Go"
            }
            apiServer = container "model-serving-api" "REST API for Gateway discovery, RBAC-checked" "Go HTTP Server" {
                gatewayEndpoint = component "Gateway Endpoint" "GET /api/v1/gateways — returns filtered gateway refs" "Go"
                authMiddleware = component "Auth Middleware" "Bearer token validation via SelfSubjectAccessReview" "Go"
            }
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform — InferenceService, ServingRuntime, LLMInferenceService CRDs" "External"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Authentication and authorization policy engine for Gateway API" "External"
        istio = softwareSystem "Istio" "Service mesh — EnvoyFilter for TLS and auth" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway resources for next-gen routing" "External"
        keda = softwareSystem "KEDA" "Prometheus-based custom metric autoscaling" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "ServiceMonitor/PodMonitor CRDs for metrics collection" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management (optional)" "External"
        openShift = softwareSystem "OpenShift Platform" "Route API, Template API, Service CA, Authentication config" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core API for CRD CRUD, RBAC, watches" "External"

        nvidiaNGC = softwareSystem "NVIDIA NGC" "NIM model catalog, API key validation, container registry" "External Service"
        modelRegistry = softwareSystem "Model Registry" "Kubeflow model versioning and tracking service" "Internal ODH"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for model management and deployment" "Internal ODH"
        platformOperator = softwareSystem "rhods-operator" "Platform operator — deploys odh-model-controller via kustomize" "Internal ODH"

        // User interactions
        dataScientist -> odhModelController "Creates InferenceService / LLMInferenceService via kubectl"
        platformAdmin -> odhModelController "Creates NIM Account, manages serving config"
        dashboard -> apiServer "GET /api/v1/gateways" "HTTPS/443 Bearer Token"

        // Controller dependencies
        odhModelController -> k8sAPI "CRD watches, resource CRUD, RBAC" "HTTPS/6443"
        odhModelController -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService CRDs"
        odhModelController -> openShift "Creates Routes, Templates; reads auth config, service CA"
        odhModelController -> kuadrant "Creates AuthPolicies for Gateways and HTTPRoutes"
        odhModelController -> istio "Creates EnvoyFilters for TLS and Authorino"
        odhModelController -> gatewayAPI "Watches Gateways, creates AuthPolicies for HTTPRoutes"
        odhModelController -> keda "Creates TriggerAuthentication for Prometheus autoscaling"
        odhModelController -> prometheusOp "Creates ServiceMonitors and PodMonitors"
        odhModelController -> nvidiaNGC "Validates API keys, fetches NIM model catalog" "HTTPS/443 Bearer Token"
        odhModelController -> modelRegistry "Model versioning sync (optional)" "HTTP(S) Bearer Token"

        // Platform operator deploys
        platformOperator -> odhModelController "Deploys via kustomize manifests"
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
            element "External Service" {
                background #76b900
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
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
        }
    }
}
