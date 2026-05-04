workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via InferenceService CRs"
        platformadmin = person "Platform Admin" "Manages RHOAI platform configuration and NIM accounts"

        odmcSystem = softwareSystem "odh-model-controller" "Kubernetes operator automating model serving infrastructure for KServe InferenceServices, LLM auth, and NVIDIA NIM integration" {
            controller = container "odh-model-controller" "Manages InferenceService lifecycle: Routes, monitoring, KEDA, auth policies, NIM integration" "Go Operator (controller-runtime)" "Operator"
            apiserver = container "model-serving-api" "HTTPS gateway discovery API with per-user RBAC authorization" "Go HTTP Server" "APIServer"
        }

        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService, ServingRuntime, LLMInferenceService CRDs" "External"
        kuadrant = softwareSystem "Kuadrant Operator" "API gateway auth policy enforcement via AuthPolicy CRD" "External"
        authorino = softwareSystem "Authorino" "External authorization service for Envoy-based auth" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing EnvoyFilter CRD for proxy configuration" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler providing TriggerAuthentication CRD" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor and PodMonitor CRDs" "External"
        openshift = softwareSystem "OpenShift Platform" "Routes, Templates, cluster Authentication config, serving-cert" "External"
        gatewayapi = softwareSystem "Gateway API" "Gateway and HTTPRoute CRDs for inference routing" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling for inference workloads" "External"

        modelregistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata, labels, and inference service IDs" "Internal ODH"
        rhoaidashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing data science projects and model serving" "Internal ODH"
        rhodsoperator = softwareSystem "rhods-operator" "Platform operator managing DataScienceCluster and DSCInitialization CRDs" "Internal ODH"

        ngcapi = softwareSystem "NVIDIA NGC API" "NIM runtime discovery, API key validation, model catalog" "External Service"
        nvcr = softwareSystem "nvcr.io Registry" "NVIDIA container registry for NIM runtime images" "External Service"
        s3storage = softwareSystem "S3 / Object Storage" "Model artifact storage for KServe inference" "External Service"

        # User interactions
        datascientist -> odmcSystem "Creates InferenceService CRs via kubectl/API"
        platformadmin -> odmcSystem "Creates NIM Account CRs, manages platform config"
        rhoaidashboard -> odmcSystem "Queries gateway discovery API" "HTTPS/443"

        # Controller dependencies
        odmcSystem -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService CRDs"
        odmcSystem -> kuadrant "Creates AuthPolicy CRDs for auth enforcement"
        odmcSystem -> authorino "Detects TLS bootstrap config for EnvoyFilter creation"
        odmcSystem -> istio "Creates EnvoyFilter CRDs for proxy configuration"
        odmcSystem -> keda "Creates TriggerAuthentication for Prometheus-based autoscaling"
        odmcSystem -> prometheus "Creates ServiceMonitor/PodMonitor for metrics scraping"
        odmcSystem -> openshift "Creates Routes, Templates; reads Authentication config" "HTTPS/443"
        odmcSystem -> gatewayapi "Watches/updates Gateway, reads HTTPRoute CRDs"
        odmcSystem -> knative "Integrates with Knative Services for serverless inference"

        # Internal ODH
        odmcSystem -> modelregistry "Syncs InferenceService metadata" "HTTP(S)"
        odmcSystem -> rhodsoperator "Reads DataScienceCluster, DSCInitialization config"

        # External services
        odmcSystem -> ngcapi "Validates API keys, discovers NIM runtimes" "HTTPS/443"
        odmcSystem -> nvcr "Acquires pull tokens for NIM images" "HTTPS/443"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "APIServer" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
