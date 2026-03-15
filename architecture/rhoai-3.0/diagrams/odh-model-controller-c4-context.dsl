workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages ML models for inference"
        admin = person "Platform Administrator" "Manages Nvidia NIM accounts and platform configuration"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe with OpenShift-native model serving capabilities including ingress, security, monitoring, and NIM integration" {
            controller = container "Controller Manager" "Reconciles KServe resources and provisions supporting infrastructure" "Go Operator" {
                inferenceServiceController = component "InferenceService Controller" "Provisions Routes, NetworkPolicies, RBAC, monitoring for inference services"
                servingRuntimeController = component "ServingRuntime Controller" "Manages ServingRuntime lifecycle"
                llmController = component "LLMInferenceService Controller" "Handles LLM inference with Gateway API integration"
                nimController = component "NIM Account Controller" "Manages Nvidia NIM account integration and runtime templates"
                webhookServer = component "Webhook Server" "Validates and mutates Pods, InferenceServices, NIM Accounts"
            }
        }

        # External Dependencies
        kserve = softwareSystem "KServe" "Provides core InferenceService and ServingRuntime CRDs" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Routes external traffic to model inference endpoints" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Collects metrics via ServiceMonitors" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and SSL passthrough" "External"
        kuadrant = softwareSystem "Kuadrant" "Provides authentication and authorization policies" "External"
        keda = softwareSystem "KEDA" "Autoscales based on custom metrics" "External"
        gatewayAPI = softwareSystem "Gateway API" "Manages HTTPRoutes for LLM services" "External"
        nvidiaGC = softwareSystem "Nvidia NGC" "Validates NIM accounts and provides model catalogs" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core platform API for resource management" "External"

        # Internal ODH Dependencies
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "Platform configuration and component management" "Internal ODH"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides TLS certificates for webhooks" "Internal ODH"

        # User interactions
        user -> odhModelController "Creates InferenceService, ServingRuntime, LLMInferenceService via kubectl/oc"
        admin -> odhModelController "Creates NIM Account CRs to integrate Nvidia NIM models"

        # Controller interactions with external systems
        odhModelController -> kserve "Watches InferenceService, ServingRuntime CRDs"
        odhModelController -> openshiftRouter "Creates Routes for external ingress" "HTTPS/443"
        odhModelController -> prometheusOperator "Creates ServiceMonitors and PodMonitors" "CRD Creation"
        odhModelController -> istio "Creates EnvoyFilters for SSL passthrough" "CRD Creation"
        odhModelController -> kuadrant "Creates AuthPolicies for authentication" "CRD Creation"
        odhModelController -> keda "Creates TriggerAuthentications for autoscaling" "CRD Creation"
        odhModelController -> gatewayAPI "Manages HTTPRoutes for LLM services" "CRD Watch/Create"
        odhModelController -> nvidiaGC "Validates NIM accounts and fetches model catalogs" "HTTPS/443 API Key"
        odhModelController -> k8sAPI "Watches and reconciles CRDs, creates resources" "HTTPS/443 Bearer Token"

        # Controller interactions with internal ODH
        odhModelController -> modelRegistry "Registers deployed models (optional)" "HTTPS/443 Bearer Token"
        odhModelController -> dsc "Reads platform configuration" "CRD Watch"
        odhModelController -> serviceCA "Obtains webhook TLS certificates" "Service Annotation"

        # External systems calling controller
        k8sAPI -> odhModelController "Calls webhook endpoints for validation/mutation" "HTTPS/9443 TLS Client Cert"
        prometheusOperator -> odhModelController "Scrapes /metrics endpoint" "HTTP/8080 Bearer Token"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout
            description "System context diagram for odh-model-controller showing its position in the OpenShift AI ecosystem"
        }

        container odhModelController "Containers" {
            include *
            autoLayout
            description "Container diagram showing the internal structure of odh-model-controller"
        }

        component controller "Components" {
            include *
            autoLayout
            description "Component diagram showing the reconcilers and servers within the controller"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
