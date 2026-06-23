workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and manages ML models via InferenceService and NIM Account resources"
        platformadmin = person "Platform Admin" "Configures RHOAI platform, manages Gateways and LLM serving infrastructure"
        inferenceClient = person "Inference Client" "Sends prediction requests to deployed models"

        odhModelController = softwareSystem "odh-model-controller" "Manages InferenceService lifecycle: Routes, metrics, autoscaling, RBAC, NIM integration, LLM auth policies, Gateway EnvoyFilters" {
            controller = container "odh-model-controller" "Primary operator managing InferenceService reconciliation, LLM auth, NIM integration" "Go Operator (controller-runtime)" {
                isvcReconciler = component "InferenceService Reconciler" "Orchestrates Route, metrics, KEDA, RBAC sub-reconcilers" "controller-runtime"
                llmController = component "LLMInferenceService Controller" "Manages per-service AuthPolicy for LLM serving" "controller-runtime"
                gatewayController = component "Gateway Controller" "Manages EnvoyFilter and AuthPolicy for Gateway bootstrap" "controller-runtime"
                nimAccountController = component "NIM Account Controller" "Manages NVIDIA NIM lifecycle: API key validation, pull secrets, templates" "controller-runtime"
                webhookServer = component "Webhook Server" "Validates InferenceService, InferenceGraph, NIM Account; mutates Pods for Ray TLS" "admission webhook"
                configmapController = component "ConfigMap Controller" "Aggregates CA certificates for S3 storage connections" "controller-runtime"
                secretController = component "Secret Controller" "Aggregates S3 data connection credentials" "controller-runtime"
            }

            apiServer = container "model-serving-api" "REST API for gateway discovery with per-request RBAC" "Go HTTP Server" {
                gatewayDiscovery = component "Gateway Discovery" "Lists available Gateways with RBAC filtering" "HTTP handler"
                authMiddleware = component "Auth Middleware" "Validates bearer token via SelfSubjectAccessReview" "HTTP middleware"
            }
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService, ServingRuntime, InferenceGraph CRDs" "External"
        kuadrant = softwareSystem "Kuadrant" "Gateway API authentication and authorization" "External - Optional"
        authorino = softwareSystem "Authorino" "Authorization provider for Kuadrant auth policies" "External - Optional"
        istio = softwareSystem "Istio" "Service mesh for traffic management and EnvoyFilter" "External - Optional"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for Prometheus-based model autoscaling" "External - Optional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor and PodMonitor" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"
        openshift = softwareSystem "OpenShift" "Container platform providing Routes, Templates, Authentication APIs" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator providing DataScienceCluster and DSCInitialization" "Internal ODH"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for LLM serving ingress" "External - Optional"
        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA GPU Cloud API for NIM runtime catalog and model data" "External Service"
        nvidiaNVCR = softwareSystem "NVIDIA NVCR" "NVIDIA container registry for NIM image pull secrets" "External Service"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing model serving" "Internal ODH"
        kubeflowHub = softwareSystem "Kubeflow Hub" "Model Registry integration for InferenceService registration" "Internal ODH - Optional"

        # User relationships
        datascientist -> odhModelController "Creates InferenceService, NIM Account via kubectl/API"
        platformadmin -> odhModelController "Configures Gateways, LLMInferenceServices"
        inferenceClient -> openshift "Sends prediction requests via OpenShift Routes"

        # Controller dependencies
        odhModelController -> kserve "Watches InferenceService, ServingRuntime, InferenceGraph, LLMInferenceService CRDs"
        odhModelController -> kuadrant "Creates AuthPolicy for Gateway and HTTPRoute auth" "HTTPS"
        odhModelController -> authorino "Configures EnvoyFilter for TLS bootstrap" "gRPC/50051"
        odhModelController -> istio "Creates EnvoyFilter for Envoy-to-Authorino mTLS" "HTTPS"
        odhModelController -> keda "Creates TriggerAuthentication for Prometheus autoscaling" "HTTPS"
        odhModelController -> prometheusOperator "Creates ServiceMonitor/PodMonitor for metrics collection" "HTTPS"
        odhModelController -> certManager "Webhook TLS certificate management" "HTTPS"
        odhModelController -> openshift "Creates Routes, Templates; reads Authentication config" "HTTPS"
        odhModelController -> rhoaiOperator "Reads DataScienceCluster, DSCInitialization for config discovery" "HTTPS"
        odhModelController -> gatewayAPI "Watches Gateway, manages HTTPRoute auth" "HTTPS"
        odhModelController -> nvidiaNGC "Validates API keys, fetches NIM model catalog" "HTTPS/443"
        odhModelController -> nvidiaNVCR "Authenticates for NIM container image pull secrets" "HTTPS/443"
        odhModelController -> kubeflowHub "Model Registry integration for InferenceService registration" "Go import"

        # Dashboard relationship
        rhoaiDashboard -> odhModelController "Discovers available model serving gateways" "HTTPS/8443"
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
            element "External - Optional" {
                background #bbbbbb
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
            element "Internal ODH - Optional" {
                background #a4e05c
                color #333333
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
        }
    }
}
