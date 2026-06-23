workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and KServe deployment"
        externalClient = person "External Client" "Sends inference requests to deployed models"

        // KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for deploying, scaling, and managing ML inference services" {
            controllerManager = container "kserve-controller-manager" "Manages InferenceService, TrainedModel, and InferenceGraph CRDs with Knative, raw K8s, and ModelMesh modes" "Go Operator" "Primary"
            llmisvcController = container "llmisvc-controller" "Dedicated controller for LLMInferenceService with LoRA, multi-node, DRA, disaggregated serving" "Go Operator" "Primary"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache and LocalModelNamespaceCache CRDs for pre-caching models" "Go Operator" "Primary"
            localmodelnodeAgent = container "localmodelnode-agent" "Per-node DaemonSet agent for model downloads and filesystem permissions" "Go DaemonSet" "Utility"
            kserveAgent = container "kserve-agent" "Sidecar for model pulling, request logging, batching, and metrics" "Go Sidecar" "Sidecar"
            kserveRouter = container "kserve-router" "HTTP router for InferenceGraph traffic (sequence, splitter, ensemble, switch)" "Go Service" "Primary"
            storageInitializer = container "kserve-storage-initializer" "Init container for downloading models from S3, GCS, Azure, HuggingFace, OCI" "Python Init Container" "Utility"
            moduleController = container "kserve-module-controller" "Component controller for ODH/RHOAI platform operator — deploys KServe via kustomize" "Go Operator" "Platform"
            eppScheduler = container "EPP Scheduler" "Endpoint Picker Protocol scheduler for LLM request routing" "Go/gRPC" "Primary"
        }

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform runtime" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for VirtualService routing, DestinationRules, mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for scale-to-zero deployments" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for non-OpenShift deployments" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress routing" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for inference workloads" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node LLM inference workload orchestration" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Distributed tracing and metrics collection" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics scraping via PodMonitor/ServiceMonitor" "External"

        // Internal ODH/RHOAI Platform
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator — creates Kserve CR" "Internal ODH"
        odhModelController = softwareSystem "odh-model-controller" "Additional model serving reconciliation for ODH" "Internal ODH"
        wva = softwareSystem "Workload Variant Autoscaler" "LLM workload variant-aware autoscaling" "Internal ODH"
        vllm = softwareSystem "vLLM" "Default LLM serving runtime" "Internal ODH"
        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Endpoint Picker Protocol scheduler container" "Internal ODH"

        // External Services
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage on GCP" "External Service"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage on Azure" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External Service"
        ociRegistry = softwareSystem "OCI Container Registry" "OCI model image storage" "External Service"

        // Relationships - People
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        platformAdmin -> rhodsOperator "Configures RHOAI platform"
        externalClient -> kserve "Sends inference requests via HTTPS/gRPC"

        // Relationships - KServe internal
        controllerManager -> kserveAgent "Injects as sidecar via pod webhook"
        controllerManager -> storageInitializer "Injects as init container via pod webhook"
        controllerManager -> kserveRouter "Creates per InferenceGraph"
        llmisvcController -> eppScheduler "Creates per LLMInferenceService"

        // Relationships - External Dependencies
        controllerManager -> kubernetes "CRD CRUD, resource management" "HTTPS/443"
        controllerManager -> istio "VirtualService routing, mTLS" "HTTPS/443"
        controllerManager -> knative "Knative Service lifecycle" "HTTPS/443"
        controllerManager -> gatewayAPI "HTTPRoute management" "HTTPS/443"
        controllerManager -> keda "ScaledObject management" "HTTPS/443"
        controllerManager -> otelOperator "OpenTelemetryCollector management" "HTTPS/443"
        controllerManager -> prometheusOperator "PodMonitor/ServiceMonitor management" "HTTPS/443"
        llmisvcController -> kubernetes "CRD CRUD, resource management" "HTTPS/443"
        llmisvcController -> gatewayAPI "HTTPRoute, Gateway management" "HTTPS/443"
        llmisvcController -> istio "DestinationRule management (ODH)" "HTTPS/443"
        llmisvcController -> leaderWorkerSet "Multi-node inference" "HTTPS/443"
        llmisvcController -> keda "ScaledObject management" "HTTPS/443"
        localmodelController -> kubernetes "PV/PVC management" "HTTPS/443"
        localmodelnodeAgent -> kubernetes "Job management" "HTTPS/443"
        moduleController -> kubernetes "Kustomize manifest deployment" "HTTPS/443"

        // Relationships - Internal Platform
        rhodsOperator -> kserve "Creates Kserve CR"
        moduleController -> odhModelController "Deploys via kustomize"
        moduleController -> wva "Deploys via kustomize"
        llmisvcController -> vllm "Manages vLLM workload pods"
        eppScheduler -> llmdScheduler "Uses EPP container image"

        // Relationships - External Services (Egress)
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azureBlob "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingface "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> ociRegistry "Pulls model images" "HTTPS/443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #9b59b6
                color #ffffff
            }
            element "Utility" {
                background #50c878
                color #ffffff
            }
            element "Platform" {
                background #e67e22
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
