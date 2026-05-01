workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via InferenceService"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and NIM accounts"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe with OpenShift ingress, auth, observability, and NIM management for RHOAI" {
            manager = container "Manager (Operator)" "Multi-controller operator managing routes, auth, monitoring, TLS, RBAC for KServe resources" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates/mutates InferenceService, InferenceGraph, NIM Account, and Pod resources" "Go (admission webhooks)"
            modelServingApi = container "model-serving-api" "REST API for Gateway API resource discovery with RBAC-enforced namespace filtering" "Go HTTP Server"

            manager -> webhookServer "Hosts webhooks on :9443" "HTTPS/TLS"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform providing InferenceService, LLMInferenceService, ServingRuntime CRDs" "External"
        kuadrant = softwareSystem "Kuadrant" "API management providing AuthPolicy CRD for Gateway API authentication" "External"
        authorino = softwareSystem "Authorino" "Authentication provider for Kuadrant AuthPolicies" "External"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter CRD for TLS configuration on Gateways" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler providing TriggerAuthentication CRD" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "ServiceMonitor/PodMonitor CRDs for metrics scraping" "External"
        gatewayAPI = softwareSystem "Gateway API Controller" "Manages Gateway and HTTPRoute resources" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Manages OpenShift Route resources for external access" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "UI for managing model serving on RHOAI" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator providing DataScienceCluster config" "Internal ODH"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata for InferenceService lifecycle" "Internal ODH"

        nvidiaNGC = softwareSystem "NVIDIA NGC API" "NVIDIA cloud services for NIM runtime catalog and API key validation" "External Cloud"
        s3Storage = softwareSystem "S3 Storage" "Object storage for ML model artifacts" "External Cloud"

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource management" "Infrastructure"

        # User interactions
        datascientist -> kserve "Creates InferenceService via kubectl" "HTTPS/443"
        platformadmin -> odhModelController "Creates NIM Account via kubectl" "HTTPS/443"

        # Core operator interactions
        odhModelController -> k8sAPI "Watches CRDs, creates/manages resources" "HTTPS/443 SA token"
        odhModelController -> kserve "Watches InferenceService, LLMInferenceService, ServingRuntime, InferenceGraph" "CRD Watch"
        odhModelController -> openshiftRouter "Creates Routes for external model access" "CRD Create"
        odhModelController -> kuadrant "Creates AuthPolicies for authentication" "CRD Create"
        odhModelController -> istio "Creates EnvoyFilters for TLS termination" "CRD Create"
        odhModelController -> keda "Creates TriggerAuthentications for autoscaling" "CRD Create"
        odhModelController -> prometheusOp "Creates ServiceMonitors for metrics scraping" "CRD Create"
        odhModelController -> gatewayAPI "Watches Gateways, reads HTTPRoutes" "CRD Watch"

        # Platform dependencies
        odhModelController -> rhodsOperator "Reads DataScienceCluster config" "CRD Read"
        odhModelController -> modelRegistry "Syncs model metadata labels/annotations" "HTTP(S) Bearer Token"
        odhModelController -> authorino "Detects TLS config for EnvoyFilter decisions" "CRD Watch"

        # External cloud dependencies
        odhModelController -> nvidiaNGC "Validates NIM API keys, fetches runtime catalog" "HTTPS/443 Bearer Token"

        # Dashboard integration
        rhoaiDashboard -> modelServingApi "Discovers Gateway listeners for namespaces" "HTTPS/8443 Bearer Token"
        modelServingApi -> k8sAPI "Lists Gateways with RBAC checks" "HTTPS/443 User-impersonated"
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
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
