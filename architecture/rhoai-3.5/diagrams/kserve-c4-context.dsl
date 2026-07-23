workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and KServe module deployment"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform with serverless inference, LLM-optimized serving, and model lifecycle management" {
            controllerManager = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel CRs; manages deployments, services, ingress, autoscaling" "Go Operator (controller-runtime)"
            llmisvcController = container "llmisvc-controller-manager" "Reconciles LLMInferenceService CRs; manages LLM workloads with distributed inference, routing, scheduling, monitoring" "Go Operator (controller-runtime)"
            localmodelController = container "kserve-localmodel-controller" "Reconciles LocalModelCache CRs; manages PV/PVC and LocalModelNode entries for model pre-caching" "Go Operator (controller-runtime)"
            localmodelAgent = container "kserve-localmodelnode-agent" "DaemonSet agent downloading models via batch Jobs; manages local model storage on each node" "Go DaemonSet"
            moduleController = container "kserve-module-controller" "Platform module deploying entire KServe stack; reconciles Kserve CR, renders kustomize manifests" "Go Operator (controller-runtime)"
            agent = container "kserve-agent" "Sidecar for model pulling, request logging, batching" "Go Sidecar"
            router = container "kserve-router" "HTTP request router for InferenceGraph DAG execution" "Go Service"
            storageInitializer = container "kserve-storage-initializer" "Downloads models from S3, GCS, Azure, HuggingFace, OCI into pod volumes" "Python Init Container"
            webhooks = container "Pod Mutation Webhooks" "Injects storage initializers, agents, batchers, metrics aggregators, accelerator selectors" "Go Admission Webhook"
        }

        # External Dependencies
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD CRUD, deployments, RBAC" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for InferenceService deployment" "External (optional)"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for VirtualService routing, mTLS, traffic management" "External (optional)"
        gatewayApi = softwareSystem "Gateway API" "HTTPRoute-based ingress for model endpoints" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management for webhooks" "External"
        keda = softwareSystem "KEDA" "Advanced autoscaling with custom metrics" "External (optional)"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node distributed inference orchestration" "External (optional)"
        prometheusOp = softwareSystem "Prometheus Operator" "PodMonitor and ServiceMonitor for metrics scraping" "External (optional)"
        dra = softwareSystem "DRA" "Dynamic Resource Allocation for GPU/accelerator provisioning" "External (optional)"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator deploying kserve-module via Kserve CR" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Model serving API and webhook management" "Internal RHOAI"
        wva = softwareSystem "Workload Variant Autoscaler" "Variant-aware autoscaling for LLM workloads" "Internal RHOAI"
        inferencePool = softwareSystem "GIE InferencePool" "Gateway API model-based routing and scheduling" "Internal RHOAI"

        # External Services
        cloudStorage = softwareSystem "Cloud Storage" "S3, GCS, Azure Blob, HuggingFace Hub for model artifacts" "External Service"

        # Relationships
        user -> kserve "Creates InferenceService / LLMInferenceService via kubectl/API"
        platformAdmin -> kserve "Manages KServe deployment via Kserve CR"

        kserve -> k8sApi "CRUD on CRDs, Deployments, Services, Ingress" "HTTPS/443"
        kserve -> knative "Creates Knative Services for serverless deployment" "HTTPS/443"
        kserve -> istio "Creates VirtualServices for routing and mTLS" "HTTPS/443"
        kserve -> gatewayApi "Creates HTTPRoutes for model endpoint ingress" "HTTPS/443"
        kserve -> certManager "Manages webhook TLS certificates" "HTTPS/443"
        kserve -> keda "Creates ScaledObjects for metric-based autoscaling" "HTTPS/443"
        kserve -> leaderWorkerSet "Creates LeaderWorkerSets for distributed inference" "HTTPS/443"
        kserve -> prometheusOp "Creates PodMonitors and ServiceMonitors" "HTTPS/443"
        kserve -> dra "Creates ResourceClaimTemplates for accelerators" "HTTPS/443"
        kserve -> cloudStorage "Downloads model artifacts" "HTTPS/443"

        rhodsOperator -> kserve "Deploys KServe via Kserve CR"
        odhModelController -> kserve "Manages model serving API webhooks"
        kserve -> wva "Deploys variant-aware autoscaler"
        kserve -> inferencePool "Creates InferencePools for model routing"
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
            element "External (optional)" {
                background #bbbbbb
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
