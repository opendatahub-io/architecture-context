workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models using InferenceService, InferenceGraph, and LLMInferenceService CRs"
        platformadmin = person "Platform Admin" "Manages RHOAI platform configuration, NIM accounts, and serving runtimes"

        odmController = softwareSystem "odh-model-controller" "Kubernetes controller-manager that reconciles model serving resources for Red Hat OpenShift AI" {
            controllerManager = container "Controller Manager" "Runs 9 reconciliation controllers, 2 cleanup runners, and 8 admission webhooks" "Go / controller-runtime 0.22.5" {
                accountCtrl = component "Account Controller" "Reconciles NIM Account CRs" "Go Controller"
                configmapCtrl = component "ConfigMap Controller" "Reconciles ConfigMap resources" "Go Controller"
                gatewayCtrl = component "Gateway Controller" "Reconciles Gateway API routing resources" "Go Controller"
                inferenceGraphCtrl = component "InferenceGraph Controller" "Reconciles InferenceGraph resources" "Go Controller"
                inferenceServiceCtrl = component "InferenceService Controller" "Reconciles InferenceService resources" "Go Controller"
                llmIsvcCtrl = component "LLMInferenceService Controller" "Reconciles LLMInferenceService resources" "Go Controller"
                podCtrl = component "Pod Controller" "Reconciles Pod resources for predictor labeling" "Go Controller"
                secretCtrl = component "Secret Controller" "Reconciles Secret resources" "Go Controller"
                servingRuntimeCtrl = component "ServingRuntime Controller" "Reconciles ServingRuntime resources" "Go Controller"
                webhookServer = component "Webhook Server" "5 mutating + 3 validating admission webhooks" "Go / 9443 TLS"
                maasCleanup = component "MaaSRBACCleanupRunner" "Background RBAC cleanup" "Go Background Runner"
                nimCleanup = component "NIMCleanupRunner" "Background NIM resource cleanup" "Go Background Runner"
            }
            modelServingAPI = container "model-serving-api" "Gateway discovery and LLM-D sample API server" "Go / 8443 TLS"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD and watches" "External Infrastructure" {
            tags "External"
        }

        kserve = softwareSystem "KServe" "ML model serving framework providing InferenceService, InferenceGraph, LLMInferenceService, and ServingRuntime CRDs" "Internal ODH" {
            tags "Internal ODH"
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing (Gateways, HTTPRoutes)" "Internal Platform" {
            tags "Internal ODH"
        }

        kuadrant = softwareSystem "Kuadrant" "API management providing AuthPolicy for access control" "Internal Platform" {
            tags "Internal ODH"
        }

        istio = softwareSystem "Istio" "Service mesh providing EnvoyFilters for traffic management" "External" {
            tags "External"
        }

        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack managing ServiceMonitors and PodMonitors" "External" {
            tags "External"
        }

        keda = softwareSystem "KEDA" "Event-driven autoscaling with TriggerAuthentications" "External" {
            tags "External"
        }

        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External" {
            tags "External"
        }

        openShiftServiceCA = softwareSystem "OpenShift service-ca" "Certificate provisioning for TLS secrets" "External" {
            tags "External"
        }

        rhoaiPlatform = softwareSystem "RHOAI Platform" "DataScienceCluster and DSCInitialization CRs" "Internal ODH" {
            tags "Internal ODH"
        }

        datascientist -> odmController "Creates InferenceService, InferenceGraph, LLMInferenceService CRs" "kubectl / API"
        platformadmin -> odmController "Manages NIM Accounts, ServingRuntimes, platform config" "kubectl / API"

        odmController -> kubernetesAPI "CRUD and watches on 75+ resource types" "HTTPS/6443 TLS 1.2+"
        odmController -> kserve "Watches and manages InferenceService, InferenceGraph, ServingRuntime" "Kubernetes API TLS"
        odmController -> gatewayAPI "Manages Gateway and HTTPRoute resources" "Kubernetes API TLS"
        odmController -> kuadrant "Creates/manages AuthPolicies for access control" "Kubernetes API TLS"
        odmController -> istio "Creates/manages EnvoyFilters" "Kubernetes API TLS"
        odmController -> prometheusOperator "Creates ServiceMonitors and PodMonitors" "Kubernetes API TLS"
        odmController -> keda "Creates TriggerAuthentications for autoscaling" "Kubernetes API TLS"
        odmController -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        odmController -> rhoaiPlatform "Watches DataScienceCluster and DSCInitialization state" "Kubernetes API TLS"
        openShiftServiceCA -> odmController "Provisions TLS certificates for webhook and API server" "Automatic"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
