workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML/AI models for inference"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing CRD-driven lifecycle management for ML inference services, LLM workloads, and local model caching" {
            kserveController = container "kserve-controller" "Main controller managing InferenceService, InferenceGraph, and TrainedModel CRDs with Knative, Istio, Gateway API, and KEDA support" "Go Operator"
            llmisvcController = container "llmisvc-controller" "Dedicated controller for LLMInferenceService CRD with multi-node, disaggregated P/D, Gateway API, InferencePool, and WVA scaling" "Go Operator"
            localmodelController = container "localmodel-controller" "Controller managing LocalModelCache/LocalModelNamespaceCache CRDs, creating PVs/PVCs and LocalModelNode entries" "Go Operator"
            localmodelnodeAgent = container "localmodelnode-agent" "Per-node DaemonSet agent managing local model storage, launching download Jobs" "Go Agent"
            kserveAgent = container "kserve-agent" "Injected sidecar for model pulling (multi-model), request logging, and batching" "Go Sidecar"
            kserveRouter = container "kserve-router" "HTTP router for InferenceGraph DAG-based inference pipelines" "Go Service"
            storageInitializer = container "storage-initializer" "Init container downloading model artifacts from cloud storage" "Python Init Container"
            webhookServer = container "Webhook Server" "Validates and mutates InferenceService, ServingRuntime CRDs and injects sidecars" "Go Webhook (port 9443)"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform (scale-to-zero)" "External"
        istio = softwareSystem "Istio / OSSM" "Service mesh for traffic routing, mTLS, VirtualServices, DestinationRules" "External"
        gatewayAPI = softwareSystem "Gateway API" "Modern Kubernetes ingress with HTTPRoute" "External"
        keda = softwareSystem "KEDA" "External metrics-based autoscaling" "External"
        certManager = softwareSystem "cert-manager / service-ca" "TLS certificate management" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for metrics scraping" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node LLM workload orchestration" "External"
        otel = softwareSystem "OpenTelemetry Operator" "Metrics collection and export" "External"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / ODH Operator" "Deploys KServe via kustomize overlays" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for inference endpoints" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth proxy sidecar for RBAC enforcement" "Internal RHOAI"
        llmdScheduler = softwareSystem "LLM-D Inference Scheduler" "Request scheduling/load balancing for LLM InferencePools" "Internal RHOAI"
        llmdWVA = softwareSystem "LLM-D WVA" "Workload Variant Autoscaling for LLM inference" "Internal RHOAI"
        vllm = softwareSystem "vLLM Runtime" "LLM inference runtime (CUDA/ROCm/Gaudi/Spyre)" "Internal RHOAI"

        # External Services (Egress)
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact downloads" "External Service"
        ociRegistries = softwareSystem "OCI Registries" "OCI artifact downloads" "External Service"

        # Relationships - User
        user -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"

        # Relationships - KServe internal
        kserveController -> webhookServer "Serves validation/mutation webhooks"
        kserveController -> kserveAgent "Injects via mutating webhook"
        kserveController -> storageInitializer "Injects via mutating webhook"
        kserveController -> kserveRouter "Deploys per InferenceGraph"

        # Relationships - KServe → External Dependencies
        kserve -> kubernetes "CRUD for Deployments, Services, HPAs, etc." "HTTPS/6443"
        kserve -> knative "Creates Knative Services for serverless mode" "HTTPS/6443"
        kserve -> istio "Creates VirtualServices/DestinationRules for routing and mTLS" "HTTPS/6443"
        kserve -> gatewayAPI "Creates HTTPRoutes for modern ingress" "HTTPS/6443"
        kserve -> keda "Creates ScaledObjects for external metrics autoscaling" "HTTPS/6443"
        kserve -> certManager "Webhook TLS certificate management" "HTTPS/6443"
        kserve -> prometheusOp "Creates PodMonitors/ServiceMonitors for LLM metrics" "HTTPS/6443"
        kserve -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node LLM" "HTTPS/6443"
        kserve -> otel "Creates OpenTelemetryCollectors for metrics" "HTTPS/6443"

        # Relationships - KServe → Internal Platform
        rhodsOperator -> kserve "Deploys via kustomize overlays"
        kserve -> openshiftOAuth "oauth-proxy sidecar for inference auth"
        kserve -> kubeRBACProxy "Auth proxy for RBAC enforcement"
        llmisvcController -> llmdScheduler "Deploys scheduler for InferencePools"
        llmisvcController -> llmdWVA "Creates VariantAutoscaling CRs" "HTTPS/6443"
        llmisvcController -> vllm "References as LLM inference runtime image"

        # Relationships - Egress
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingface "Downloads model artifacts" "HTTPS/443"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
