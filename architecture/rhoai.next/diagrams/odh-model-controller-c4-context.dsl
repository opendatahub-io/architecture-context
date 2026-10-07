workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML model deployments via InferenceService, LLMInferenceService CRs"
        admin = person "Platform Admin" "Configures platform, ClusterServingRuntimes, NIM Accounts, TLS profiles"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes controller extending KServe with platform-specific lifecycle management, admission control, networking, auth integration, and model-serving API" {
            controllerManager = container "Controller Manager" "Runs 10 reconcilers, admission webhooks, TLS profile watcher" "Go / controller-runtime" "controller"
            modelServingApi = container "model-serving-api" "TLS-secured REST API for gateway discovery and LLM-D sample serving" "Go / net/http" "api"
        }

        kserve = softwareSystem "KServe" "Model inference platform providing InferenceService, ServingRuntime, LLMInferenceService CRDs" "Internal ODH"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing" "Internal ODH"
        kuadrant = softwareSystem "Kuadrant" "API management with AuthPolicy for per-service authentication" "Internal ODH"
        keda = softwareSystem "KEDA" "Event-driven autoscaler with TriggerAuthentication for Prometheus-based scaling" "Internal ODH"
        prometheusOp = softwareSystem "Prometheus Operator" "Manages ServiceMonitors and PodMonitors for observability" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilters for traffic management" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Ingress routing for InferenceService endpoints" "External"
        dsc = softwareSystem "DataScienceCluster" "Platform component configuration" "Internal ODH"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives OTLP traces from model-serving-api" "External"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS profile and Authentication config" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Core Kubernetes API for resource CRUD and watches" "External"

        user -> odhModelController "Creates InferenceService/LLMInferenceService CRs via kubectl/dashboard"
        admin -> odhModelController "Configures ClusterServingRuntimes, NIM Accounts"

        controllerManager -> kubeAPI "Watches CRDs, creates/manages resources" "HTTPS/6443"
        controllerManager -> openshiftAPI "Reads/watches cluster TLS profile" "HTTPS/6443"
        controllerManager -> kserve "Watches InferenceService, LLMInferenceService, ServingRuntime, InferenceGraph" "CRD Watch"
        controllerManager -> gatewayAPI "Manages Gateways, HTTPRoutes" "CRD CRUD"
        controllerManager -> kuadrant "Creates AuthPolicies for LLMInferenceService auth" "CRD CRUD"
        controllerManager -> keda "Creates TriggerAuthentications for autoscaling" "CRD CRUD"
        controllerManager -> prometheusOp "Creates ServiceMonitors/PodMonitors" "CRD CRUD"
        controllerManager -> istio "Creates EnvoyFilters for gateway traffic" "CRD CRUD"
        controllerManager -> openshiftRoutes "Creates Routes for InferenceService endpoints" "CRD CRUD"
        controllerManager -> dsc "Reads enabled platform components" "CRD Watch"

        modelServingApi -> kubeAPI "Gateway discovery, SelfSubjectAccessReview" "HTTPS/6443"
        modelServingApi -> otelCollector "Exports traces" "gRPC/OTLP"

        kubeAPI -> controllerManager "Admission webhook calls" "HTTPS/443→9443"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "controller" {
                shape hexagon
            }
            element "api" {
                shape roundedbox
            }
        }
    }
}
