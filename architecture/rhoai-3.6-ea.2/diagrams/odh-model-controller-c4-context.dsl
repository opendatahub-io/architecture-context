workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService resources"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration, TLS profiles, and NIM accounts"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes controller extending KServe with RHOAI-specific model serving: gateway routing, TLS, multi-accelerator runtimes, NIM integration" {
            controllerManager = container "odh-model-controller" "Controller manager with 10 reconcilers and 8 admission webhooks" "Go / controller-runtime" "Controller"
            modelServingApi = container "model-serving-api" "REST API for gateway discovery and LLM-D sample templates" "Go / HTTPS" "API Server"
        }

        kserve = softwareSystem "KServe" "Core ML inference serving platform providing InferenceService, ServingRuntime, and InferenceGraph CRDs" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and EnvoyFilter configuration" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for LLM serving traffic routing" "External"
        kuadrant = softwareSystem "Kuadrant" "API gateway policy engine providing AuthPolicy for per-service authentication" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler providing TriggerAuthentication for inference workloads" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack operator managing ServiceMonitor and PodMonitor resources" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Provides Routes, service-CA TLS, APIServer TLS profiles, and Templates" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Core API server for resource CRUD, watches, and RBAC enforcement" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing model serving" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "Platform component enablement configuration" "Internal ODH"

        # Relationships
        dataScientist -> odhModelController "Creates InferenceService / LLMInferenceService via kubectl"
        platformAdmin -> odhModelController "Configures NIM accounts, TLS profiles, serving runtimes"
        rhoaiDashboard -> modelServingApi "Discovers gateways and retrieves LLM-D templates" "HTTPS/443"

        controllerManager -> kubernetesAPI "Watches CRDs, creates sub-resources (Routes, RBAC, NetworkPolicies, monitors)" "HTTPS/6443"
        controllerManager -> kserve "Watches and manages InferenceService, ServingRuntime, InferenceGraph lifecycle"
        controllerManager -> istio "Creates EnvoyFilters for gateway traffic shaping"
        controllerManager -> gatewayAPI "Manages shared Gateway and per-service HTTPRoutes"
        controllerManager -> kuadrant "Creates per-service AuthPolicies for LLM workloads"
        controllerManager -> keda "Creates TriggerAuthentications for autoscaling"
        controllerManager -> prometheusOperator "Creates ServiceMonitors and PodMonitors"
        controllerManager -> openshiftPlatform "Creates Routes, reads TLS profiles, provisions NIM Templates"
        controllerManager -> dsc "Reads platform component enablement state"
        controllerManager -> modelRegistry "Integrates model metadata (when enabled)" "gRPC"

        modelServingApi -> kubernetesAPI "Lists Gateways, performs SelfSubjectAccessReview" "HTTPS/6443"
        modelServingApi -> otel "Exports distributed traces" "OTLP/gRPC"
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
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "API Server" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}
