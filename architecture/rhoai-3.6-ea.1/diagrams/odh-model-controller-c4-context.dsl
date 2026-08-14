workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRs"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform components and NIM accounts"
        apiClient = person "API Client" "Queries gateway discovery and sample templates via REST API"

        odhModelController = softwareSystem "odh-model-controller" "Dual-workload Kubernetes operator managing model serving resources, admission webhooks, and Gateway API integration on RHOAI" {
            controllerDeployment = container "odh-model-controller Deployment" "Controller-runtime operator with 10 reconcilers and 8 admission webhooks" "Go Operator" {
                isvcReconciler = component "InferenceServiceReconciler" "Manages InferenceService lifecycle and subordinate resources (Routes, NetworkPolicies, ServiceAccounts, KEDA, monitoring)" "Go Controller"
                gatewayReconciler = component "GatewayReconciler" "Manages Gateway API resources, Kuadrant AuthPolicies, Istio EnvoyFilters" "Go Controller"
                llmisvcReconciler = component "LLMInferenceServiceReconciler" "Manages LLMInferenceService lifecycle" "Go Controller"
                igReconciler = component "InferenceGraphReconciler" "Manages InferenceGraph lifecycle" "Go Controller"
                srtReconciler = component "ServingRuntimeReconciler" "Manages ServingRuntime lifecycle" "Go Controller"
                accountReconciler = component "AccountReconciler" "Manages NIM Account lifecycle" "Go Controller"
                webhookServer = component "Webhook Server" "8 admission webhooks (5 mutating, 3 validating) on port 9443" "Go HTTP Server"
                tlsManager = component "TLS Manager" "Resolves TLS config from OpenShift APIServer profile, fallback Mozilla Intermediate" "Go Package"
            }

            apiDeployment = container "model-serving-api Deployment" "HTTPS REST API for gateway discovery and LLM-d sample templates" "Go HTTP Server" {
                gatewayEndpoint = component "/api/v1/gateways" "Gateway discovery with Bearer token auth and SelfSubjectAccessReview" "REST Endpoint"
                samplesEndpoint = component "/api/v1/samples/llm-d" "Static embedded YAML templates, unauthenticated" "REST Endpoint"
                metricsEndpoint = component "/metrics" "Prometheus metrics on port 8080" "REST Endpoint"
                authMiddleware = component "Auth Middleware" "Extracts Bearer token from Authorization header, returns 401 for unauthenticated" "Go Middleware"
            }
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD and watch operations" "External"
        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService, InferenceGraph, LLMInferenceService, ServingRuntime CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing" "External"
        kuadrant = softwareSystem "Kuadrant" "API management with AuthPolicies for authentication" "Internal RHOAI"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with TriggerAuthentications" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via PodMonitors and ServiceMonitors" "External"
        certManager = softwareSystem "OpenShift service-ca" "TLS certificate provisioning for Services" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress routing via Routes" "External"
        dsc = softwareSystem "DataScienceCluster" "RHOAI platform component configuration" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"

        dataScientist -> odhModelController "Creates InferenceService, LLMInferenceService via kubectl"
        platformAdmin -> odhModelController "Configures NIM Accounts and ServingRuntimes"
        apiClient -> odhModelController "GET /api/v1/gateways with Bearer token" "HTTPS/8443"

        odhModelController -> kubernetesAPI "Watches and manages Kubernetes resources" "HTTPS/6443"
        odhModelController -> kserve "Watches InferenceService, InferenceGraph, LLMInferenceService, ServingRuntime CRDs" "Kubernetes API"
        odhModelController -> istio "Creates EnvoyFilters for gateway ingress" "Kubernetes API"
        odhModelController -> gatewayAPI "Manages Gateway and HTTPRoute resources" "Kubernetes API"
        odhModelController -> kuadrant "Creates AuthPolicies for LLMInferenceService auth" "Kubernetes API"
        odhModelController -> keda "Creates TriggerAuthentications for autoscaling" "Kubernetes API"
        odhModelController -> prometheusOperator "Creates PodMonitors and ServiceMonitors" "Kubernetes API"
        odhModelController -> certManager "TLS certificates provisioned for webhook and metrics Services"
        odhModelController -> openshiftRouter "Creates Routes for model serving endpoints" "Kubernetes API"
        odhModelController -> dsc "Reads DataScienceCluster and DSCInitialization CRs" "Kubernetes API"
        odhModelController -> otelCollector "Exports traces" "OTLP/gRPC"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
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
        }
    }
}
