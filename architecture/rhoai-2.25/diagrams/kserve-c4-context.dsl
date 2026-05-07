workspace {
    model {
        // Users
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and LLM deployments"
        externalClient = person "External Client" "Sends inference requests to deployed models"

        // KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native platform for deploying, managing, and serving ML models with serverless inference, LLM serving, and local model caching" {
            controllerManager = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel, and LLMInferenceService CRDs; runs admission webhooks" "Go Operator" "Primary"
            agent = container "kserve-agent" "Pod sidecar handling request proxying, model pulling, logging, batching, and metrics" "Go Sidecar"
            router = container "kserve-router" "InferenceGraph routing sidecar traversing DAG nodes for multi-model inference" "Go Sidecar"
            storageInitializer = container "kserve-storage-initializer" "Downloads model artifacts from cloud storage into pods before serving" "Python Init Container"
            localModelController = container "kserve-localmodel-controller" "Manages LocalModelCache resources, creating PVs/PVCs for model distribution" "Go Controller"
            localModelNodeAgent = container "kserve-localmodelnode-agent" "DaemonSet agent managing local model downloads via batch Jobs" "Go DaemonSet"
        }

        // Platform Dependencies (Internal)
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys KServe via kustomize overlays" "Internal RHOAI"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for InferenceService pods" "External"
        istio = softwareSystem "Istio Service Mesh" "Traffic management via VirtualServices and DestinationRules" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic routing with OpenShift Gateway" "External"
        gatewayInferenceExt = softwareSystem "Gateway API Inference Extension" "InferencePool/InferenceModel for LLM request-aware scheduling" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node distributed inference orchestration" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling beyond HPA" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "ServiceMonitor/PodMonitor for metrics collection" "External"
        otelOp = softwareSystem "OpenTelemetry Operator" "Distributed tracing via OpenTelemetryCollector" "External"
        openshiftIngress = softwareSystem "OpenShift Ingress" "openshift-ai-inference Gateway for external traffic" "Internal RHOAI"

        // External Services
        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage on GCP" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage on Azure" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External Service"
        kubernetes = softwareSystem "Kubernetes API Server" "Cluster API for CRD operations and resource management" "External"

        // Relationships - Users
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl" "HTTPS/6443"
        mlEngineer -> kserve "Manages ServingRuntimes, LocalModelCache" "HTTPS/6443"
        externalClient -> kserve "Sends inference requests" "HTTPS/443"

        // Relationships - KServe to Platform
        kserve -> kubernetes "CRD watches, resource CRUD, leader election" "HTTPS/6443"
        kserve -> knative "Creates Knative Services for serverless inference" "CRD via K8s API"
        kserve -> istio "Creates VirtualServices for traffic routing and canary" "CRD via K8s API"
        kserve -> gatewayAPI "Creates HTTPRoutes for external traffic" "CRD via K8s API"
        kserve -> gatewayInferenceExt "Creates InferencePools for LLM load balancing" "CRD via K8s API"
        kserve -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node LLM" "CRD via K8s API"
        kserve -> keda "Creates ScaledObjects for event-driven autoscaling" "CRD via K8s API"
        kserve -> prometheusOp "Creates ServiceMonitors/PodMonitors" "CRD via K8s API"
        kserve -> otelOp "Creates OpenTelemetryCollectors" "CRD via K8s API"

        // Relationships - KServe to External Services
        kserve -> s3 "Downloads model artifacts" "HTTPS/443"
        kserve -> gcs "Downloads model artifacts" "HTTPS/443"
        kserve -> azure "Downloads model artifacts" "HTTPS/443"
        kserve -> huggingface "Downloads pre-trained models" "HTTPS/443"

        // Relationships - Platform to KServe
        rhoaiOperator -> kserve "Deploys and configures via kustomize overlays"
        openshiftIngress -> kserve "Routes external traffic to inference endpoints" "HTTPS/443"

        // Container-level relationships
        controllerManager -> kubernetes "Watches CRDs, creates resources" "HTTPS/6443"
        controllerManager -> knative "Creates Knative Services" "CRD"
        controllerManager -> istio "Creates VirtualServices, DestinationRules" "CRD"
        controllerManager -> gatewayAPI "Creates HTTPRoutes" "CRD"
        controllerManager -> gatewayInferenceExt "Creates InferencePools, InferenceModels" "CRD"
        controllerManager -> leaderWorkerSet "Creates LeaderWorkerSets" "CRD"
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingface "Downloads models" "HTTPS/443"
        localModelController -> kubernetes "Creates PVs/PVCs" "HTTPS/6443"
        localModelNodeAgent -> kubernetes "Creates download Jobs" "HTTPS/6443"
        router -> controllerManager "Auth: TokenReview, SubjectAccessReview" "HTTPS/6443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Primary" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
