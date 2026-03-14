workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        developer = person "Developer" "Integrates model inference into applications"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift integrations, NIM support, and LLM inference management" {
            controller = container "Model Controller" "Reconciles KServe resources and creates OpenShift/Istio resources" "Go Operator"
            isController = container "InferenceService Controller" "Manages Routes and HTTPRoutes for model endpoints" "Go Reconciler"
            nimController = container "NIM Account Controller" "Manages NVIDIA NIM accounts and NGC integration" "Go Reconciler"
            llmController = container "LLM InferenceService Controller" "Orchestrates LLM inference with flow control and auth" "Go Reconciler"
            metrics = container "Metrics Service" "Exposes Prometheus metrics for controller and model serving" "HTTP Service"
        }

        kserve = softwareSystem "KServe" "Cloud-native model serving framework" "External"
        openShiftRouter = softwareSystem "OpenShift Router" "Exposes model endpoints via Routes" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS, traffic routing, and AuthorizationPolicy" "External"
        k8sGatewayAPI = softwareSystem "Kubernetes Gateway API" "Alternative ingress for model endpoints" "External"
        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA GPU Cloud for NIM models and configurations" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for model serving management" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        s3Storage = softwareSystem "S3 Storage" "Stores model artifacts for serving" "External"
        prometheus = softwareSystem "Prometheus" "Collects metrics from controller and model endpoints" "Internal ODH"
        keda = softwareSystem "KEDA" "Kubernetes Event-Driven Autoscaling for inference workloads" "External"
        trustyai = softwareSystem "TrustyAI" "Model inference monitoring for fairness and explainability" "Internal ODH"

        # User interactions
        dataScientist -> odhDashboard "Creates InferenceServices via UI"
        developer -> odhModelController "Calls model inference endpoints" "HTTPS/443"

        # Controller container relationships
        controller -> isController "Delegates InferenceService reconciliation"
        controller -> nimController "Delegates NIM Account management"
        controller -> llmController "Delegates LLM InferenceService setup"
        controller -> metrics "Exposes metrics"

        # External system dependencies
        odhModelController -> kserve "Extends InferenceService and ServingRuntime CRDs" "HTTPS/6443"
        isController -> openShiftRouter "Creates Routes for model endpoints"
        isController -> k8sGatewayAPI "Creates HTTPRoutes for model endpoints"
        llmController -> istio "Creates AuthorizationPolicies for LLM auth" "HTTPS/6443"
        nimController -> nvidiaNGC "Downloads NIM models and configurations" "HTTPS/443 API Key"

        # Internal ODH integrations
        odhDashboard -> odhModelController "Manages InferenceServices"
        odhModelController -> modelRegistry "Retrieves model metadata" "HTTP/8080"
        odhModelController -> s3Storage "Accesses model artifacts for serving" "HTTPS/443"
        prometheus -> metrics "Scrapes controller and model metrics" "HTTP/8080"
        odhModelController -> keda "Creates ScaledObjects for autoscaling"
        odhModelController -> trustyai "Integrates TrustyAI sidecars for monitoring"

        # External client access
        developer -> openShiftRouter "Sends inference requests" "HTTPS/443"
        openShiftRouter -> istio "Routes via service mesh" "mTLS"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6db3f2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
