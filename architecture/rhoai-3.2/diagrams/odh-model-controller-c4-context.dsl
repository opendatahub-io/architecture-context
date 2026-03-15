workspace {
    model {
        user = person "Data Scientist" "Deploys and manages ML models via InferenceServices"
        endUser = person "End User" "Consumes inference predictions via HTTP/HTTPS endpoints"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift-specific integrations for model serving workloads" {
            manager = container "Controller Manager" "Reconciles KServe resources and provisions infrastructure" "Go Operator" {
                isvcController = component "InferenceService Controller" "Creates Routes, NetworkPolicies, RBAC, ServiceMonitors" "Reconciler"
                srController = component "ServingRuntime Controller" "Manages ServingRuntime resources" "Reconciler"
                llmController = component "LLMInferenceService Controller" "Creates AuthPolicies and EnvoyFilters" "Reconciler"
                nimController = component "NIM Account Controller" "Validates NGC accounts and provisions pull secrets" "Reconciler"
                igController = component "InferenceGraph Controller" "Manages multi-model inference pipelines" "Reconciler"
            }

            webhookServer = container "Webhook Server" "Validates and mutates KServe resources" "Go HTTPS Server" {
                podWebhook = component "Pod Mutating Webhook" "Mutates predictor pods" "Webhook"
                isvcWebhook = component "InferenceService Webhook" "Validates/defaults InferenceServices" "Webhook"
                nimWebhook = component "NIM Account Webhook" "Validates NIM Account resources" "Webhook"
            }

            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "Go HTTP Server"
        }

        kserve = softwareSystem "KServe" "Core model serving platform providing InferenceService CRDs" "External - RHOAI Component"
        istio = softwareSystem "Istio" "Service mesh for traffic routing and mTLS" "External - Platform"
        kuadrant = softwareSystem "Kuadrant Operator" "Provides AuthPolicy CRD for authentication/authorization" "External - RHOAI Component"
        authorino = softwareSystem "Authorino Operator" "Executes authorization policies defined by Kuadrant" "External - RHOAI Component"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor and PodMonitor CRDs" "External - Platform"
        openshiftAPI = softwareSystem "OpenShift API" "Provides Route CRD for external ingress and Template resources" "External - Platform"
        gatewayAPI = softwareSystem "Gateway API" "Provides HTTPRoute and Gateway resources for advanced routing" "External - Platform"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling for KServe workloads" "External - Platform"
        keda = softwareSystem "KEDA" "Autoscaling via TriggerAuthentication resources" "External - Optional"
        modelRegistry = softwareSystem "Model Registry" "Tracks deployed models and metadata" "Internal ODH - Optional"
        dscOperator = softwareSystem "DSC/DSCI Operator" "Platform configuration via DataScienceCluster CRDs" "Internal ODH"
        nvidiaNGC = softwareSystem "NVIDIA NGC API" "Validates NIM accounts, fetches model lists and pull secrets" "External Service"
        openshiftRouter = softwareSystem "OpenShift Router" "External HTTPS ingress for model endpoints" "External - Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External - Platform"

        # User interactions
        user -> odhModelController "Creates InferenceService, ServingRuntime, Account CRs via kubectl/oc"
        endUser -> openshiftRouter "Sends inference requests via HTTPS"

        # ODH Model Controller integrations
        odhModelController -> k8sAPI "Watches CRDs, creates/updates resources via Kubernetes API" "HTTPS/6443"
        odhModelController -> kserve "Watches InferenceService/ServingRuntime CRDs created by KServe" "Kubernetes API"
        odhModelController -> openshiftAPI "Creates Routes for InferenceService external access" "Kubernetes API"
        odhModelController -> istio "Creates EnvoyFilters for LLM routing and request transformation" "Kubernetes API"
        odhModelController -> kuadrant "Creates AuthPolicies for InferenceService authentication" "Kubernetes API"
        odhModelController -> prometheusOp "Creates ServiceMonitors/PodMonitors for metrics collection" "Kubernetes API"
        odhModelController -> gatewayAPI "Creates HTTPRoute and Gateway resources for routing" "Kubernetes API"
        odhModelController -> modelRegistry "Registers deployed InferenceServices (when enabled)" "HTTPS/443"
        odhModelController -> nvidiaNGC "Validates NIM accounts, fetches model lists and pull secrets" "HTTPS/443"
        odhModelController -> dscOperator "Reads DataScienceCluster and DSCInitialization for platform config" "Kubernetes API"

        # Webhook interactions
        k8sAPI -> webhookServer "Calls webhooks for validation and mutation" "HTTPS/9443"

        # Dependencies
        kserve -> knative "Uses Knative for serverless mode autoscaling" "Kubernetes API"
        kserve -> istio "Uses Istio for traffic management" "Service Mesh"
        kuadrant -> authorino "Delegates authorization enforcement to Authorino" "Kubernetes API"
        openshiftRouter -> kserve "Routes traffic to InferenceService predictor pods" "HTTP/HTTPS"
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

        component manager "ManagerComponents" {
            include *
            autoLayout
        }

        component webhookServer "WebhookComponents" {
            include *
            autoLayout
        }

        styles {
            element "External - Platform" {
                background #999999
                color #ffffff
            }
            element "External - RHOAI Component" {
                background #7ed321
                color #000000
            }
            element "Internal ODH" {
                background #4a90e2
                color #ffffff
            }
            element "Internal ODH - Optional" {
                background #5bc0de
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
            element "Person" {
                shape Person
            }
        }
    }
}
