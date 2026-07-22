workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform via ODH Operator and Kserve CR"

        kserve = softwareSystem "KServe" "Kubernetes-native model inference platform with multi-controller architecture for ML and LLM workloads" {
            kserveController = container "kserve-controller" "Manages InferenceService, TrainedModel, InferenceGraph CRDs with webhooks" "Go Operator" {
                isvcReconciler = component "InferenceService Reconciler" "Reconciles InferenceService CRs — creates deployments, services, ingress, HPA, KEDA, OTel" "controller-runtime"
                igReconciler = component "InferenceGraph Reconciler" "Reconciles InferenceGraph CRs — creates router deployments and Knative services" "controller-runtime"
                tmReconciler = component "TrainedModel Reconciler" "Manages multi-model serving registrations" "controller-runtime"
                webhookServer = component "Webhook Server" "Validates/mutates InferenceService, pod injection (storage-init, agent, batcher)" "9443/TCP TLS"
            }

            llmisvcController = container "llmisvc-controller" "Controller for LLMInferenceService v1alpha2 — LLM workload orchestration with disaggregated prefill/decode, multi-node, GIE" "Go Operator" {
                llmisvcReconciler = component "LLMISvc Reconciler" "Reconciles LLMInferenceService — creates workloads, schedulers, InferencePools, HTTPRoutes" "controller-runtime"
                llmWebhookServer = component "LLM Webhook Server" "Validates/defaults LLMInferenceService and LLMInferenceServiceConfig" "9443/TCP TLS"
            }

            localmodelController = container "localmodel-controller" "Manages LocalModelCache and LocalModelNamespaceCache — PV/PVC for model caching" "Go Operator"
            localmodelNodeAgent = container "localmodelnode-agent" "Per-node agent managing model download jobs and local storage" "Go Operator (DaemonSet)"
            moduleController = container "kserve-module-controller" "ODH/RHOAI platform module — deploys and manages all KServe components via Kserve CR" "Go Operator"

            inferenceAgent = container "inference-agent" "Sidecar for model pulling, request logging, batching, metrics" "Go Service"
            inferenceRouter = container "inference-router" "DAG-based inference pipeline router (ensemble, sequence, splitter, switch)" "Go Service"
            storageInitializer = container "storage-initializer" "Init container downloading model artifacts from S3, GCS, Azure, HuggingFace, PVC, OCI, HDFS" "Python 3.11"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration and API server" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for webhook TLS" "External"
        istio = softwareSystem "Istio / Service Mesh" "Traffic management, mTLS, VirtualService, DestinationRule" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for InferenceService" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress and GIE InferencePool" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "OTel Collector sidecar injection" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node serving topology for LLM workloads" "External"
        wva = softwareSystem "Workload Variant Autoscaler" "LLM-specific autoscaling (VariantAutoscaling)" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for observability" "External"

        # Internal Platform Dependencies
        odhOperator = softwareSystem "ODH / RHOAI Platform Operator" "Platform operator that creates Kserve CR" "Internal RHOAI"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "mTLS enforcement and traffic management" "Internal RHOAI"
        dsGateway = softwareSystem "data-science-gateway" "Platform ingress gateway for LLMInferenceService" "Internal RHOAI"

        # External Services
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Service"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Model download (hf:// URI scheme)" "External Service"

        # Relationships
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        platformAdmin -> odhOperator "Configures platform via DataScienceCluster"
        odhOperator -> kserve "Creates Kserve CR to deploy KServe"

        kserve -> kubernetes "CRD watch/reconciliation" "HTTPS/443 SA token"
        kserve -> certManager "Webhook TLS certificate provisioning" "HTTPS/443"
        kserve -> istio "VirtualService/DestinationRule CRUD, mTLS" "HTTPS/443"
        kserve -> knative "Knative Service CRUD (serverless mode)" "HTTPS/443"
        kserve -> gatewayAPI "HTTPRoute/Gateway/InferencePool CRUD" "HTTPS/443"
        kserve -> keda "ScaledObject CRUD (event-driven autoscaling)" "HTTPS/443"
        kserve -> otelOperator "OTel Collector sidecar injection" "HTTPS/443"
        kserve -> leaderWorkerSet "LeaderWorkerSet CRUD (multi-node)" "HTTPS/443"
        kserve -> wva "VariantAutoscaling CRUD (LLM scaling)" "HTTPS/443"
        kserve -> prometheusOp "PodMonitor/ServiceMonitor CRUD" "HTTPS/443"

        kserve -> s3 "Download model artifacts" "HTTPS/443 AWS IAM"
        kserve -> gcs "Download model artifacts" "HTTPS/443 GCP creds"
        kserve -> azureBlob "Download model artifacts" "HTTPS/443 Azure Identity"
        kserve -> huggingface "Download models" "HTTPS/443 HF Token"

        # Container relationships
        moduleController -> kserveController "Deploys via kustomize manifests"
        moduleController -> llmisvcController "Deploys via kustomize manifests"
        moduleController -> localmodelController "Deploys via kustomize manifests"

        kserveController -> inferenceAgent "Injects as sidecar via pod webhook"
        kserveController -> storageInitializer "Injects as init container via pod webhook"
        kserveController -> inferenceRouter "Creates for InferenceGraph workloads"

        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSet for multi-node"
        llmisvcController -> gatewayAPI "Creates HTTPRoute and InferencePool"

        localmodelController -> localmodelNodeAgent "Coordinates via LocalModelNode CRs"
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

        component kserveController "KServeControllerComponents" {
            include *
            autoLayout
        }

        component llmisvcController "LLMISvcControllerComponents" {
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
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
