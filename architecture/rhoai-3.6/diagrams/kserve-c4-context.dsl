workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRs"
        platformAdmin = person "Platform Admin" "Manages cluster-wide KServe configuration, serving runtimes, and local model caching"
        externalClient = person "External Client" "Sends inference requests to deployed models"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform managing lifecycle of inference services, LLM deployments, serving runtimes, and local model caching on RHOAI" {
            controllerManager = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel, and ServingRuntime CRDs; runs admission webhooks" "Go Operator (controller-runtime)"
            llmisvcController = container "llmisvc-controller" "Reconciles LLMInferenceService CRDs with Gateway API, LeaderWorkerSet, and KEDA integration" "Go Operator (controller-runtime)"
            moduleController = container "kserve-module-controller" "Meta-operator that installs and manages KServe sub-components: CRDs, webhooks, RBAC, serving runtimes, monitoring" "Go Operator (controller-runtime)"
            localmodelController = container "localmodel-controller" "Reconciles LocalModelCache CRDs, managing PV/PVC provisioning and download Jobs for model pre-caching" "Go Operator (controller-runtime)"
            localmodelNodeAgent = container "localmodelnode-agent" "Per-node agent reconciling LocalModelNode CRDs, executing model download Jobs on individual cluster nodes" "Go Operator (controller-runtime)"
            router = container "router" "Inference graph request router implementing split/switch/ensemble/sequence traffic patterns with TokenReview auth" "Go Service"
            agent = container "agent" "Inference agent managing model downloads and batcher sidecar for model serving pods" "Go Service"
            storageInitializer = container "storage-initializer" "Downloads model artifacts from S3/GCS/Azure/HDFS/OCI/HuggingFace before model server startup" "Python Init Container"
            webhookServer = container "Webhook Server" "Validates and mutates InferenceService, LLMInferenceService, ServingRuntime, InferenceGraph, and other KServe CRDs" "Go HTTPS Server"
            kubeRBACProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes authorization proxy for metrics endpoint" "Sidecar Container"
        }

        kubernetes = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook and workload certs" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for dynamic HTTPRoute-based ingress routing" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject CRs for LLM inference services" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-pod workload orchestration for distributed LLM inference" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor/PodMonitor" "External"
        openShiftConfig = softwareSystem "OpenShift Config API" "Cluster TLS security profile and platform configuration" "External"
        odhOperator = softwareSystem "ODH Operator" "Creates Kserve CR to trigger KServe installation via module controller" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage on Azure" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage on GCP" "External"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Open-source ML model registry and download" "External"
        ociRegistries = softwareSystem "OCI Registries" "Container/artifact registries for OCI model format" "External"
        gatewayInferenceExt = softwareSystem "Gateway API Inference Extension" "InferencePool and InferenceModel for load-balanced model routing" "External"
        openTelemetry = softwareSystem "OpenTelemetry Operator" "Distributed tracing via OpenTelemetryCollector" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService/LLMInferenceService via kubectl" "HTTPS/6443"
        platformAdmin -> kserve "Manages ServingRuntimes, LocalModelCache, and KServe config" "HTTPS/6443"
        externalClient -> kserve "Sends inference requests" "HTTPS/443"

        # KServe internal relationships
        controllerManager -> webhookServer "Runs admission webhooks"
        moduleController -> controllerManager "Installs and manages"
        moduleController -> llmisvcController "Installs and manages"
        moduleController -> localmodelController "Installs and manages"
        localmodelController -> localmodelNodeAgent "Coordinates node-level caching"

        # External dependencies
        kserve -> kubernetes "All controllers: cluster resource CRUD and watch" "HTTPS/6443"
        kserve -> certManager "Certificate and Issuer management for webhook and workload TLS" "HTTPS/6443"
        kserve -> gatewayAPI "Dynamic HTTPRoute ingress routing for inference services" "HTTPS/6443"
        kserve -> keda "ScaledObject creation for event-driven autoscaling" "HTTPS/6443"
        kserve -> leaderWorkerSet "Multi-pod workload management for distributed inference" "HTTPS/6443"
        kserve -> openShiftConfig "TLS security profile resolution from APIServer CR" "HTTPS/6443"
        kserve -> gatewayInferenceExt "InferencePool and InferenceModel for load-balanced routing" "HTTPS/6443"
        kserve -> openTelemetry "OpenTelemetryCollector creation for distributed tracing" "HTTPS/6443"
        prometheus -> kserve "Scrapes metrics via kube-rbac-proxy" "HTTPS/8443"
        odhOperator -> kserve "Creates Kserve CR to trigger installation" "HTTPS/6443"

        # Storage dependencies
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azureBlob "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingFaceHub "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> ociRegistries "Downloads model artifacts" "HTTPS/443"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
