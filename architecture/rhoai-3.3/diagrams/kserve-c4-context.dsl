workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"
        admin = person "Platform Administrator" "Manages KServe platform and serving runtimes"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for predictive and generative ML models" {
            controller = container "KServe Controller" "Manages InferenceService lifecycle and reconciliation" "Go Operator" {
                tags "Container"
            }
            webhook = container "Webhook Server" "Validates and mutates KServe custom resources" "Go Service" {
                tags "Container"
            }
            predictor = container "Predictor Runtime" "Framework-specific serving containers (sklearn, pytorch, huggingface, etc.)" "Python/C++" {
                tags "Container"
            }
            router = container "InferenceGraph Router" "Routes requests through multi-model pipelines" "Go Service" {
                tags "Container"
            }
            llmScheduler = container "LLM Scheduler" "Schedules LLM workloads with disaggregated prefill/decode" "Go Service" {
                tags "Container"
            }
            storageInitializer = container "Storage Initializer" "Downloads model artifacts before serving starts" "Python Init Container" {
                tags "Container"
            }
        }

        # External Dependencies
        knative = softwareSystem "Knative Serving" "Serverless autoscaling and revision management platform" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and canary deployments" "External"
        certManager = softwareSystem "cert-manager" "Manages TLS certificates for webhook server" "External"
        keda = softwareSystem "KEDA" "Kubernetes-based event-driven autoscaling" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Manages multi-node distributed workloads" "External"

        # Internal ODH/RHOAI Dependencies
        dashboard = softwareSystem "ODH Dashboard" "User interface for managing InferenceServices" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (OSSM)" "OpenShift Service Mesh for traffic routing and mTLS" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores and versions trained model metadata" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform" "Internal ODH"
        oauth = softwareSystem "OpenShift OAuth" "Authentication for metrics and API endpoints" "Internal ODH"

        # External Services
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Service"

        # Relationships - User interactions
        user -> kserve "Creates and manages InferenceServices via kubectl or Dashboard"
        admin -> kserve "Configures ServingRuntimes and cluster-wide settings"

        # Relationships - KServe to external dependencies
        kserve -> knative "Uses for serverless autoscaling and revision management" "Knative Service CRs"
        kserve -> istio "Uses for traffic routing, VirtualServices, and canary deployments" "VirtualService/DestinationRule CRs"
        kserve -> certManager "Requests TLS certificates for webhook server" "Certificate CRs"
        kserve -> keda "Uses for custom metric-based autoscaling (raw mode)" "ScaledObject CRs"
        kserve -> leaderWorkerSet "Uses for multi-node distributed LLM inference" "LeaderWorkerSet CRs"

        # Relationships - KServe to internal ODH/RHOAI
        dashboard -> kserve "Provides UI for creating and managing InferenceServices" "REST API"
        kserve -> serviceMesh "Configures traffic routing and mTLS policies" "Istio CRs"
        kserve -> modelRegistry "Fetches model metadata and storage locations" "API/Storage integration"
        pipelines -> kserve "Deploys models after pipeline completion" "MLflow/S3 integration"
        kserve -> oauth "Protects controller metrics endpoint" "OAuth Proxy sidecar"

        # Relationships - KServe to external services
        kserve -> s3 "Downloads model artifacts" "HTTPS/443 (AWS IAM or Access Keys)"
        kserve -> gcs "Downloads model artifacts" "HTTPS/443 (GCP Service Account)"
        kserve -> azure "Downloads model artifacts" "HTTPS/443 (Azure credentials)"
        kserve -> prometheus "Exports inference metrics" "ServiceMonitor/PodMonitor"

        # Container-level relationships
        user -> controller "Creates InferenceService CRs"
        controller -> webhook "Validates and mutates resources"
        controller -> predictor "Creates and manages predictor deployments"
        controller -> router "Creates router for InferenceGraph pipelines"
        controller -> llmScheduler "Creates scheduler for LLM workloads"
        storageInitializer -> s3 "Downloads models before serving"
        storageInitializer -> gcs "Downloads models before serving"
        storageInitializer -> azure "Downloads models before serving"
        predictor -> modelRegistry "Accesses model metadata"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout lr
        }

        container kserve "KServeContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
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
