workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService, LLMInferenceService, and NIM Account resources"
        platformAdmin = person "Platform Admin" "Configures DataScienceCluster, Gateways, and platform-level resources"

        odmcSystem = softwareSystem "odh-model-controller" "Extends KServe with RHOAI-specific capabilities: ingress, auth policies, NIM lifecycle, metrics, and gateway discovery" {
            controller = container "odh-model-controller" "Reconciles InferenceService, LLMInferenceService, InferenceGraph, ServingRuntime, Gateway, and NIM Account CRs" "Go Operator (controller-runtime)"
            webhooks = container "Admission Webhooks" "Injects credentials, hardware profiles, Ray TLS; validates names, namespaces, NIM accounts, InferenceGraph URLs" "Mutating + Validating Webhooks"
            apiServer = container "model-serving-api" "Gateway discovery API with FIPS TLS, bearer token auth, RBAC-scoped responses" "Go HTTP Server"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService, ServingRuntime, LLMInferenceService CRDs" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Authentication and authorization policy enforcement for Gateway API" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter CRD for traffic and TLS configuration" "Conditional"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes-native API for managing network gateways and HTTP routing" "Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides Route CRD for external ingress with TLS termination" "Platform"
        prometheus = softwareSystem "Prometheus Operator" "ServiceMonitor and PodMonitor CRDs for metrics collection" "Platform"
        keda = softwareSystem "KEDA" "TriggerAuthentication CRD for Prometheus-based autoscaling" "Conditional"
        dsc = softwareSystem "DataScienceCluster / DSCI" "Platform initialization and component configuration" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and serves model metadata for registry integration" "Internal RHOAI"
        hardwareProfile = softwareSystem "HardwareProfile" "Defines scheduling constraints (Kueue, node selectors, tolerations)" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "User-facing web UI for model serving and deployment" "Internal RHOAI"
        ngcAPI = softwareSystem "NVIDIA NGC API" "Cloud catalog for NIM runtime and model metadata" "External"
        nvcrRegistry = softwareSystem "NVIDIA Container Registry (nvcr.io)" "Container image registry for NIM runtimes" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource CRUD operations" "Platform"

        dataScientist -> odmcSystem "Creates InferenceService, LLMInferenceService, NIM Account via kubectl"
        platformAdmin -> odmcSystem "Configures Gateways, DataScienceCluster"

        controller -> k8sAPI "CRUD on Routes, AuthPolicies, EnvoyFilters, ServiceMonitors, Secrets, ConfigMaps" "HTTPS/443"
        controller -> ngcAPI "Validates API keys, fetches NIM model metadata" "HTTPS/443"
        controller -> nvcrRegistry "Validates NIM images via manifest pulls" "HTTPS/443"
        controller -> kuadrant "Creates AuthPolicy resources; watches Kuadrant/Authorino CRs" "HTTPS/443"
        controller -> istio "Creates EnvoyFilter for Authorino gRPC TLS cluster" "HTTPS/443"
        controller -> openshiftRouter "Creates Routes for InferenceService external access" "HTTPS/443"
        controller -> prometheus "Creates ServiceMonitor and PodMonitor per ISVC/Gateway" "HTTPS/443"
        controller -> keda "Creates TriggerAuthentication for Prometheus autoscaling" "HTTPS/443"
        controller -> modelRegistry "Labels ISVCs with model registry metadata" "HTTPS/443"

        apiServer -> k8sAPI "SelfSubjectAccessReview, list Gateways" "HTTPS/443"
        dashboard -> apiServer "GET /api/v1/gateways for gateway discovery" "HTTPS/8443"

        odmcSystem -> kserve "Watches and extends InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph CRs"
        odmcSystem -> gatewayAPI "Watches Gateway CRs; creates per-gateway EnvoyFilter, AuthPolicy, PodMonitor"
        odmcSystem -> dsc "Reads DSC spec for NIM air-gapped mode, component configuration"
        odmcSystem -> hardwareProfile "Reads HardwareProfile CRs for scheduling constraint injection"

        k8sAPI -> webhooks "Sends AdmissionReview requests for ISVC, LLMISVC, Pod, NIM Account, InferenceGraph" "HTTPS/9443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Conditional" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
