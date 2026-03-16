workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        cicdPipeline = person "CI/CD Pipeline" "Automates model deployment to production"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift-specific integrations for production model serving" {
            controllerManager = container "Controller Manager" "Reconciles InferenceService resources and orchestrates deployment modes" "Go 1.21 Operator" {
                osisReconciler = component "OpenshiftInferenceServiceReconciler" "Orchestrates ModelMesh, KServe Serverless, and KServe Raw deployment modes" "Controller"
                storageReconciler = component "StorageSecretReconciler" "Manages storage credentials for S3, PVC access" "Controller"
                caReconciler = component "KServeCustomCACertReconciler" "Manages custom CA certificate bundles" "Controller"
                monitoringReconciler = component "MonitoringReconciler" "Creates ServiceMonitor and PodMonitor resources" "Controller"
                modelRegistryReconciler = component "ModelRegistryInferenceServiceReconciler" "Integrates with Model Registry for lineage tracking" "Controller"
            }
            webhookServer = container "Webhook Server" "Validates Knative Service configurations for service mesh compatibility" "Go Service" {
                validator = component "Knative Service Validator" "Ensures proper service mesh configuration" "Webhook"
            }
            runtimeTemplates = container "Serving Runtime Templates" "Pre-configured runtime definitions for inference engines" "ConfigMaps" {
                vllmTemplate = component "vLLM Runtime Template" "OpenAI-compatible LLM inference" "ConfigMap"
                tgisTemplate = component "TGIS Runtime Template" "IBM Text Generation Inference" "ConfigMap"
                caikitTemplate = component "Caikit Runtime Template" "Caikit framework model serving" "ConfigMap"
                ovmsTemplate = component "OVMS Runtime Template" "OpenVINO Model Server" "ConfigMap"
            }
        }

        kserve = softwareSystem "KServe" "Core InferenceService and ServingRuntime CRD management" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe Serverless mode" "External - Conditional"
        istioMesh = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and observability" "External - Conditional"
        authorino = softwareSystem "Authorino" "Authentication and authorization for inference endpoints" "External - Conditional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Enables ServiceMonitor/PodMonitor for metrics collection" "External - Optional"
        openshiftRouter = softwareSystem "OpenShift Route API" "External access to inference services on OpenShift" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for TLS certificates" "External - Conditional"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing model serving deployments" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and lineage" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Manages DataScienceCluster and platform configuration" "Internal ODH"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "Infrastructure"
        s3Storage = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"

        # Relationships - Users to ODH Model Controller
        dataScientist -> odhModelController "Creates InferenceService via kubectl/ODH Dashboard"
        cicdPipeline -> odhModelController "Deploys InferenceServices automatically"

        # Relationships - ODH Model Controller internals
        controllerManager -> webhookServer "Activates webhook when service mesh enabled"
        osisReconciler -> storageReconciler "Triggers storage secret reconciliation"
        osisReconciler -> caReconciler "Triggers CA certificate reconciliation"
        osisReconciler -> monitoringReconciler "Triggers monitoring resource creation"
        osisReconciler -> modelRegistryReconciler "Triggers model registry integration"
        osisReconciler -> runtimeTemplates "Deploys serving runtime templates"

        # Relationships - ODH Model Controller to External Dependencies
        odhModelController -> kserve "Co-manages InferenceService resources" "K8s API Watch/CRUD"
        odhModelController -> knativeServing "Creates Knative Services for Serverless mode" "K8s API CRUD"
        odhModelController -> istioMesh "Creates VirtualServices, PeerAuthentications, Telemetries" "K8s API CRUD"
        odhModelController -> authorino "Creates AuthConfig resources for endpoint authentication" "K8s API CRUD"
        odhModelController -> prometheusOperator "Creates ServiceMonitors and PodMonitors" "K8s API CRUD"
        odhModelController -> openshiftRouter "Creates OpenShift Routes for external access" "K8s API CRUD"
        odhModelController -> certManager "Uses for certificate management (optional)" "K8s API Watch"

        # Relationships - ODH Model Controller to Internal ODH Components
        odhModelController -> odhDashboard "Provides runtime templates labeled for dashboard discovery" "ConfigMap Labels"
        odhModelController -> modelRegistry "Associates InferenceServices with registered models" "gRPC API (optional)"
        odhModelController -> odhOperator "Reads DataScienceCluster and DSCInitialization config" "K8s API Watch"
        dataSciencePipelines -> odhModelController "Auto-deploys models from pipeline outputs" "K8s API CRUD"

        # Relationships - ODH Model Controller to Infrastructure
        odhModelController -> k8sAPI "CRUD operations on all managed resources" "HTTPS/6443 TLS1.2+"
        k8sAPI -> odhModelController "Webhook validation requests for Knative Services" "HTTPS/9443 mTLS"
        prometheusOperator -> odhModelController "Scrapes controller metrics" "HTTP/8080 Bearer Token"

        # Relationships - Inference Services to External Services
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443 AWS IAM"

        # Relationships - Users to other systems
        dataScientist -> odhDashboard "Manages InferenceServices via Web UI"
        dataScientist -> k8sAPI "Creates InferenceServices via kubectl"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram showing ODH Model Controller and its integrations"
        }

        container odhModelController "Containers" {
            include *
            autoLayout tb
            description "Container diagram showing internal components of ODH Model Controller"
        }

        component controllerManager "ControllerComponents" {
            include *
            autoLayout tb
            description "Component diagram showing reconcilers within the Controller Manager"
        }

        component webhookServer "WebhookComponents" {
            include *
            autoLayout tb
            description "Component diagram showing webhook validation components"
        }

        component runtimeTemplates "RuntimeTemplates" {
            include *
            autoLayout lr
            description "Component diagram showing serving runtime templates"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - Conditional" {
                background #bbbbbb
                color #000000
            }
            element "External - Optional" {
                background #cccccc
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Infrastructure" {
                background #1168bd
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5dade2
                color #000000
            }
            element "Component" {
                background #85c1e9
                color #000000
            }
        }
    }
}
