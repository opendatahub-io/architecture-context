workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using InferenceService and LLMInferenceService CRs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration via DataScienceCluster and DSCInitialization"
        apiConsumer = person "API Consumer" "Queries gateway discovery and LLM-D sample endpoints"

        odhModelController = softwareSystem "odh-model-controller" "Primary model-serving control plane for RHOAI, managing InferenceService, LLMInferenceService, InferenceGraph, and NIM Account lifecycle" {
            controllerDeployment = container "odh-model-controller" "Controller-runtime operator with 9 reconcilers and 8 admission webhooks" "Go Operator" {
                tags "Primary"
            }
            modelServingAPI = container "model-serving-api" "TLS-secured REST API for gateway discovery and LLM-D sample templates" "Go Service" {
                tags "Primary"
            }
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform providing InferenceService and ServingRuntime CRDs" "External"
        kuadrant = softwareSystem "Kuadrant" "API gateway authentication and authorization via AuthPolicy resources" "External"
        istio = softwareSystem "Istio" "Service mesh providing traffic management and EnvoyFilter support" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing and gateway management" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring infrastructure for PodMonitor and ServiceMonitor management" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collector for OTLP/gRPC trace export" "External"
        openShift = softwareSystem "OpenShift Platform" "Routes, service-ca operator, Authentication config" "External"
        kubernetes = softwareSystem "Kubernetes API" "Core API server for resource operations, RBAC, and admission control" "External"

        dsc = softwareSystem "DataScienceCluster" "Platform CRD for enabled component configuration" "Internal RHOAI"
        dsci = softwareSystem "DSCInitialization" "Platform CRD for initialization state" "Internal RHOAI"
        hardwareProfile = softwareSystem "HardwareProfile" "Infrastructure CRD for hardware profile configuration" "Internal RHOAI"

        dataScientist -> odhModelController "Creates InferenceService, LLMInferenceService, InferenceGraph via kubectl"
        platformAdmin -> odhModelController "Configures NIM Accounts and platform settings"
        apiConsumer -> odhModelController "Queries /api/v1/gateways with Bearer token" "HTTPS/443"

        controllerDeployment -> kubernetes "Watches and manages Kubernetes resources" "HTTPS/6443"
        controllerDeployment -> kserve "Reconciles InferenceService and ServingRuntime CRs"
        controllerDeployment -> kuadrant "Creates and manages AuthPolicy resources"
        controllerDeployment -> istio "Creates and manages EnvoyFilter resources"
        controllerDeployment -> gatewayAPI "Manages Gateway and HTTPRoute resources"
        controllerDeployment -> prometheusOperator "Creates PodMonitor and ServiceMonitor resources"
        controllerDeployment -> openShift "Creates Routes, reads Authentication config"

        modelServingAPI -> kubernetes "SelfSubjectAccessReview, Gateway discovery" "HTTPS/6443"
        modelServingAPI -> otelCollector "Exports traces" "OTLP/gRPC TLS"

        controllerDeployment -> dsc "Watches DataScienceCluster for component state"
        controllerDeployment -> dsci "Watches DSCInitialization for platform state"
        controllerDeployment -> hardwareProfile "Watches HardwareProfile resources"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
