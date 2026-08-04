workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages serving runtimes and inference configurations"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform components"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing CRD-driven lifecycle management for inference workloads" {
            manager = container "KServe Controller Manager" "Reconciles InferenceService, InferenceGraph, TrainedModel CRDs" "Go Operator (controller-runtime)"
            llmisvcController = container "LLMISvc Controller" "Reconciles LLMInferenceService with Gateway API, InferencePool, KEDA" "Go Operator (controller-runtime)"
            localmodelController = container "LocalModel Controller" "Manages LocalModelCache with PV/PVC for node-local caching" "Go Operator (controller-runtime)"
            localmodelNodeController = container "LocalModelNode Controller" "Manages node-level model download Jobs" "Go Operator (controller-runtime)"
            kserveModule = container "KServe Module Controller" "RHOAI platform module lifecycle via ODH Operator pattern" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates serving CRDs (20 endpoints)" "Kubernetes Admission Webhook"
            router = container "InferenceGraph Router" "Multi-step inference pipeline routing with TokenReview auth" "Go HTTP Server"
            kubeRBACProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes AuthN/AuthZ for metrics" "Sidecar"
            pythonSDK = container "Python SDK" "V2 Prediction Protocol over HTTP (FastAPI) and gRPC" "Python"
            storageHandlers = container "Storage Handlers" "Download model artifacts from S3, GCS, Azure, HDFS" "Python"
        }

        istio = softwareSystem "Istio Service Mesh" "Traffic management, mTLS, VirtualService routing" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling for inference pods" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based routing with InferencePool extension" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObjects" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        odhOperator = softwareSystem "ODH Operator" "RHOAI platform lifecycle operator" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI user interface for model management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage (GCP)" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster resource management" "Infrastructure"

        # User interactions
        dataScientist -> kserve "Creates InferenceService/LLMInferenceService via kubectl or Dashboard"
        dataScientist -> kserve "Sends inference requests via HTTP/gRPC"
        mlEngineer -> kserve "Configures ServingRuntimes and ClusterServingRuntimes"
        platformAdmin -> odhOperator "Manages RHOAI platform lifecycle"
        odhOperator -> kserve "Provisions Kserve CR for platform module"

        # KServe to external dependencies
        kserve -> istio "Uses for traffic routing and mTLS" "Kubernetes API"
        kserve -> knativeServing "Uses for serverless autoscaling" "Kubernetes API"
        kserve -> gatewayAPI "Creates HTTPRoutes and InferencePools" "Kubernetes API"
        kserve -> certManager "Requests TLS certificates" "Certificate CR"
        kserve -> keda "Creates ScaledObjects for autoscaling" "Kubernetes API"
        kserve -> kubeAPI "Manages Deployments, Services, RBAC, etc." "HTTPS/6443"
        kserve -> s3 "Downloads model artifacts" "HTTPS/443"
        kserve -> gcs "Downloads model artifacts" "HTTPS/443"
        kserve -> azureBlob "Downloads model artifacts" "HTTPS/443"

        # Internal RHOAI integrations
        odhDashboard -> kserve "UI management of InferenceServices" "Kubernetes API"
        dsPipelines -> kserve "Automated model deployment" "Kubernetes API"
        kserve -> modelRegistry "Fetches model metadata" "Kubernetes API"

        # Monitoring
        prometheus -> kserve "Scrapes metrics via kube-rbac-proxy" "HTTPS/8443"

        # Internal container relationships
        manager -> webhookServer "Validates/mutates CRDs"
        manager -> kubeAPI "CRUD on Deployments, Services, HTTPRoutes" "HTTPS/6443"
        llmisvcController -> kubeAPI "CRUD on HTTPRoutes, InferencePools, LeaderWorkerSets" "HTTPS/6443"
        localmodelController -> kubeAPI "CRUD on PVs, PVCs" "HTTPS/6443"
        localmodelNodeController -> kubeAPI "Creates model download Jobs" "HTTPS/6443"
        kserveModule -> kubeAPI "Manages CRDs, RBAC, SCC, NetworkPolicies, cert-manager" "HTTPS/6443"
        router -> kubeAPI "TokenReview and SubjectAccessReview" "HTTPS/6443"
        pythonSDK -> storageHandlers "Downloads models at startup"
        storageHandlers -> s3 "S3 protocol" "HTTPS/443"
        storageHandlers -> gcs "GCS protocol" "HTTPS/443"
        storageHandlers -> azureBlob "Azure Blob protocol" "HTTPS/443"
        prometheus -> kubeRBACProxy "Scrapes metrics" "HTTPS/8443"
        kubeRBACProxy -> manager "Proxies to metrics endpoint" "HTTP/8080 localhost"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout
        }

        container kserve "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
