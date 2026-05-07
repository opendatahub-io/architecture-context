workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML/LLM models for inference"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and KServe configuration"

        kserve = softwareSystem "KServe" "Kubernetes-native ML/AI model serving platform with CRD-driven lifecycle management" {
            kserveController = container "kserve-controller" "Manages InferenceService, InferenceGraph, TrainedModel CRDs" "Go Operator" "controller"
            llmisvcController = container "llmisvc-controller" "Manages LLMInferenceService CRD with multi-node, disaggregated P/D, Gateway API" "Go Operator" "controller"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache/LocalModelNamespaceCache CRDs, creates PVs/PVCs" "Go Operator" "controller"
            localmodelnodeAgent = container "localmodelnode-agent" "Per-node agent managing local model storage, download Jobs" "Go Agent (DaemonSet)" "agent"
            kserveAgent = container "kserve-agent" "Sidecar for model pulling, request logging, request batching" "Go Sidecar" "sidecar"
            kserveRouter = container "kserve-router" "HTTP router for InferenceGraph DAG-based inference pipelines" "Go Service" "utility"
            storageInitializer = container "storage-initializer" "Downloads model artifacts from cloud storage" "Python Init Container" "utility"
            webhookServer = container "Webhook Server" "Validates/defaults CRDs, injects sidecars" "Go Webhook" "webhook"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        istio = softwareSystem "Istio / OSSM" "Service mesh for traffic management and mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform (scale-to-zero)" "External"
        gatewayAPI = softwareSystem "Gateway API" "Modern HTTPRoute-based ingress routing" "External"
        keda = softwareSystem "KEDA" "External metrics-based autoscaling" "External"
        otel = softwareSystem "OpenTelemetry Operator" "Metrics collection and export" "External"
        prometheus = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for metrics scraping" "External"
        certManager = softwareSystem "cert-manager / service-ca" "TLS certificate management" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node workload orchestration" "External"
        llmdWVA = softwareSystem "LLM-D WVA" "Workload Variant Autoscaling for LLM inference" "External"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / odh-operator" "Deploys KServe via kustomize overlays" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for inference endpoints" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth proxy for RBAC enforcement" "Internal RHOAI"
        vllm = softwareSystem "vLLM Runtime" "LLM inference runtime (CUDA/ROCm/Gaudi/Spyre)" "Internal RHOAI"
        llmdScheduler = softwareSystem "LLM-D Inference Scheduler" "Request scheduling for InferencePools" "Internal RHOAI"

        # External Storage Services
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3-compatible)" "External Storage"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage (GCS)" "External Storage"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External Storage"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact repository" "External Storage"
        oci = softwareSystem "OCI Registries" "OCI artifact storage" "External Storage"

        # Relationships - Users
        datascientist -> kserve "Creates InferenceService/LLMInferenceService via kubectl/dashboard"
        platformadmin -> rhodsOperator "Configures and deploys KServe"

        # Relationships - KServe internals
        kserveController -> webhookServer "Validates and mutates CRDs"
        kserveController -> kserveAgent "Injects as sidecar via webhook"
        kserveController -> storageInitializer "Injects as init container via webhook"
        kserveRouter -> kserveController "Routes to InferenceService endpoints"

        # Relationships - External dependencies
        kserve -> kubernetes "CRUD for Deployments, Services, HPAs, etc." "HTTPS/6443"
        kserve -> istio "Creates VirtualServices, DestinationRules" "HTTPS/6443"
        kserve -> knative "Creates Knative Services for serverless mode" "HTTPS/6443"
        kserve -> gatewayAPI "Creates HTTPRoutes for modern ingress" "HTTPS/6443"
        kserve -> keda "Creates ScaledObjects for autoscaling" "HTTPS/6443"
        kserve -> otel "Creates OpenTelemetryCollectors" "HTTPS/6443"
        kserve -> prometheus "Creates PodMonitors/ServiceMonitors" "HTTPS/6443"
        kserve -> certManager "Webhook TLS certificates" "annotation-based"
        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node" "HTTPS/6443"
        llmisvcController -> llmdWVA "Creates VariantAutoscaling CRs" "HTTPS/6443"
        llmisvcController -> llmdScheduler "Deploys scheduler for InferencePools" "gRPC/TLS"

        # Relationships - Internal platform
        rhodsOperator -> kserve "Deploys via kustomize overlays"
        kserve -> openshiftOAuth "Auth proxy for inference endpoints" "HTTPS/8443"
        kserve -> kubeRBACProxy "RBAC enforcement for endpoints" "HTTPS/8443"
        kserve -> vllm "LLM inference runtime" "HTTPS/8000"

        # Relationships - Storage
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azure "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingface "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> oci "Downloads OCI artifacts" "HTTPS/443"
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
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "controller" {
                background #4a90e2
                color #ffffff
            }
            element "agent" {
                background #50c878
                color #ffffff
            }
            element "sidecar" {
                background #50c878
                color #ffffff
            }
            element "utility" {
                background #9b59b6
                color #ffffff
            }
            element "webhook" {
                background #e74c3c
                color #ffffff
            }
        }
    }
}
