workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models via InferenceService, LLMInferenceService, and NIM Account CRDs"
        dashboard = person "RHOAI Dashboard" "Web UI for managing model serving resources"

        odmcSystem = softwareSystem "odh-model-controller" "Manages model serving infrastructure lifecycle for KServe on RHOAI" {
            controller = container "odh-model-controller" "Kubernetes controller managing 8 controllers and 4 webhooks for InferenceService, LLMInferenceService, NIM, Gateway lifecycle" "Go Operator (controller-runtime)"
            servingAPI = container "model-serving-api" "REST API server for Gateway discovery with RBAC-filtered namespace access" "Go REST Server (HTTPS, FIPS TLS)"
        }

        kserve = softwareSystem "KServe" "Provides InferenceService, ServingRuntime, InferenceGraph, LLMInferenceService CRDs" "External - Required"
        kuadrant = softwareSystem "Kuadrant Operator" "Provides AuthPolicy CRD for gateway-level authentication" "External - Optional"
        authorino = softwareSystem "Authorino Operator" "Authentication provider used by Kuadrant AuthPolicy" "External - Optional"
        istio = softwareSystem "Istio / Service Mesh" "Provides EnvoyFilter CRD for TLS bootstrap on gateways" "External - Optional"
        keda = softwareSystem "KEDA" "Provides TriggerAuthentication CRD for Prometheus-based autoscaling" "External - Optional"
        prometheusOp = softwareSystem "Prometheus Operator" "Provides ServiceMonitor and PodMonitor CRDs for metrics collection" "External - Optional"
        gatewayAPI = softwareSystem "Gateway API" "Provides Gateway and HTTPRoute CRDs for LLMInferenceService ingress" "External - Optional"
        knative = softwareSystem "Knative Serving" "Serverless InferenceService mode" "External - Optional"

        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM API key validation, model catalog, runtime token exchange" "External Service"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Bidirectional InferenceService sync with model registry" "Internal ODH - Optional"

        openshiftRouting = softwareSystem "OpenShift Routes" "Traffic exposure for InferenceServices" "Platform"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus metrics federation" "Platform"
        dsc = softwareSystem "DataScienceCluster / DSCInitialization" "Platform configuration CRDs for namespace discovery" "Internal ODH"

        k8sAPI = softwareSystem "Kubernetes API Server" "Central API for all cluster operations" "Platform"

        user -> odmcSystem "Creates InferenceService, LLMInferenceService, NIM Account via kubectl" "HTTPS/443"
        dashboard -> servingAPI "Queries gateway discovery API" "HTTPS/443, Bearer Token"

        controller -> k8sAPI "Watches CRDs, creates Routes/ServiceMonitors/NetworkPolicies/AuthPolicies/EnvoyFilters" "HTTPS/443, SA Token"
        servingAPI -> k8sAPI "SelfSubjectAccessReview + List Gateways" "HTTPS/443, User Token + SA Token"

        odmcSystem -> kserve "Watches InferenceService, ServingRuntime, InferenceGraph, LLMInferenceService CRDs" "K8s API"
        odmcSystem -> kuadrant "Creates AuthPolicy for LLMInferenceService auth" "K8s API"
        odmcSystem -> authorino "Watches Authorino for TLS config" "K8s API"
        odmcSystem -> istio "Creates EnvoyFilters on Gateways" "K8s API"
        odmcSystem -> keda "Creates TriggerAuthentication for autoscaling" "K8s API"
        odmcSystem -> prometheusOp "Creates ServiceMonitor/PodMonitor for metrics" "K8s API"
        odmcSystem -> gatewayAPI "Watches Gateways, manages HTTPRoutes" "K8s API"
        odmcSystem -> openshiftRouting "Creates Routes for InferenceService traffic" "K8s API"
        odmcSystem -> openshiftMonitoring "Creates RoleBindings for metrics access" "RBAC"
        odmcSystem -> dsc "Reads DataScienceCluster/DSCInitialization for namespace config" "K8s API"
        odmcSystem -> ngcAPI "NIM API key validation, model catalog queries" "HTTPS/443, API Key"
        odmcSystem -> modelRegistry "Bidirectional InferenceService sync" "HTTPS/443, Bearer Token"
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

        styles {
            element "Person" {
                shape person
                background #08427b
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
            element "External - Required" {
                background #999999
                color #ffffff
            }
            element "External - Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal ODH - Optional" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #d5e8d4
                color #000000
            }
        }
    }
}
