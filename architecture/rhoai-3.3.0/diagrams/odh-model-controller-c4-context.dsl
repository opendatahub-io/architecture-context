workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages ML model inference workloads on OpenShift AI"
        admin = person "Platform Administrator" "Manages NVIDIA NIM accounts and serving runtime configurations"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe with OpenShift-specific integrations for model serving (Routes, NetworkPolicies, RBAC, metrics, NIM support)" {
            controllerManager = container "Controller Manager" "Reconciles KServe resources and manages OpenShift integrations" "Go Operator" {
                isController = component "InferenceService Controller" "Creates Routes, NetworkPolicies, RBAC, ServiceMonitors for InferenceServices" "Go Reconciler"
                igController = component "InferenceGraph Controller" "Manages multi-model inference pipeline resources" "Go Reconciler"
                srController = component "ServingRuntime Controller" "Manages serving runtime templates (vLLM, OVMS, MLServer, Caikit, TGIS)" "Go Reconciler"
                llmController = component "LLM InferenceService Controller" "Specialized controller for Large Language Model deployments" "Go Reconciler"
                nimController = component "NIM Account Controller" "Validates NGC API keys and creates NIM serving runtime templates" "Go Reconciler"
                cmController = component "ConfigMap Controller" "Watches ConfigMaps referenced by managed resources" "Go Reconciler"
                secretController = component "Secret Controller" "Watches Secrets referenced by managed resources" "Go Reconciler"
                podController = component "Pod Controller" "Mutates pods for inference workloads" "Go Reconciler"
            }
            webhookServer = container "Webhook Server" "Validates and mutates KServe resources, NIM Accounts, and Pods" "Go Admission Controller" {
                validatingWebhook = component "Validating Webhook" "Validates InferenceService, InferenceGraph, NIM Account, ConfigMap resources" "Webhook Handler"
                mutatingWebhook = component "Mutating Webhook" "Mutates InferenceService, InferenceGraph, and Pod resources" "Webhook Handler"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics (8080/TCP HTTP, TODO: migrate to HTTPS/8443)" "HTTP Server"
            healthServer = container "Health Server" "Provides liveness and readiness probes (8081/TCP)" "HTTP Server"
        }

        kserve = softwareSystem "KServe" "Core model serving platform - manages InferenceService lifecycle and predictor deployments" "External"
        kubernetes = softwareSystem "Kubernetes API Server" "Orchestrates containers and manages cluster state" "External"
        openshift = softwareSystem "OpenShift Platform" "Provides Routes, Templates, and service-ca for certificate management" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides traffic management, mTLS, and observability for inference workloads" "External"
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling for model inference workloads" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Collects and stores metrics from inference workloads via ServiceMonitors" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for inference workloads based on custom metrics" "External"
        kuadrant = softwareSystem "Kuadrant" "API authentication and authorization policies for inference endpoints" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management (optional - OpenShift uses service-ca)" "External"

        odhOperator = softwareSystem "opendatahub-operator" "Manages DataScienceCluster and DSCInitialization resources" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versioning, and lineage information" "Internal ODH"

        ngcAPI = softwareSystem "NVIDIA NGC API" "Validates NGC API keys and provides NIM model configurations" "External Service"
        s3Storage = softwareSystem "S3 Storage" "Stores ML model artifacts for inference workloads" "External Service"

        # Relationships - User interactions
        user -> odhModelController "Creates InferenceService, InferenceGraph, ServingRuntime resources via kubectl/oc"
        admin -> odhModelController "Creates NIM Account resources with NGC API credentials via kubectl/oc"

        # Core integrations
        odhModelController -> kserve "Watches and extends KServe CRDs (InferenceService, InferenceGraph, ServingRuntime)" "HTTPS/443 via K8s API"
        odhModelController -> kubernetes "Creates and manages OpenShift/K8s resources (Routes, NetworkPolicies, RBAC, ServiceMonitors)" "HTTPS/443 TLS1.2+"
        odhModelController -> openshift "Creates OpenShift Routes for external access, uses Templates for NIM runtimes" "HTTPS/443 via K8s API"
        odhModelController -> istio "Creates EnvoyFilters for service mesh configuration" "HTTPS/443 via K8s API"
        odhModelController -> prometheusOp "Creates ServiceMonitors and PodMonitors for metrics collection" "HTTPS/443 via K8s API"
        odhModelController -> keda "Creates TriggerAuthentication resources for autoscaling" "HTTPS/443 via K8s API"
        odhModelController -> kuadrant "Creates AuthPolicy resources for API authentication/authorization" "HTTPS/443 via K8s API"

        # Internal ODH dependencies
        odhModelController -> odhOperator "Reads DataScienceCluster and DSCInitialization for platform configuration" "HTTPS/443 via K8s API"
        odhModelController -> modelRegistry "Optional integration for model metadata and lineage" "HTTPS/443"

        # External service integrations
        odhModelController -> ngcAPI "Validates NGC API keys and retrieves NIM model configurations" "HTTPS/443 TLS1.2+ (NGC API Key auth)"

        # Monitoring
        prometheusOp -> odhModelController "Scrapes /metrics endpoint for controller metrics" "HTTP/8080 (Bearer Token)"

        # KServe dependencies (context)
        kserve -> istio "Uses for traffic routing and mTLS"
        kserve -> knative "Uses for serverless autoscaling"
        kserve -> s3Storage "Downloads model artifacts for inference"

        # Deployment context
        deploymentGroup = deploymentGroup "Production" {
            deploymentNode "OpenShift Cluster" {
                deploymentNode "redhat-ods-applications namespace" {
                    deploymentNode "odh-model-controller Pod" {
                        containerInstance controllerManager
                        containerInstance webhookServer
                        containerInstance metricsServer
                        containerInstance healthServer
                    }
                }
                deploymentNode "User Namespace" {
                    deploymentNode "Managed Resources" {
                        infrastructureNode "OpenShift Route" {
                            description "External HTTPS access to inference endpoints"
                        }
                        infrastructureNode "NetworkPolicy" {
                            description "Ingress/egress traffic control for inference pods"
                        }
                        infrastructureNode "ServiceMonitor" {
                            description "Prometheus metrics scraping configuration"
                        }
                        infrastructureNode "TriggerAuthentication" {
                            description "KEDA autoscaling authentication"
                        }
                    }
                }
            }
        }
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autolayout lr
            description "System context diagram for odh-model-controller showing its role in the OpenShift AI / KServe ecosystem"
        }

        container odhModelController "Containers" {
            include *
            autolayout lr
            description "Container diagram showing internal components of odh-model-controller"
        }

        component controllerManager "ControllerComponents" {
            include *
            autolayout lr
            description "Component diagram showing reconcilers within the Controller Manager"
        }

        component webhookServer "WebhookComponents" {
            include *
            autolayout lr
            description "Component diagram showing webhook handlers"
        }

        deployment odhModelController "Production" "Deployment" {
            include *
            autolayout lr
            description "Deployment diagram showing odh-model-controller running on OpenShift"
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
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                shape Component
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
