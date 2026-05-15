workspace {
    model {
        // Actors
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRDs"
        platformAdmin = person "Platform Admin" "Manages KServe installation, ServingRuntimes, and LLMInferenceServiceConfigs"

        // Primary System
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for ML inference on RHOAI" {
            kserveController = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel, LocalModel CRDs" "Go Operator (controller-runtime)" "Controller"
            llmisvcController = container "llmisvc-controller-manager" "Reconciles LLMInferenceService CRD with disaggregated P/D, Gateway API, WVA autoscaling" "Go Operator (controller-runtime)" "Controller"
            agent = container "kserve-agent" "Reverse proxy sidecar for request logging, batching, and model pulling" "Go Sidecar" "Sidecar"
            router = container "kserve-router" "InferenceGraph DAG router (Sequence, Splitter, Ensemble, Switch)" "Go Service" "Service"
            storageInitializer = container "kserve-storage-initializer" "Downloads model artifacts from S3, GCS, Azure, HF, OCI, PVC, HDFS" "Python 3.11 Init Container" "InitContainer"
            webhookService = container "Webhook Server" "Mutating and validating webhooks for CRD defaulting and validation" "Go admission webhook" "Webhook"
        }

        // Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys KServe via kustomize overlays" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway (data-science-gateway)" "Platform-managed Gateway CR for LLMInferenceService HTTPRoutes" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Signs webhook and workload TLS certificates" "Internal OpenShift"

        // External Dependencies
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform (1.28+)" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway for ingress routing" "External"
        inferenceGateway = softwareSystem "Inference Gateway Extension" "InferencePool for scheduler-based load balancing (EPP)" "External"
        knativeServing = softwareSystem "Knative Serving" "Scale-to-zero, revision management, traffic splitting" "External"
        istio = softwareSystem "Istio" "Service mesh, mTLS, VirtualService ingress, DestinationRules" "External"
        keda = softwareSystem "KEDA" "External metric autoscaling via Prometheus queries (v2.17+)" "External"
        wva = softwareSystem "WVA (Workload Variant Autoscaler)" "Computes desired replicas based on model characteristics" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node distributed inference workloads" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "PodMonitor and ServiceMonitor for metrics scraping" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics collection sidecar for InferenceService pods" "External"
        kuadrant = softwareSystem "Kuadrant" "Authentication enforcement for HTTPRoutes on OpenShift" "External"

        // External Services
        objectStorage = softwareSystem "Object Storage (S3/GCS/Azure)" "Model artifact storage" "External Service"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External Service"
        ociRegistries = softwareSystem "OCI Registries" "Container and model image registries" "External Service"

        // Relationships - Actors
        dataScientist -> kserve "Creates InferenceService/LLMInferenceService via kubectl/API"
        platformAdmin -> kserve "Manages ServingRuntimes, LLMInferenceServiceConfigs, cluster settings"
        rhodsOperator -> kserve "Deploys via config/overlays/odh/ kustomize" "kustomize"

        // Relationships - Internal containers
        kserveController -> webhookService "Registers mutating/validating webhooks"
        kserveController -> kubernetes "CRUD on Deployments, Services, Knative Services, VirtualServices, HTTPRoutes" "HTTPS/6443"
        llmisvcController -> kubernetes "CRUD on Deployments, LeaderWorkerSets, HTTPRoutes, InferencePools" "HTTPS/6443"
        llmisvcController -> webhookService "Registers validating/conversion webhooks"
        storageInitializer -> objectStorage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingFaceHub "Downloads models from HF Hub" "HTTPS/443"
        storageInitializer -> ociRegistries "Pulls model images" "HTTPS/443"
        router -> kserve "Calls target InferenceService endpoints" "HTTP/HTTPS"

        // Relationships - External dependencies
        kserveController -> knativeServing "Creates Knative Services for serverless mode" "K8s API"
        kserveController -> istio "Creates VirtualServices for Istio ingress" "K8s API"
        kserveController -> keda "Creates ScaledObjects for autoscaling" "K8s API"
        kserveController -> otelOperator "Creates OpenTelemetry Collectors" "K8s API"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes, watches Gateways" "K8s API"
        llmisvcController -> inferenceGateway "Creates InferencePools (v1 + v1alpha2)" "K8s API"
        llmisvcController -> wva "Creates VariantAutoscaling for LLM autoscaling" "K8s API"
        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node inference" "K8s API"
        llmisvcController -> prometheusOperator "Creates PodMonitors, ServiceMonitors" "K8s API"
        llmisvcController -> istio "Creates DestinationRules for TLS origination (OCP)" "K8s API"
        llmisvcController -> kuadrant "Checks AuthPolicy CRD availability (OCP)" "K8s API"
        llmisvcController -> platformGateway "References platform Gateway for HTTPRoutes" "K8s API"
        kserve -> openshiftServiceCA "Webhook and workload TLS certificate signing" "K8s API"
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
            element "Internal OpenShift" {
                background #50c878
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #50c878
                color #ffffff
            }
            element "Service" {
                background #50c878
                color #ffffff
            }
            element "InitContainer" {
                background #9b59b6
                color #ffffff
            }
            element "Webhook" {
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
