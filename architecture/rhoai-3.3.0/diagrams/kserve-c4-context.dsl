workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference serving"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and optimizes inference performance"
        endUser = person "End User" "Consumes ML model predictions via API calls"

        # KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for predictive and generative ML models" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, InferenceGraph, and LLM resources" "Go Operator" {
                reconciler = component "Reconciler" "Watches CRs and creates/updates Kubernetes resources"
                resourceManager = component "Resource Manager" "Manages Deployments, Services, VirtualServices"
            }

            webhook = container "Webhook Server" "Validates and mutates InferenceService, ServingRuntime, and related CRs" "Go Admission Webhook" {
                validator = component "Validator" "Validates CR specifications"
                mutator = component "Mutator" "Sets defaults and injects sidecar configurations"
            }

            storageInitializer = container "Storage Initializer" "Downloads ML models from cloud storage before serving containers start" "Python Init Container"

            agent = container "Agent" "Provides logging, request batching, and monitoring for inference pods" "Go Sidecar"

            router = container "Router" "Routes requests through InferenceGraph multi-model pipelines" "Go Service"

            localModelManager = container "Local Model Manager" "Manages local model caching on cluster nodes" "Go Controller"

            localModelAgent = container "Local Model Node Agent" "Node-level agent for local model cache management" "Go DaemonSet"

            llmScheduler = container "LLM Scheduler" "Schedules and manages LLM inference with disaggregated prefill/decode" "Go Service"

            # Serving Runtimes
            sklearnRuntime = container "scikit-learn Server" "Serves scikit-learn models" "Python"
            xgboostRuntime = container "XGBoost Server" "Serves XGBoost models" "Python"
            pytorchRuntime = container "PyTorch Server" "Serves PyTorch models" "Python"
            huggingfaceRuntime = container "Hugging Face Server" "Serves Transformer and LLM models" "Python"
            tritonRuntime = container "NVIDIA Triton Server" "High-performance multi-framework inference server" "C++/Python"
            vllmRuntime = container "vLLM Server" "Optimized LLM inference with PagedAttention" "Python"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes API Server" "Manages cluster state and resources" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides traffic management, mTLS, and observability" "External OSSM"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling and revision management" "External"
        certManager = softwareSystem "cert-manager" "Manages TLS certificates for webhooks" "External"
        keda = softwareSystem "KEDA" "Advanced autoscaling with custom metrics" "External Optional"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics collection and export" "External Optional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics scraping and monitoring" "External Optional"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Manages multi-node distributed LLM workloads" "External Optional"

        # Internal ODH/RHOAI Dependencies
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for creating and managing InferenceServices" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores and versions trained model metadata" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Trains and produces models for inference" "Internal ODH"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for controller metrics endpoint" "Internal OpenShift"
        openshiftRouter = softwareSystem "OpenShift Router" "Exposes inference services externally via Routes" "Internal OpenShift"
        authorino = softwareSystem "Authorino" "External authorization for inference endpoints" "Internal ODH Optional"

        # External Storage Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for ML model artifacts (AWS S3, MinIO, etc.)" "External Storage"
        gcsStorage = softwareSystem "Google Cloud Storage" "Google Cloud object storage for ML model artifacts" "External Storage"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure object storage for ML model artifacts" "External Storage"

        # Eventing
        knativeEventing = softwareSystem "Knative Eventing" "Event-driven logging for inference requests/responses" "External Optional"

        # Relationships - People to Systems
        dataScientist -> kserve "Creates InferenceService CRs via kubectl or Dashboard"
        dataScientist -> odhDashboard "Manages models via UI"
        mlEngineer -> kserve "Configures ServingRuntimes and InferenceGraphs"
        endUser -> kserve "Sends inference requests via HTTPS"

        # Relationships - KServe Internal
        controller -> webhook "Validates resources before reconciliation"
        controller -> kubernetes "Creates/updates Deployments, Services, VirtualServices, etc." "HTTPS/6443"
        webhook -> kubernetes "Registers admission webhooks"

        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azureStorage "Downloads model artifacts" "HTTPS/443"

        router -> sklearnRuntime "Routes pipeline requests" "HTTP/8000"
        router -> pytorchRuntime "Routes pipeline requests" "HTTP/8000"
        router -> huggingfaceRuntime "Routes pipeline requests" "HTTP/8000"

        llmScheduler -> vllmRuntime "Schedules LLM inference to prefill/decode workers" "gRPC/8000-8001"

        agent -> knativeEventing "Sends request/response logs" "HTTP/8080"

        localModelManager -> kubernetes "Creates download Jobs for local cache" "HTTPS/6443"
        localModelAgent -> s3Storage "Downloads models to local disk" "HTTPS/443"

        # Relationships - External Dependencies
        kserve -> istio "Uses for traffic routing, canary deployments, and mTLS" "VirtualServices/DestinationRules"
        kserve -> knative "Uses for serverless autoscaling and revisions" "Knative Service CRs"
        kserve -> certManager "Requests TLS certificates for webhooks" "Certificate CRs"
        kserve -> keda "Uses for custom metric-based autoscaling (raw mode)" "ScaledObject CRs"
        kserve -> otelOperator "Deploys OpenTelemetry collectors for metrics" "OpenTelemetryCollector CRs"
        kserve -> prometheusOperator "Configures Prometheus scraping" "ServiceMonitor/PodMonitor CRs"
        kserve -> leaderWorkerSet "Manages multi-node LLM workloads" "LeaderWorkerSet CRs"

        # Relationships - Internal ODH/RHOAI
        odhDashboard -> kubernetes "Creates InferenceService CRs via API"
        kserve -> openshiftOAuth "Uses OAuth Proxy for metrics authentication"
        kserve -> openshiftRouter "Creates Routes for external access" "Route CRs"
        kserve -> modelRegistry "Fetches model metadata for serving"
        kserve -> authorino "Uses for external authorization policies (optional)"
        dataSciencePipelines -> s3Storage "Stores trained model artifacts"
        kserve -> dataSciencePipelines "Consumes models from pipeline runs" "via S3/MLflow"

        # External User Traffic
        endUser -> istio "Sends inference requests via IngressGateway" "HTTPS/443"
        istio -> sklearnRuntime "Routes to predictor pod" "HTTP/8000"
        istio -> xgboostRuntime "Routes to predictor pod" "HTTP/8000"
        istio -> pytorchRuntime "Routes to predictor pod" "HTTP/8000"
        istio -> huggingfaceRuntime "Routes to predictor pod" "HTTP/8000"
        istio -> tritonRuntime "Routes to predictor pod" "HTTP/8000"
        istio -> vllmRuntime "Routes to LLM predictor" "HTTP/8000"
        istio -> router "Routes to InferenceGraph router" "HTTP/8000"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External OSSM" {
                background #466BB0
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal ODH Optional" {
                background #a8e6a1
                color #333333
            }
            element "Internal OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Go Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Go Admission Webhook" {
                background #357ABD
                color #ffffff
            }
            element "Go Service" {
                background #5A9FD4
                color #ffffff
            }
            element "Go Controller" {
                background #6AAFE6
                color #ffffff
            }
            element "Go DaemonSet" {
                background #7BBFF7
                color #ffffff
            }
            element "Go Sidecar" {
                background #8CCFFF
                color #333333
            }
            element "Python Init Container" {
                background #FFD43B
                color #333333
            }
            element "Python" {
                background #306998
                color #ffffff
            }
            element "C++/Python" {
                background #659AD2
                color #ffffff
            }
        }

        theme default
    }
}
