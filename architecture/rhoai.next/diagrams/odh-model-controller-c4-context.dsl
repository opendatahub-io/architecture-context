workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformadmin = person "Platform Admin" "Manages NIM Accounts and platform configuration"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes operator and API server automating model serving infrastructure lifecycle for KServe on RHOAI" {
            controller = container "odh-model-controller" "Manages InferenceService lifecycle — Routes, RBAC, monitoring, auth policies, EnvoyFilters, NIM accounts, Ray TLS, KEDA" "Go Operator (controller-runtime)" "Operator"
            apiServer = container "model-serving-api" "Gateway discovery endpoint with per-user RBAC enforcement for LLMInferenceService creation" "Go REST Server" "API"
            webhooks = container "Admission Webhooks" "Pod mutation (Ray TLS), InferenceService validation, InferenceGraph validation, NIM Account singleton" "Go Webhook Handlers" "Webhook"
            runtimeTemplates = container "ServingRuntime Templates" "Pre-configured templates for vLLM (CUDA/ROCm/Gaudi/CPU/Spyre), OVMS, MLServer, guardrails" "OpenShift Templates" "Config"
        }

        kserve = softwareSystem "KServe" "Core ML inference platform — manages predictor pods, transformers, and explainers" "External"
        kuadrant = softwareSystem "Kuadrant" "API management — AuthPolicy CRDs for authentication/authorization on Gateway API" "External"
        authorino = softwareSystem "Authorino" "Authorization service backend for Kuadrant AuthPolicies" "External"
        istio = softwareSystem "Istio" "Service mesh — EnvoyFilter CRDs for TLS and external authorization" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute for ingress management" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling — TriggerAuthentication for Prometheus-based scaling" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring — ServiceMonitor and PodMonitor CRDs" "External"
        openshift = softwareSystem "OpenShift" "Platform — Routes, Templates, Authentication, Config APIs" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "External"

        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM model catalog discovery, API key validation, token exchange" "External Service"
        modelRegistry = softwareSystem "Model Registry" "Stores InferenceService metadata (optional)" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "UI for model deployment — calls model-serving-api for gateway discovery" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator — deploys odh-model-controller via kustomize" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "Platform CRD — Model Registry namespace, air-gapped mode" "Internal ODH"

        datascientist -> odhModelController "Creates InferenceService/LLMInferenceService via kubectl"
        platformadmin -> odhModelController "Creates NIM Account CRD to enable NVIDIA NIM"
        rhoaiDashboard -> apiServer "GET /api/v1/gateways with user bearer token" "HTTPS/443"

        controller -> k8sAPI "CRUD on Routes, ServiceMonitors, ClusterRoleBindings, AuthPolicies, EnvoyFilters" "HTTPS/443"
        controller -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph CRDs" "Watch stream"
        controller -> kuadrant "Creates AuthPolicy CRDs for Gateway/HTTPRoute authentication" "HTTPS/443"
        controller -> authorino "Configures auth chain via EnvoyFilter (gRPC/mTLS)" "gRPC/50051"
        controller -> istio "Creates EnvoyFilters for TLS bootstrap on Gateways" "HTTPS/443"
        controller -> gatewayAPI "Watches Gateway CRDs, manages finalizers" "Watch stream"
        controller -> keda "Creates TriggerAuthentication for Prometheus-based autoscaling" "HTTPS/443"
        controller -> prometheus "Creates ServiceMonitor/PodMonitor per InferenceService" "HTTPS/443"
        controller -> openshift "Creates Routes for external access, Templates for NIM runtimes" "HTTPS/443"
        controller -> ngcAPI "NIM: API key validation, model catalog, token exchange" "HTTPS/443"
        controller -> modelRegistry "Registers InferenceService metadata (optional)" "HTTPS"
        controller -> dsc "Reads Model Registry namespace and air-gapped mode config" "HTTPS/443"

        apiServer -> k8sAPI "SelfSubjectAccessReview (user token), List Gateways (SA token)" "HTTPS/443"

        rhodsOperator -> odhModelController "Deploys controller and API server via kustomize manifests"

        k8sAPI -> webhooks "Admission review requests" "HTTPS/443"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "API" {
                background #f5a623
                color #ffffff
            }
            element "Webhook" {
                background #e57373
                color #ffffff
            }
            element "Config" {
                background #82b366
                color #ffffff
            }
        }
    }
}
