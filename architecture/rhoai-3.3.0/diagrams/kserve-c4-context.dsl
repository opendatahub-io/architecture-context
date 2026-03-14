workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML inference services"
        externalClient = person "External Client" "Consumes inference predictions via HTTP/HTTPS"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for predictive and generative ML models with standardized inference protocols and autoscaling" {
            controller = container "kserve-controller-manager" "Manages InferenceService, ServingRuntime, InferenceGraph, and LLM inference lifecycle" "Go Operator" {
                tags "ODH Component"
            }
            webhook = container "kserve-webhook-server" "Validates and mutates InferenceService, ServingRuntime, TrainedModel, InferenceGraph, and pod resources" "Go Admission Webhook" {
                tags "ODH Component"
            }
            storageInitializer = container "storage-initializer" "Downloads ML models from S3, GCS, Azure Blob, PVC, or OCI registries before serving" "Python Init Container" {
                tags "ODH Component"
            }
            predictorRuntime = container "Predictor Runtime" "Framework-specific serving containers (sklearn, xgboost, pytorch, huggingface, triton)" "Python/C++" {
                tags "ODH Component"
            }
            router = container "Router" "Routes requests through InferenceGraph multi-model pipelines" "Go Service" {
                tags "ODH Component"
            }
            llmScheduler = container "LLM Scheduler" "Schedules and manages LLM inference workloads with disaggregated prefill/decode architecture" "Go Service" {
                tags "ODH Component"
            }
            agent = container "Agent" "Provides logging, request batching, and monitoring for inference pods" "Go Sidecar" {
                tags "ODH Component"
            }
            localModelManager = container "Local Model Manager" "Manages local model caching on cluster nodes for improved performance" "Go Controller" {
                tags "ODH Component"
            }
        }

        # External Dependencies
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling, revision management, and traffic routing" "External" {
            tags "External Dependency"
        }
        istio = softwareSystem "Istio" "Service mesh for traffic management, VirtualServices, DestinationRules, and mTLS" "External" {
            tags "External Dependency"
        }
        certManager = softwareSystem "cert-manager" "Manages TLS certificates for webhook server" "External" {
            tags "External Dependency"
        }
        keda = softwareSystem "KEDA" "Advanced autoscaling for raw deployment mode with custom metrics" "External" {
            tags "External Dependency"
        }
        prometheus = softwareSystem "Prometheus Operator" "ServiceMonitor and PodMonitor resources for metrics scraping" "External" {
            tags "External Dependency"
        }
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics collection and export for autoscaling and observability" "External" {
            tags "External Dependency"
        }
        gatewayAPI = softwareSystem "Gateway API" "Alternative to Istio for ingress/egress traffic management" "External" {
            tags "External Dependency"
        }
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Manages multi-node distributed LLM inference workloads" "External" {
            tags "External Dependency"
        }

        # Internal ODH/RHOAI Dependencies
        serviceMesh = softwareSystem "Service Mesh (OSSM)" "OpenShift Service Mesh for traffic routing, mTLS, canary deployments, and external ingress" "Internal ODH" {
            tags "Internal Dependency"
        }
        openshiftRoutes = softwareSystem "OpenShift Routes" "Exposes inference services externally via OpenShift router" "Internal ODH" {
            tags "Internal Dependency"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "Provides user interface for creating and managing InferenceServices" "Internal ODH" {
            tags "Internal Dependency"
        }
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for controller metrics endpoint" "Internal ODH" {
            tags "Internal Dependency"
        }
        modelRegistry = softwareSystem "Model Registry" "Stores and versions trained models accessed via storage-initializer" "Internal ODH" {
            tags "Internal Dependency"
        }
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Inference services consume models produced by pipeline runs" "Internal ODH" {
            tags "Internal Dependency"
        }
        authorino = softwareSystem "Authorino" "Optional external authorization for inference endpoints" "Internal ODH" {
            tags "Internal Dependency"
        }

        # External Services
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service" {
            tags "External Service"
        }
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage for GCP" "External Service" {
            tags "External Service"
        }
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage for Azure" "External Service" {
            tags "External Service"
        }
        containerRegistries = softwareSystem "Container Registries" "OCI registries for pulling model images (modelcar feature)" "External Service" {
            tags "External Service"
        }

        # User interactions
        dataScientist -> kserve "Creates InferenceService, ServingRuntime, InferenceGraph via kubectl/UI"
        externalClient -> kserve "Sends inference requests (HTTP/HTTPS)" "443/TCP HTTPS"

        # KServe internal
        controller -> webhook "Validates and mutates resources"
        storageInitializer -> predictorRuntime "Provides downloaded models"
        predictorRuntime -> agent "Sends logs and metrics"
        router -> predictorRuntime "Routes multi-model pipeline requests"
        llmScheduler -> predictorRuntime "Schedules LLM inference requests"

        # External dependencies
        kserve -> knative "Uses for serverless autoscaling and revision management" "K8s API / 6443/TCP"
        kserve -> istio "Uses for traffic routing and mTLS" "K8s API / 6443/TCP"
        kserve -> certManager "Requests TLS certificates for webhooks" "K8s API / 6443/TCP"
        kserve -> keda "Uses for custom metric-based autoscaling (optional)" "K8s API / 6443/TCP"
        kserve -> prometheus "Configures metrics scraping (optional)" "K8s API / 6643/TCP"
        kserve -> otelOperator "Deploys metrics collectors (optional)" "K8s API / 6443/TCP"
        kserve -> gatewayAPI "Manages ingress via Gateway API (optional)" "K8s API / 6443/TCP"
        kserve -> leaderWorkerSet "Manages multi-node LLM workloads (optional)" "K8s API / 6443/TCP"

        # Internal ODH dependencies
        kserve -> serviceMesh "Creates VirtualServices, DestinationRules, Gateways" "K8s API / 6443/TCP"
        kserve -> openshiftRoutes "Creates Routes for external access" "K8s API / 6443/TCP"
        odhDashboard -> kserve "Provides UI for InferenceService management" "K8s API / 6443/TCP"
        kserve -> openshiftOAuth "Uses OAuth Proxy for metrics authentication" "8443/TCP HTTPS"
        kserve -> modelRegistry "Fetches model metadata and versions" "gRPC/9090 or Storage Integration"
        dataSciencePipelines -> kserve "Deploys models via InferenceService" "K8s API / 6443/TCP"
        kserve -> authorino "Enforces authorization policies (optional)" "K8s API / 6443/TCP"

        # External service access
        storageInitializer -> s3Storage "Downloads model artifacts" "443/TCP HTTPS"
        storageInitializer -> gcsStorage "Downloads model artifacts" "443/TCP HTTPS"
        storageInitializer -> azureStorage "Downloads model artifacts" "443/TCP HTTPS"
        storageInitializer -> containerRegistries "Pulls OCI model images" "443/TCP HTTPS"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
            description "System context diagram for KServe showing external dependencies, internal ODH integrations, and external services"
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
            description "Container diagram for KServe showing internal components and their relationships"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "ODH Component" {
                background #4a90e2
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal Dependency" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
