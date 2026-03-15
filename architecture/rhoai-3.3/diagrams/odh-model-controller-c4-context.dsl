workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages ML model inference services on OpenShift AI"
        admin = person "Platform Administrator" "Configures NVIDIA NIM accounts and manages serving infrastructure"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe with OpenShift-specific integrations for model serving workloads" {
            controller = container "Controller Manager" "Reconciles KServe resources and creates OpenShift-specific resources" "Go Operator" {
                isController = component "InferenceService Controller" "Creates Routes, NetworkPolicies, ServiceMonitors, RBAC for InferenceServices" "Go Reconciler"
                igController = component "InferenceGraph Controller" "Manages multi-model inference pipelines" "Go Reconciler"
                srController = component "ServingRuntime Controller" "Manages serving runtime templates" "Go Reconciler"
                llmController = component "LLM InferenceService Controller" "Handles LLM-specific inference services" "Go Reconciler"
                nimController = component "NIM Account Controller" "Validates NGC API keys and creates NIM templates" "Go Reconciler"
            }
            webhook = container "Webhook Server" "Validates and mutates KServe resources and pods" "Go Admission Controller" {
                tags "WebServer"
            }
            metrics = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server" {
                tags "WebServer"
            }
        }

        kserve = softwareSystem "KServe" "Core model serving platform" "External" {
            tags "External"
        }

        openshift = softwareSystem "OpenShift" "Container platform with Routes and Templates" "External" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External" {
            tags "External"
        }

        keda = softwareSystem "KEDA" "Event-driven autoscaling for inference workloads" "External" {
            tags "External"
        }

        istio = softwareSystem "Istio" "Service mesh for traffic management" "External" {
            tags "External"
        }

        kuadrant = softwareSystem "Kuadrant" "API authentication and authorization" "External" {
            tags "External"
        }

        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH" {
            tags "Internal ODH"
        }

        ngcAPI = softwareSystem "NVIDIA NGC API" "Validates NIM accounts and provides model configurations" "External API" {
            tags "External API"
        }

        s3Storage = softwareSystem "S3 Storage" "Model artifact storage" "External Storage" {
            tags "External Storage"
        }

        // User interactions
        user -> odhModelController "Creates InferenceService CRs via kubectl/OpenShift Console"
        admin -> odhModelController "Creates NIM Account CRs for NVIDIA inference"

        // Core dependency
        odhModelController -> kserve "Watches and extends InferenceService, InferenceGraph, ServingRuntime CRDs" "HTTPS/443 (K8s API)"

        // OpenShift integrations
        odhModelController -> openshift "Creates Routes for external access" "HTTPS/443 (K8s API)"
        odhModelController -> openshift "Creates Templates for NIM serving runtimes" "HTTPS/443 (K8s API)"

        // Monitoring and autoscaling
        odhModelController -> prometheus "Creates ServiceMonitors and PodMonitors" "HTTPS/443 (K8s API)"
        prometheus -> odhModelController "Scrapes /metrics endpoint" "HTTP/8080"

        odhModelController -> keda "Creates TriggerAuthentications for autoscaling" "HTTPS/443 (K8s API)"

        // Service mesh and API gateway
        odhModelController -> istio "Creates EnvoyFilters for traffic policies" "HTTPS/443 (K8s API)"
        odhModelController -> kuadrant "Creates AuthPolicies for API authentication" "HTTPS/443 (K8s API)"

        // Optional integrations
        odhModelController -> modelRegistry "Fetches model metadata and versioning" "HTTPS/443" {
            tags "Optional"
        }

        // External services
        odhModelController -> ngcAPI "Validates NIM accounts and NGC API keys" "HTTPS/443"

        // Inference workloads (managed by controller)
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443"
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

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
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
            element "External API" {
                background #f5a623
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
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
            element "WebServer" {
                shape WebBrowser
            }
            relationship "Optional" {
                dashed true
            }
        }
    }
}
