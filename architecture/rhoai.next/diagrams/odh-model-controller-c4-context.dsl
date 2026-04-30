workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures NIM accounts and Gateway resources"

        odmController = softwareSystem "odh-model-controller" "Sidecar operator extending KServe with OpenShift ingress, auth, monitoring, NIM, and Gateway API integration" {
            manager = container "Manager" "Runs all reconcilers and webhooks for KServe resource augmentation" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates/mutates InferenceServices, Accounts, InferenceGraphs, Pods" "Go (9443/TCP TLS)"
            modelServingAPI = container "model-serving-api" "REST API for Gateway listener discovery with RBAC enforcement" "Go HTTP Server (8443/TCP HTTPS FIPS)"
            isReconciler = container "InferenceService Reconciler" "Creates Routes, NetworkPolicies, ServiceMonitors, KEDA TriggerAuth" "Go Controller"
            llmReconciler = container "LLMInferenceService Reconciler" "Creates AuthPolicies for LLM serving endpoints" "Go Controller"
            gwReconciler = container "Gateway Reconciler" "Creates EnvoyFilters and AuthPolicies on Gateways" "Go Controller"
            nimReconciler = container "NIM Account Reconciler" "Validates NVIDIA API keys, provisions templates and pull secrets" "Go Controller"
            cmReconciler = container "ConfigMap Reconciler" "Aggregates CA certificates into KServe-consumable ConfigMap" "Go Controller"
            secretReconciler = container "Secret Reconciler" "Consolidates S3 data connections into storage-config" "Go Controller"
            podReconciler = container "Pod Reconciler" "Manages per-pod Ray TLS certificates" "Go Controller"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform providing InferenceService CRD" "External"
        kuadrant = softwareSystem "Kuadrant" "API management with AuthPolicy CRD for authentication" "External (conditional)"
        authorino = softwareSystem "Authorino" "Authentication provider for Kuadrant AuthPolicies" "External (conditional)"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilter CRD and Gateway API controller" "External (conditional)"
        keda = softwareSystem "KEDA" "Event-driven autoscaler with TriggerAuthentication CRD" "External (conditional)"
        prometheusOp = softwareSystem "Prometheus Operator" "ServiceMonitor and PodMonitor CRD provider" "External (conditional)"
        openshiftRouter = softwareSystem "OpenShift Router" "Manages OpenShift Route resources for external access" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator providing DSC and DSCI CRDs" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI consuming Gateway discovery API" "Internal ODH"
        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA cloud services for NIM runtime catalog and API key validation" "External"
        nvcr = softwareSystem "nvcr.io" "NVIDIA container registry for NIM runtime images" "External"
        kubeflowMR = softwareSystem "Kubeflow Model Registry" "Model metadata storage for InferenceService lifecycle sync" "External (conditional)"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD operations and RBAC" "Infrastructure"

        # User interactions
        dataScientist -> odmController "Creates InferenceService/LLMInferenceService via kubectl"
        platformAdmin -> odmController "Creates NIM Account and Gateway resources"
        rhoaiDashboard -> modelServingAPI "Discovers Gateway listeners" "HTTPS/443 Bearer Token"

        # Operator to dependencies
        odmController -> kserve "Watches InferenceService, ServingRuntime, InferenceGraph CRDs" "HTTPS/443"
        odmController -> kuadrant "Creates AuthPolicies for model serving endpoints" "HTTPS/443"
        odmController -> authorino "Detects TLS config for EnvoyFilter decisions" "HTTPS/443"
        odmController -> istio "Creates EnvoyFilters on Gateways" "HTTPS/443"
        odmController -> keda "Creates TriggerAuthentications for autoscaling" "HTTPS/443"
        odmController -> prometheusOp "Creates ServiceMonitors for metrics scraping" "HTTPS/443"
        odmController -> openshiftRouter "Creates Routes for external model access" "HTTPS/443"
        odmController -> rhodsOperator "Reads platform config (DSC, DSCI)" "HTTPS/443"
        odmController -> nvidiaNGC "Validates NIM API keys, fetches model catalog" "HTTPS/443 Bearer Token"
        odmController -> nvcr "Verifies NIM container image manifests" "HTTPS/443 Bearer Token"
        odmController -> kubeflowMR "Syncs model metadata labels/annotations" "HTTP(S) Bearer Token"
        odmController -> k8sAPI "CRD watches, resource CRUD, RBAC checks" "HTTPS/443 SA Token"

        # Internal container relationships
        manager -> isReconciler "Starts"
        manager -> llmReconciler "Starts"
        manager -> gwReconciler "Starts"
        manager -> nimReconciler "Starts"
        manager -> cmReconciler "Starts"
        manager -> secretReconciler "Starts"
        manager -> podReconciler "Starts"
        manager -> webhookServer "Embeds"
    }

    views {
        systemContext odmController "SystemContext" {
            include *
            autoLayout
        }

        container odmController "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (conditional)" {
                background #bbbbbb
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
        }
    }
}
