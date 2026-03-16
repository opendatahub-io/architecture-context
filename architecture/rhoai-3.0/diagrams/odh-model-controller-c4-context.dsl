workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages ML models on OpenShift"
        admin = person "Platform Administrator" "Manages NIM accounts and platform configuration"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe with OpenShift-native model serving capabilities including ingress, security, monitoring, and NIM integration" {
            controllerManager = container "Controller Manager" "Reconciles KServe resources and provisions supporting infrastructure" "Go Operator" {
                isController = component "InferenceService Controller" "Provisions Routes, NetworkPolicies, RBAC, monitoring for InferenceServices" "Reconciler"
                srController = component "ServingRuntime Controller" "Manages ServingRuntime lifecycle" "Reconciler"
                llmController = component "LLMInferenceService Controller" "Handles LLM services with Gateway API integration" "Reconciler"
                igController = component "InferenceGraph Controller" "Manages multi-model inference graphs" "Reconciler"
                nimController = component "NIM Account Controller" "Manages Nvidia NIM account integration, API keys, pull secrets" "Reconciler"
                podController = component "Pod Controller" "Mutates predictor pods for KServe integration" "Reconciler"
                secretController = component "Secret Controller" "Manages secrets for model serving workloads" "Reconciler"
                cmController = component "ConfigMap Controller" "Manages configuration for model serving" "Reconciler"
            }

            webhookServer = container "Webhook Server" "Validates and mutates Pods, InferenceServices, InferenceGraphs, LLMInferenceServices, NIM Accounts" "Go HTTPS Server"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on /metrics endpoint" "HTTP Server"
        }

        # External Dependencies
        kserve = softwareSystem "KServe" "Provides core InferenceService, ServingRuntime, LLMInferenceService CRDs" "External"
        openshift = softwareSystem "OpenShift" "Provides Routes for external ingress, Service CA for certificates, Template API" "External"
        kubernetes = softwareSystem "Kubernetes API Server" "Manages cluster resources and serves admission webhooks" "External"
        prometheus = softwareSystem "Prometheus Operator" "Collects metrics via ServiceMonitor/PodMonitor" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides EnvoyFilter for SSL/TLS passthrough" "External"
        kuadrant = softwareSystem "Kuadrant" "Provides AuthPolicy for authentication/authorization" "External"
        keda = softwareSystem "KEDA" "Provides autoscaling based on custom metrics" "External"
        gatewayAPI = softwareSystem "Gateway API" "Provides HTTPRoute for LLM inference services" "External"
        nvidiaAPI = softwareSystem "Nvidia NGC" "Validates NIM accounts and provides model catalog access" "External"

        # Internal ODH Dependencies
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and deployment information" "Internal ODH"
        dscInit = softwareSystem "DSC Initialization" "Provides platform configuration via DataScienceCluster and DSCInitialization CRDs" "Internal ODH"

        # Relationships - User interactions
        user -> odhModelController "Creates InferenceService, ServingRuntime, LLMInferenceService CRs via kubectl/UI"
        admin -> odhModelController "Creates NIM Account CRs, configures platform settings"

        # Relationships - External dependencies
        odhModelController -> kserve "Watches and reconciles InferenceService, ServingRuntime, LLMInferenceService CRDs"
        odhModelController -> openshift "Creates Routes for external access, uses Service CA for webhook certs, processes Templates for NIM runtimes" "HTTPS/443"
        odhModelController -> kubernetes "Watches CRDs, creates/updates resources, serves admission webhooks" "HTTPS/443, 9443"
        odhModelController -> nvidiaAPI "Validates NIM accounts, fetches model catalogs" "HTTPS/443"
        odhModelController -> prometheus "Creates ServiceMonitors/PodMonitors for metrics collection"
        odhModelController -> istio "Creates EnvoyFilters for SSL passthrough (optional)"
        odhModelController -> kuadrant "Creates AuthPolicies for authentication (optional)"
        odhModelController -> keda "Creates TriggerAuthentications for autoscaling (optional)"
        odhModelController -> gatewayAPI "Manages HTTPRoutes for LLM services (optional)"

        # Relationships - Internal dependencies
        odhModelController -> modelRegistry "Registers deployed InferenceServices (optional)" "HTTPS/443"
        odhModelController -> dscInit "Reads DataScienceCluster and DSCInitialization for platform configuration"

        # Relationships - Monitoring
        prometheus -> odhModelController "Scrapes /metrics endpoint" "HTTP/8080"
        kubernetes -> odhModelController "Calls webhook endpoints for validation/mutation" "HTTPS/9443"
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

        component controllerManager "Components" {
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
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }
}
