workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML/LLM models for inference"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and KServe configuration"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for ML/LLM inference with multi-protocol support (REST V1/V2, gRPC, OpenAI-compatible)" {
            kserveController = container "kserve-controller" "Reconciles InferenceService, TrainedModel, InferenceGraph CRDs into Deployments, Services, Ingress, autoscalers" "Go Operator (controller-runtime)"
            llmisvcController = container "llmisvc-controller" "Reconciles LLMInferenceService CRD with Gateway API HTTPRoutes, InferencePool, scheduler, VariantAutoscaling" "Go Operator (controller-runtime)"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache CRDs, PV/PVC creation for model distribution across node groups" "Go Operator (controller-runtime)"
            localmodelAgent = container "localmodelnode-agent" "DaemonSet agent managing model download Jobs and local filesystem storage on worker nodes" "Go DaemonSet"
            kserveAgent = container "kserve-agent" "Sidecar proxy with model puller, request/response logger, and request batcher" "Go Sidecar"
            kserveRouter = container "kserve-router" "Routes inference requests through InferenceGraph nodes (Splitter, Switch, Ensemble, Sequence)" "Go Service"
            storageInitializer = container "storage-initializer" "Downloads model artifacts from S3, GCS, Azure, HuggingFace Hub, HDFS, HTTP(S)" "Python Init Container"
            modelServer = container "Model Server (SDK)" "V1/V2/OpenAI REST and gRPC V2 inference framework with Prometheus metrics" "Python (FastAPI/uvicorn)"
        }

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for InferenceService deployment" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, VirtualServices, DestinationRules, mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress for InferenceService and LLMInferenceService" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObjects" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node LLM workload orchestration" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for metrics collection" "External"
        otelOp = softwareSystem "OpenTelemetry Operator" "Sidecar OTel collector for pod metrics" "External"
        llmdWVA = softwareSystem "llm-d WVA" "Cost-aware variant autoscaling for LLM workloads" "External"

        // Internal Platform Dependencies
        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys KServe via kustomize manifests" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Route API" "Routes for InferenceGraph external access" "Internal RHOAI"
        openshiftSCC = softwareSystem "OpenShift SCC" "SecurityContextConstraints for privileged workloads" "Internal RHOAI"

        // External Services (Egress)
        s3 = softwareSystem "S3 Storage" "S3-compatible object storage for model artifacts" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "GCS for model artifacts" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Azure storage for model artifacts" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository and download service" "External Service"

        // Relationships - User
        datascientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        platformadmin -> kserve "Configures ServingRuntimes, LLMInferenceServiceConfig"

        // Relationships - Container level
        kserveController -> kubernetes "CRUD on Deployments, Services, Ingress, HTTPRoutes" "HTTPS/443"
        kserveController -> knative "Creates Knative Services for serverless mode" "HTTPS/443"
        kserveController -> istio "Creates VirtualServices for traffic mgmt" "HTTPS/443"
        kserveController -> keda "Creates ScaledObjects for autoscaling" "HTTPS/443"
        kserveController -> otelOp "Creates OTel sidecar collectors" "HTTPS/443"

        llmisvcController -> kubernetes "CRUD on Deployments, Services, HTTPRoutes, InferencePools" "HTTPS/443"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes, discovers Gateways" "HTTPS/443"
        llmisvcController -> istio "Creates DestinationRules for mTLS (OCP)" "HTTPS/443"
        llmisvcController -> keda "Creates ScaledObjects for KEDA scaling" "HTTPS/443"
        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node" "HTTPS/443"
        llmisvcController -> prometheusOp "Creates PodMonitors and ServiceMonitors" "HTTPS/443"
        llmisvcController -> llmdWVA "Creates VariantAutoscalings" "HTTPS/443"

        localmodelController -> kubernetes "Creates PersistentVolumes and PVCs" "HTTPS/443"
        localmodelAgent -> kubernetes "Creates download Jobs" "HTTPS/443"

        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingface "Downloads models from HF Hub" "HTTPS/443"

        kserveRouter -> modelServer "Routes inference requests (InferenceGraph)" "HTTP/80"

        // Platform relationships
        rhodsOperator -> kserve "Deploys via kustomize at pinned commit"
        kserveController -> openshiftRoutes "Creates Routes for InferenceGraph" "HTTPS/443"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
