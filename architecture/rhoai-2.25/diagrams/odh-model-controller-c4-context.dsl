workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService, InferenceGraph, and NIM Account resources"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and deploys odh-model-controller via rhods-operator"

        odhModelController = softwareSystem "odh-model-controller" "Automates model serving infrastructure lifecycle — networking, security, observability, and NIM integration for KServe workloads on RHOAI" {
            isvcController = container "InferenceService Controller" "Reconciles InferenceService CRs; delegates to mode-specific sub-reconcilers (Serverless/Raw/ModelMesh)" "Go (controller-runtime)"
            igController = container "InferenceGraph Controller" "Reconciles InferenceGraph CRs; creates AuthConfigs for graph endpoints" "Go (controller-runtime)"
            llmController = container "LLMInferenceService Controller" "Reconciles LLMInferenceService CRs; creates Kuadrant AuthPolicies" "Go (controller-runtime)"
            nimController = container "NIM Account Controller" "Manages NVIDIA NIM account lifecycle — validation, catalog sync, pull secrets, ServingRuntime templates" "Go (controller-runtime)"
            podController = container "Pod Controller" "Manages per-pod Ray TLS certificates for multi-node inference" "Go (controller-runtime)"
            configmapController = container "ConfigMap Controller" "Watches CA certificate ConfigMaps; regenerates odh-kserve-custom-ca-bundle" "Go (controller-runtime)"
            secretController = container "Secret Controller" "Watches data connection secrets; regenerates storage-config" "Go (controller-runtime)"
            srtController = container "ServingRuntime Controller" "Creates Ray TLS CA, Prometheus RoleBindings for ServingRuntimes" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates Pods, InferenceServices, InferenceGraphs, NIM Accounts, Knative Services" "Go (9443/TCP HTTPS)"
            deltaProcessor = container "Delta Processor" "Computes desired vs. existing state; determines create/update/delete via 17 type-specific comparators" "Go"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys and manages odh-model-controller Deployment; sets feature state env vars" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Provides InferenceService, InferenceGraph, LLMInferenceService, ServingRuntime CRDs and core model serving" "Internal RHOAI"
        istio = softwareSystem "Istio / Red Hat Service Mesh" "Service mesh for traffic management, mTLS, gateways, virtual services, telemetry" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for Serverless mode InferenceServices" "External"
        authorino = softwareSystem "Authorino" "Request-level authentication and authorization for inference endpoints via AuthConfig CRDs" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant" "Gateway-bound authentication for LLMInferenceService via AuthPolicy CRDs" "Internal RHOAI"
        keda = softwareSystem "KEDA" "Event-driven autoscaling using Prometheus metrics via TriggerAuthentication CRDs" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via ServiceMonitor and PodMonitor CRDs" "External"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model metadata registration and tracking" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "External access via Route CRDs for inference endpoints" "External"
        nvidiaAPI = softwareSystem "NVIDIA NGC API" "API key validation, model catalog queries, token exchange" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "CRD watches, resource CRUD operations across 15+ API groups" "External"

        dataScientist -> odhModelController "Creates InferenceService / InferenceGraph / NIM Account via kubectl/API"
        platformAdmin -> rhodsOperator "Configures RHOAI platform and component states"
        rhodsOperator -> odhModelController "Deploys controller, sets KSERVE_STATE/MODELMESH_STATE/NIM_STATE/MODELREGISTRY_STATE"

        odhModelController -> kserve "Watches InferenceService, InferenceGraph, LLMInferenceService, ServingRuntime CRDs"
        odhModelController -> istio "Creates Gateways, VirtualServices, PeerAuthentications, Telemetries; enrolls namespaces via ServiceMeshMember"
        odhModelController -> knative "Validates Knative Service mesh membership in webhook"
        odhModelController -> authorino "Creates AuthConfig resources for inference endpoint authentication"
        odhModelController -> kuadrant "Creates AuthPolicy resources for LLMInferenceService gateway auth"
        odhModelController -> keda "Creates TriggerAuthentication resources for Prometheus-based autoscaling"
        odhModelController -> prometheus "Creates ServiceMonitors, PodMonitors, RoleBindings for metrics scraping"
        odhModelController -> modelRegistry "Registers InferenceService metadata for model tracking" "HTTPS/varies"
        odhModelController -> openshiftRouter "Creates OpenShift Routes for external inference access" "HTTPS/443"
        odhModelController -> nvidiaAPI "Validates API keys, fetches model catalog, obtains auth tokens" "HTTPS/443"
        odhModelController -> k8sAPI "CRD watches, resource CRUD across all managed API groups" "HTTPS/443"

        isvcController -> deltaProcessor "Uses for create/update/delete decisions"
        nimController -> nvidiaAPI "NGC API key validation and catalog sync"
        podController -> k8sAPI "Creates per-pod Ray TLS certificates"
        webhookServer -> k8sAPI "Receives webhook calls from API server"
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
        }
    }
}
