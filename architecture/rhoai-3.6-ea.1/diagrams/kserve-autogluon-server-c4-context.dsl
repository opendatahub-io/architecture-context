workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using AutoGluon TabularPredictor and TimeSeriesPredictor"
        platformAdmin = person "Platform Admin" "Manages KServe operator and serving runtimes on OpenShift"

        kserveAutogluon = softwareSystem "KServe AutoGluon Server" "KServe model serving platform with AutoGluon inference runtime for tabular and time-series predictions" {
            controllerManager = container "KServe Controller Manager" "Reconciles InferenceService, InferenceGraph, and TrainedModel resources" "Go controller-runtime Operator"
            llmisvcController = container "LLMInferenceService Controller" "Reconciles LLMInferenceService resources with Gateway API, LeaderWorkerSet, and KEDA integration" "Go controller-runtime Operator"
            localModelController = container "LocalModel Controller" "Manages LocalModelCache and node-level model caching with PersistentVolumes" "Go controller-runtime Operator"
            localModelNodeAgent = container "LocalModelNode Agent" "Manages node-level model downloads via batch Jobs" "Go controller-runtime Operator"
            webhookServer = container "Webhook Server" "Validates and mutates KServe CRDs via Kubernetes admission webhooks" "Go Service, TLS"
            autogluonServer = container "AutoGluon Model Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via V2 inference protocol" "Python FastAPI/uvicorn"
            kserveSDK = container "KServe Python SDK" "Framework for building model servers with V2 inference protocol support (HTTP + gRPC)" "Python Package"
            kubeRBACProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes authorization proxy for metrics endpoint" "Go Sidecar"
            router = container "Inference Router" "Routes requests for InferenceGraph ensemble/splitter/switch patterns" "Go Service"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster resource management, RBAC enforcement, admission control" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for mTLS enforcement, traffic routing via VirtualServices" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for scale-to-zero model deployments" "External"
        gatewayAPI = softwareSystem "Gateway API" "Modern Kubernetes ingress routing via Gateway, GatewayClass, and HTTPRoute resources" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObjects for model serving pods" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        s3 = softwareSystem "S3 Storage" "AWS S3 object storage for model artifacts" "External Cloud"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "GCP object storage for model artifacts" "External Cloud"

        # User interactions
        dataScientist -> kserveAutogluon "Creates InferenceService CRs via kubectl/API" "HTTPS/6443"
        dataScientist -> autogluonServer "Sends inference requests" "HTTPS/443 (V2 Protocol)"
        platformAdmin -> kserveAutogluon "Manages ClusterServingRuntimes and operator configuration" "HTTPS/6443"

        # Internal container relationships
        autogluonServer -> kserveSDK "Uses SDK for model serving framework"
        controllerManager -> webhookServer "Delegates admission control"
        controllerManager -> kubeRBACProxy "Metrics proxied through"

        # External dependencies
        controllerManager -> kubernetesAPI "Watches/creates resources" "HTTPS/6443, SA token"
        controllerManager -> istio "Creates VirtualServices" "Kubernetes API"
        controllerManager -> knative "Creates Knative Services" "Kubernetes API"
        controllerManager -> gatewayAPI "Creates HTTPRoutes (conditional)" "Kubernetes API"
        llmisvcController -> kubernetesAPI "Watches/creates LLM resources" "HTTPS/6443, SA token"
        llmisvcController -> gatewayAPI "Manages Gateway and HTTPRoutes" "Kubernetes API"
        llmisvcController -> keda "Creates ScaledObjects" "Kubernetes API"
        localModelController -> kubernetesAPI "Manages PVs/PVCs for model caching" "HTTPS/6443, SA token"
        localModelNodeAgent -> kubernetesAPI "Creates batch Jobs for model download" "HTTPS/6443, SA token"
        webhookServer -> kubernetesAPI "Receives admission requests" "HTTPS/443, TLS"

        # Model storage
        autogluonServer -> s3 "Downloads model artifacts" "HTTPS/443, IAM"
        autogluonServer -> azureBlob "Downloads model artifacts" "HTTPS/443, Azure AD"
        autogluonServer -> gcs "Downloads model artifacts" "HTTPS/443, GCP SA"
        localModelNodeAgent -> s3 "Pre-caches models to PVs" "HTTPS/443, IAM"

        # Monitoring
        prometheus -> kubeRBACProxy "Scrapes metrics" "HTTPS/8443"
    }

    views {
        systemContext kserveAutogluon "SystemContext" {
            include *
            autoLayout
        }

        container kserveAutogluon "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
