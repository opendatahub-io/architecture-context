workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, deploys, and manages ML inference services"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and LLM deployments"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing CRDs and controllers for deploying, scaling, and managing ML inference services" {
            kserveController = container "kserve-controller-manager" "Manages InferenceService, InferenceGraph, TrainedModel, LocalModel CRDs with Knative, Istio, Gateway API, KEDA, and OTel integration" "Go Operator"
            llmisvcController = container "llmisvc-controller-manager" "Dedicated controller for LLMInferenceService with Gateway API, LeaderWorkerSet, disaggregated P/D, WVA autoscaling" "Go Operator"
            storageInitializer = container "storage-initializer" "Init container downloading model artifacts from cloud storage (S3, GCS, Azure, HF, OCI)" "Python Service"
            inferenceAgent = container "inference-agent" "Sidecar for model pulling, request/response logging, batching, health proxying" "Go Sidecar"
            inferenceRouter = container "inference-router" "HTTP router for InferenceGraph multi-step pipelines (splitter, switch, ensemble, sequence)" "Go Service"
            localmodelController = container "localmodel-controller" "Manages LocalModelCache/LocalModelNamespaceCache for distributed model caching" "Go Controller"
            localmodelNodeAgent = container "localmodelnode-agent" "Per-node DaemonSet managing model downloads and local folder management" "Go Agent"
            pythonSDK = container "kserve Python SDK" "Client library and model server framework (FastAPI/uvicorn) with REST/gRPC support" "Python Library"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation and resource management" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform for scale-to-zero inference" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for VirtualService/DestinationRule traffic management and mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress routing for InferenceService and LLMInferenceService" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObjects" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node distributed workload orchestration for LLM inference" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics collection via OpenTelemetryCollector CRD" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for metrics scraping" "External"
        wva = softwareSystem "llm-d WVA" "Workload Variant Autoscaler for intelligent LLM replica scaling" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management (upstream, replaced by OpenShift CA on OCP)" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "CA certificate signing for workload TLS certs" "External"
        kuadrant = softwareSystem "Kuadrant" "Gateway API auth enforcement via AuthPolicy CRD" "External"

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator deploying KServe via get_all_manifests.sh" "Internal RHOAI"

        s3 = softwareSystem "AWS S3" "Model artifact storage" "Cloud Storage"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "Cloud Storage"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "Cloud Storage"
        huggingface = softwareSystem "HuggingFace Hub" "Model artifact storage" "Cloud Storage"

        # Relationships
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        mlEngineer -> kserve "Configures ServingRuntimes, LLMInferenceServiceConfigs"

        rhodsOperator -> kserve "Deploys and manages lifecycle" "Kustomize"

        kserve -> kubernetesAPI "CRD reconciliation, resource CRUD" "HTTPS/6443"
        kserve -> knativeServing "Creates Knative Services for serverless mode" "HTTPS/6443 (API)"
        kserve -> istio "Creates VirtualServices/DestinationRules for traffic routing" "HTTPS/6443 (API)"
        kserve -> gatewayAPI "Creates HTTPRoutes for ingress routing" "HTTPS/6443 (API)"
        kserve -> keda "Creates ScaledObjects for event-driven autoscaling" "HTTPS/6443 (API)"
        kserve -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node LLM workloads" "HTTPS/6443 (API)"
        kserve -> otelOperator "Creates OpenTelemetryCollectors for metrics" "HTTPS/6443 (API)"
        kserve -> prometheusOperator "Creates PodMonitors/ServiceMonitors" "HTTPS/6443 (API)"
        kserve -> wva "Creates VariantAutoscalings for LLM scaling" "HTTPS/6443 (API)"
        kserve -> certManager "References Certificates/Issuers for webhook TLS" "HTTPS/6443 (API)"
        kserve -> openshiftServiceCA "Reads CA signing key for workload TLS certs" "Secret"
        kserve -> kuadrant "Watches AuthPolicy CRD as gateway precondition" "HTTPS/6443 (API)"

        kserve -> s3 "Downloads model artifacts" "HTTPS/443"
        kserve -> gcs "Downloads model artifacts" "HTTPS/443"
        kserve -> azure "Downloads model artifacts" "HTTPS/443"
        kserve -> huggingface "Downloads model artifacts" "HTTPS/443"

        # Container-level relationships
        kserveController -> kubernetesAPI "Reconciles CRDs" "HTTPS/6443"
        llmisvcController -> kubernetesAPI "Reconciles LLMInferenceService CRDs" "HTTPS/6443"
        storageInitializer -> s3 "Downloads models" "HTTPS/443"
        storageInitializer -> gcs "Downloads models" "HTTPS/443"
        storageInitializer -> azure "Downloads models" "HTTPS/443"
        storageInitializer -> huggingface "Downloads models" "HTTPS/443"
        inferenceRouter -> kserveController "Routes to InferenceService endpoints" "HTTP/HTTPS"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Cloud Storage" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
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
