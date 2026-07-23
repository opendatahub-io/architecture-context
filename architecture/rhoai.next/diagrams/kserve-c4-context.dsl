workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models and LLM inference services"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and KServe configuration"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for ML and LLM inference" {
            kserveController = container "kserve-controller-manager" "Manages InferenceService, InferenceGraph, TrainedModel CRDs; reconciles Deployments, Services, HTTPRoutes, VirtualServices" "Go Operator"
            llmisvcController = container "llmisvc-controller-manager" "Manages LLMInferenceService and LLMInferenceServiceConfig CRDs; creates workloads, schedulers, InferencePools, autoscaling" "Go Operator"
            moduleController = container "kserve-module-controller" "RHOAI platform integration; deploys KServe components via kustomize manifests" "Go Operator (Platform Module)"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache and LocalModelNamespaceCache CRDs; creates PVs/PVCs for model caching" "Go Operator"
            localmodeAgent = container "localmodelnode-agent" "Per-node model download agent; creates download Jobs on target nodes" "Go DaemonSet Agent"
            agent = container "kserve-agent" "Sidecar for model pulling, request/response logging, and request batching" "Go Sidecar"
            router = container "kserve-router" "InferenceGraph request router; supports splitter, switch, ensemble, sequence patterns" "Go Service"
            storageInitializer = container "kserve-storage-initializer" "Downloads model artifacts from S3, GCS, Azure, HuggingFace, OCI into pod volumes" "Python Init Container"
            autogluonServer = container "kserve-autogluon-server" "AutoGluon-based model server for tabular ML inference" "Python Service"
            webhookServer = container "Webhook Server" "24 admission webhooks (5 mutating, 15 validating, 4 conversion) for CRD validation and defaulting" "Go Webhook Service"
        }

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that creates Kserve CR to trigger deployment" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API Controller" "Provides HTTPRoute-based ingress for inference endpoints" "Internal RHOAI"
        gie = softwareSystem "GIE (Gateway API Inference Extension)" "Gateway-aware endpoint selection via InferencePool" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic routing, mTLS, VirtualServices, DestinationRules" "External"
        knative = softwareSystem "Knative Serving" "Serverless deployment with scale-to-zero for InferenceServices" "External"
        keda = softwareSystem "KEDA" "External metrics autoscaling via ScaledObjects with Prometheus triggers" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node LLM inference topology management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics collection sidecar injection" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "PodMonitor and ServiceMonitor for metrics scraping" "External"
        wva = softwareSystem "WVA (llm-d)" "Workload Variant Autoscaler for LLM-specific scaling" "External"
        prometheus = softwareSystem "Prometheus" "Metrics query endpoint for KEDA and HPA" "External"
        vllm = softwareSystem "vLLM Inference Engine" "LLM inference engine (CUDA, ROCm, Gaudi, Spyre variants)" "Internal RHOAI"
        llmdRouter = softwareSystem "llm-d Router/Scheduler" "Endpoint picker (EPP) for gateway-aware LLM scheduling" "Internal RHOAI"
        kubeAuthProxy = softwareSystem "kube-rbac-proxy / kube-auth-proxy" "Auth sidecar for SubjectAccessReview on InferenceService pods" "Internal RHOAI"
        s3Storage = softwareSystem "Cloud Object Storage" "S3, GCS, Azure Blob for model artifact storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading ML models" "External"
        kubernetes = softwareSystem "Kubernetes API" "Platform runtime for CRD management and resource CRUD" "External"
        odmController = softwareSystem "ODH Model Controller" "Additional RHOAI model serving webhook and mutation layer" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant" "AuthPolicy precondition check before creating HTTPRoutes" "Internal RHOAI"

        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl or Dashboard"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform including KServe"
        rhoaiOperator -> kserve "Creates Kserve CR to trigger deployment" "CRD Watch"

        kserve -> kubernetes "CRD reconciliation, resource CRUD" "HTTPS/443"
        kserve -> istio "Creates VirtualServices, DestinationRules for traffic routing and mTLS" "CRD"
        kserve -> knative "Creates Knative Services for serverless deployment" "CRD"
        kserve -> gatewayAPI "Creates HTTPRoutes for ingress routing" "CRD"
        kserve -> gie "Creates InferencePools for gateway-aware scheduling" "CRD"
        kserve -> keda "Creates ScaledObjects for external metrics autoscaling" "CRD"
        kserve -> lws "Creates LeaderWorkerSets for multi-node inference" "CRD"
        kserve -> certManager "Provisions TLS certificates for webhooks" "CRD"
        kserve -> otelOperator "Creates OpenTelemetryCollector CRs for metrics collection" "CRD"
        kserve -> prometheusOperator "Creates PodMonitors and ServiceMonitors" "CRD"
        kserve -> wva "Creates VariantAutoscaling CRs for LLM scaling" "CRD"
        kserve -> prometheus "Queries metrics for KEDA and HPA" "HTTP/9090"
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443"
        kserve -> huggingface "Downloads ML models" "HTTPS/443"
        kserve -> vllm "References vLLM images for LLMInferenceServiceConfig presets" "Container Image"
        kserve -> llmdRouter "Deploys EPP for gateway-aware scheduling" "Container Image"
        kserve -> kubeAuthProxy "Injects auth sidecar into InferenceService pods" "Container Image"
        odmController -> kserve "Mutates InferenceService, InferenceGraph, LLMInferenceService" "Webhooks"
        kuadrant -> kserve "AuthPolicy precondition check" "CRD"
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
