workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models via kubectl/oc"
        dashboardUser = person "Dashboard User" "Uses RHOAI Dashboard to manage inference services"

        odmcSystem = softwareSystem "odh-model-controller" "Manages model serving infrastructure, webhooks, and runtime templates for RHOAI" {
            controller = container "odh-model-controller" "Reconciles InferenceService, LLMInferenceService, ServingRuntime, NIM Account; creates Routes, AuthPolicies, EnvoyFilters, ServiceMonitors, NetworkPolicies" "Go Operator (controller-runtime)"
            webhooks = container "Admission Webhooks" "Mutates InferenceServices (credentials/HardwareProfile), LLMInferenceServices, Pods (Ray TLS); validates InferenceGraphs and NIM Account singleton" "Go Webhook Server"
            apiServer = container "model-serving-api" "Provides Gateway discovery and LLM-D sample configuration REST endpoints" "Go HTTPS Server (FIPS)"
            templates = container "ServingRuntime Templates" "vLLM, OVMS, MLServer, Caikit, AutoGluon across CUDA, ROCm, Gaudi, Spyre, CPU with fast-track channels" "Kustomize Templates"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService, ServingRuntime, and LLMInferenceService CRDs" "Internal ODH"
        kuadrant = softwareSystem "Kuadrant / Authorino" "API gateway authentication and authorization via AuthPolicy CRDs" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter for TLS bootstrap on Gateways" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via TriggerAuthentication" "External"
        promOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor and PodMonitor CRDs" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute for LLM inference ingress" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "External route exposure for InferenceServices" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus federation for KEDA metrics" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling for serving mode" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management" "External"
        rhods = softwareSystem "rhods-operator" "RHOAI platform operator providing DataScienceCluster configuration" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata for deployed models" "Internal ODH"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing model serving" "Internal ODH"
        hwProfile = softwareSystem "HardwareProfile Controller" "Resolves hardware scheduling constraints (resources, nodeSelector, tolerations)" "Internal ODH"
        nimAPI = softwareSystem "NVIDIA NIM API" "NGC API for model catalog discovery and API key validation" "External"
        s3 = softwareSystem "S3 Storage" "Model artifact storage accessed via connection credentials" "External"

        # User interactions
        user -> odmcSystem "Creates InferenceService, LLMInferenceService, NIM Account via kubectl"
        dashboardUser -> dashboard "Manages inference services via web UI"
        dashboard -> apiServer "GET /api/v1/gateways, GET /api/v1/samples/llm-d" "HTTPS/8443 FIPS"

        # Internal container relationships
        controller -> webhooks "Webhook admission flow" "HTTPS/9443"

        # Platform dependencies
        odmcSystem -> kserve "Watches InferenceService, ServingRuntime, InferenceGraph, LLMInferenceService CRDs"
        odmcSystem -> kuadrant "Creates AuthPolicies, watches Kuadrant/Authorino availability"
        odmcSystem -> istio "Creates EnvoyFilters for Authorino TLS bootstrap"
        odmcSystem -> keda "Creates TriggerAuthentications for autoscaling"
        odmcSystem -> promOperator "Creates ServiceMonitors and PodMonitors"
        odmcSystem -> gatewayAPI "Watches Gateways, reads HTTPRoutes"
        odmcSystem -> openshiftRouter "Creates Routes for InferenceServices" "HTTPS/443"
        odmcSystem -> openshiftMonitoring "KEDA metrics source" "HTTPS"
        odmcSystem -> knative "Service CRD for serverless mode"
        odmcSystem -> rhods "Reads DataScienceCluster, DSCInitialization config"
        odmcSystem -> modelRegistry "Syncs deployed models to registry" "HTTPS/443"
        odmcSystem -> hwProfile "Resolves HardwareProfile CRDs in webhooks"
        odmcSystem -> nimAPI "Validates API keys, fetches model catalog" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
