workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via InferenceService CRs"
        platformadmin = person "Platform Admin" "Manages RHOAI platform configuration and NIM accounts"
        dashboarduser = person "Dashboard User" "Uses RHOAI Dashboard or CLI to discover gateways and deploy models"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes controller managing model serving lifecycle — networking, security, observability, and secrets for InferenceServices" {
            manager = container "Controller Manager" "Runs 8+ reconcilers and 8 admission webhooks for InferenceService, LLMInferenceService, Gateway, ServingRuntime, NIM Account, and related resources" "Go / controller-runtime"
            modelServingApi = container "model-serving-api" "HTTPS REST API for gateway discovery and LLM-D sample manifests" "Go / net/http"
            servingRuntimes = container "ClusterServingRuntimes" "27 runtime definitions covering vLLM (CUDA, ROCm, Gaudi, CPU, Spyre), MLServer, and OVMS with fast-channel tiers" "Kustomize / YAML"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD, watches, admission webhooks, and authorization" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService, LLMInferenceService, ServingRuntime CRDs" "Internal RHOAI"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes ingress management via Gateway and HTTPRoute resources" "External"
        kuadrant = softwareSystem "Kuadrant" "API management providing AuthPolicy for inference endpoint authentication" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh for traffic management via EnvoyFilters" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with TriggerAuthentication for Prometheus metrics" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring via ServiceMonitor and PodMonitor CRDs" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Routes, APIServer TLS profile, service-ca certificates" "External"
        odhDashboard = softwareSystem "RHOAI Dashboard" "Web UI for model serving management" "Internal RHOAI"
        dscOperator = softwareSystem "DSC Operator" "DataScienceCluster and DSCInitialization CRs for platform state" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP/gRPC" "External"

        datascientist -> odhModelController "Creates InferenceService / LLMInferenceService CRs via kubectl"
        platformadmin -> odhModelController "Manages NIM Accounts and ServingRuntime configuration"
        dashboarduser -> modelServingApi "Discovers gateways and retrieves sample manifests" "HTTPS/443"

        odhModelController -> kubernetesApi "Watches CRs, creates/manages Routes, NetworkPolicies, RBAC, Secrets, ServiceMonitors" "HTTPS/6443"
        odhModelController -> kserve "Watches and reconciles InferenceService, LLMInferenceService, ServingRuntime CRDs"
        odhModelController -> gatewayApi "Manages Gateway and HTTPRoute resources for model serving ingress"
        odhModelController -> kuadrant "Creates AuthPolicies for inference endpoint authentication"
        odhModelController -> istio "Creates EnvoyFilters for traffic shaping"
        odhModelController -> keda "Creates TriggerAuthentications for autoscaling"
        odhModelController -> prometheusOperator "Creates ServiceMonitors and PodMonitors"
        odhModelController -> openshiftPlatform "Reads TLS profile, creates Routes, uses service-ca certificates"
        odhModelController -> dscOperator "Reads DataScienceCluster and DSCInitialization state"
        modelServingApi -> otel "Exports distributed traces" "OTLP/gRPC"

        odhDashboard -> modelServingApi "Gateway discovery and sample manifests" "HTTPS/443"
        kubernetesApi -> manager "Sends admission webhook requests" "HTTPS/9443"
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
