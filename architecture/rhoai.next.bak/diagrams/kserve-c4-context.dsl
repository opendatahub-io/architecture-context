workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates and deploys ML models using InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Manages KServe platform via Kserve CR and ODH operator"
        externalClient = person "External Client" "Sends inference requests to deployed models"

        // KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native platform for serving ML models with serverless and raw deployment modes" {
            kserveController = container "kserve-controller-manager" "Primary controller managing InferenceService, InferenceGraph, TrainedModel CRDs with Knative/raw deployment, ingress, and autoscaling" "Go Operator"
            llmisvcController = container "llmisvc-controller-manager" "LLM-specific controller managing LLMInferenceService CRDs with disaggregated serving, llm-d integration, and Gateway API networking" "Go Operator"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache and LocalModelNamespaceCache CRDs for pre-caching models to node-local PVs" "Go Operator"
            localmodelNodeAgent = container "localmodelnode-agent" "DaemonSet agent managing local model downloads via Jobs and PV/PVC lifecycle" "Go DaemonSet"
            moduleController = container "kserve-module-controller" "ODH platform module controller managing KServe deployment lifecycle via Kserve CR" "Go Operator"
            webhookServer = container "Webhook Server" "Mutates and validates InferenceService, LLMInferenceService, and other CRDs; injects storage-initializer and agent sidecars into pods" "Go HTTP Server" "9443/TCP HTTPS"
            storageInitializer = container "storage-initializer" "Downloads model artifacts from cloud storage (S3, GCS, Azure, HuggingFace, OCI) into model serving pods" "Python 3.11 Init Container"
            inferenceAgent = container "inference-agent" "Sidecar for inference logging, batching, and request/response capture via CloudEvents" "Go Sidecar"
            inferenceRouter = container "inference-router" "Implements InferenceGraph DAG routing with Sequence, Splitter, Ensemble, and Switch patterns" "Go Service" "8080/TCP HTTP"
        }

        // Internal ODH Platform Dependencies
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Platform operator managing KServe via Kserve CR" "Internal ODH"
        odhModelController = softwareSystem "odh-model-controller" "Additional model serving controller co-deployed with KServe" "Internal ODH"
        vllmRuntimes = softwareSystem "vLLM Runtimes" "LLM inference engines (CUDA, ROCm, Gaudi, Spyre) referenced by LLMInferenceServiceConfig" "Internal ODH"
        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Endpoint picker for LLM request scheduling" "Internal ODH"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth proxy sidecar for model serving endpoints" "Internal ODH"

        // External Infrastructure Dependencies
        knative = softwareSystem "Knative Serving" "Serverless platform providing scale-to-zero for InferenceServices" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for ingress routing via VirtualServices" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress for raw and LLM deployment modes" "External"
        keda = softwareSystem "KEDA" "Kubernetes Event-Driven Autoscaler for pod scaling based on metrics" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Manages OpenTelemetryCollector instances for metrics pipeline" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitor/PodMonitor for metrics scraping" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node inference workloads for large LLMs" "External"
        certManager = softwareSystem "cert-manager" "Webhook certificate management (upstream only; OpenShift uses service-ca)" "External"

        // External Services
        s3Storage = softwareSystem "S3 / MinIO" "Object storage for ML model artifacts" "External Service"
        gcsStorage = softwareSystem "Google Cloud Storage" "Object storage for ML model artifacts" "External Service"
        azureStorage = softwareSystem "Azure Blob Storage" "Object storage for ML model artifacts" "External Service"
        huggingFace = softwareSystem "HuggingFace Hub" "Model hub for downloading pre-trained models" "External Service"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for all CRUD operations" "External"

        // Relationships - People to System
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl" "HTTPS/6443"
        platformAdmin -> kserve "Manages KServe lifecycle via Kserve CR" "HTTPS/6443"
        externalClient -> kserve "Sends inference requests to deployed models" "HTTPS/443"

        // Relationships - Internal containers
        kserveController -> webhookServer "Registers mutating/validating webhooks"
        llmisvcController -> webhookServer "Registers LLM-specific webhooks"
        webhookServer -> storageInitializer "Injects into pods via pod mutation"
        webhookServer -> inferenceAgent "Injects into pods when logging/batching enabled"

        // Relationships - KServe to Kubernetes API
        kserveController -> kubernetesAPI "CRUD on Deployments, Services, HTTPRoutes, VirtualServices" "HTTPS/6443"
        llmisvcController -> kubernetesAPI "CRUD on Deployments, LWS, HTTPRoutes, InferencePools, ScaledObjects" "HTTPS/6443"
        localmodelController -> kubernetesAPI "CRUD on PVs, PVCs, download Jobs" "HTTPS/6443"
        moduleController -> kubernetesAPI "Reconcile KServe manifests from templates" "HTTPS/6443"

        // Relationships - KServe to External Infrastructure
        kserveController -> knative "Creates Knative Services for serverless mode" "HTTPS/6443 via API"
        kserveController -> istio "Creates VirtualServices for ingress routing" "HTTPS/6443 via API"
        kserveController -> gatewayAPI "Creates HTTPRoutes for raw deployment ingress" "HTTPS/6443 via API"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes and InferencePools" "HTTPS/6443 via API"
        llmisvcController -> keda "Creates ScaledObjects for LLM autoscaling" "HTTPS/6443 via API"
        llmisvcController -> otelOperator "Creates OpenTelemetryCollectors for metrics" "HTTPS/6443 via API"
        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node inference" "HTTPS/6443 via API"

        // Relationships - KServe to Internal ODH
        odhOperator -> moduleController "Manages via Kserve CR" "CRD"
        kserve -> odhModelController "Co-deployed controller" "CRD"
        kserve -> vllmRuntimes "References runtime images in LLMInferenceServiceConfig" "Container Image"
        kserve -> llmdScheduler "Deploys scheduler alongside LLM workloads" "HTTP/8080"
        kserve -> kubeRBACProxy "Injects auth proxy sidecar" "HTTPS/8443"

        // Relationships - Storage
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443 AWS IAM"
        storageInitializer -> gcsStorage "Downloads model artifacts" "HTTPS/443 GCS SA"
        storageInitializer -> azureStorage "Downloads model artifacts" "HTTPS/443 Azure identity"
        storageInitializer -> huggingFace "Downloads model artifacts" "HTTPS/443 HF Token"
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
                background #438DD5
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
