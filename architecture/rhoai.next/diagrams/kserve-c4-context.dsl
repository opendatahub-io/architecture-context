workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML/LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and autoscaling policies"
        platformAdmin = person "Platform Admin" "Manages KServe deployment and platform configuration"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for ML and LLM inference workloads" {
            kserveController = container "kserve-controller" "Reconciles InferenceService, TrainedModel, InferenceGraph CRDs" "Go Operator (controller-runtime)" {
                isvcReconciler = component "InferenceService Reconciler" "Manages predictor/transformer/explainer deployments"
                igReconciler = component "InferenceGraph Reconciler" "Manages multi-model inference pipelines"
                webhookServer = component "Webhook Server" "Validates/mutates CRDs, injects sidecars" "9443/TCP"
            }

            llmisvcController = container "llmisvc-controller" "Reconciles LLMInferenceService with Gateway API and disaggregated P/D" "Go Operator (controller-runtime)" {
                llmReconciler = component "LLMInferenceService Reconciler" "Manages LLM workloads with InferencePool and VariantAutoscaling"
                routerDiscovery = component "Router Discovery" "Discovers Gateways and creates HTTPRoutes"
                scalingManager = component "Scaling Manager" "Configures HPA, KEDA, or VariantAutoscaling"
            }

            localmodelController = container "localmodel-controller" "Manages LocalModelCache CRDs with PV/PVC distribution" "Go Operator (controller-runtime)"

            localmodelAgent = container "localmodelnode-agent" "DaemonSet managing model downloads on worker nodes" "Go DaemonSet"

            kserveAgent = container "kserve-agent" "Sidecar proxy for model pulling, logging, batching" "Go Sidecar" "9081/TCP"

            kserveRouter = container "kserve-router" "Routes requests through InferenceGraph nodes" "Go Service" "8080/TCP"

            storageInitializer = container "storage-initializer" "Downloads model artifacts from remote storage" "Python Init Container"

            pythonSDK = container "KServe Python SDK" "Model serving framework with V1/V2/OpenAI REST and gRPC" "Python Library" "8080/TCP, 8081/TCP"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress routing" "External"
        gatewayInferenceExt = softwareSystem "Gateway API Inference Extension" "InferencePool and InferenceModel CRDs" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management (non-RHOAI)" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Sidecar metric collector for autoscaling" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node LLM workload orchestration" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "PodMonitor/ServiceMonitor for metrics" "External"
        llmdWVA = softwareSystem "llm-d WVA" "Cost-aware variant autoscaling for LLMs" "External"
        kuadrant = softwareSystem "Kuadrant" "Gateway auth policy (OCP)" "External"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys KServe via kustomize manifests" "Internal RHOAI"
        openshiftRouteAPI = softwareSystem "OpenShift Route API" "External route access for InferenceGraph" "Internal RHOAI"
        openshiftSCC = softwareSystem "OpenShift SCC" "SecurityContextConstraints for privileged workloads" "Internal RHOAI"
        openshiftServingCerts = softwareSystem "OpenShift Serving Certs" "Automatic TLS cert provisioning for webhooks" "Internal RHOAI"

        # External Services
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External Service"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Service"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Service"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External Service"

        # Relationships - Users
        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        mlEngineer -> kserve "Configures ServingRuntimes and scaling policies"
        platformAdmin -> rhodsOperator "Manages KServe deployment configuration"

        # Relationships - KServe → External Dependencies
        kserveController -> kubernetes "CRUD Deployments, Services, Ingress, HPAs" "HTTPS/443"
        kserveController -> knativeServing "Creates Knative Services for serverless mode" "HTTPS/443"
        kserveController -> istio "Creates VirtualServices for traffic management" "HTTPS/443"
        kserveController -> keda "Creates ScaledObjects for autoscaling" "HTTPS/443"
        kserveController -> otelOperator "Creates OTel Collector sidecars" "HTTPS/443"

        llmisvcController -> kubernetes "CRUD Deployments, Services, Secrets, HTTPRoutes" "HTTPS/443"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes, discovers Gateways" "HTTPS/443"
        llmisvcController -> gatewayInferenceExt "Creates InferencePools" "HTTPS/443"
        llmisvcController -> istio "Creates DestinationRules for mTLS (OCP)" "HTTPS/443"
        llmisvcController -> keda "Creates ScaledObjects" "HTTPS/443"
        llmisvcController -> leaderWorkerSet "Creates LeaderWorkerSets for multi-node" "HTTPS/443"
        llmisvcController -> prometheusOperator "Creates PodMonitors, ServiceMonitors" "HTTPS/443"
        llmisvcController -> llmdWVA "Creates VariantAutoscaling for cost-aware scaling" "HTTPS/443"
        llmisvcController -> kuadrant "Checks AuthPolicy preconditions (OCP)" "HTTPS/443"
        llmisvcController -> openshiftSCC "Uses SCC for multi-node workloads" "RBAC"

        localmodelController -> kubernetes "Creates PVs, PVCs for model caching" "HTTPS/443"
        localmodelAgent -> kubernetes "Creates download Jobs on worker nodes" "HTTPS/443"

        kserveController -> openshiftRouteAPI "Creates Routes for InferenceGraph" "HTTPS/443"
        kserveController -> openshiftServingCerts "Webhook TLS via annotation" "annotation"

        # Relationships - Egress
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azureStorage "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> huggingfaceHub "Downloads pre-trained models" "HTTPS/443"
        localmodelAgent -> s3Storage "Downloads models for local caching" "HTTPS/443"

        # Internal platform
        rhodsOperator -> kserve "Deploys via kustomize at pinned commit"
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

        component llmisvcController "LLMISVCControllerComponents" {
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
