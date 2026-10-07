workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and KServe configuration"

        kserve = softwareSystem "KServe" "Kubernetes-native platform for deploying, scaling, and managing ML model inference services" {
            moduleController = container "kserve-module-controller" "Top-level ODH module controller; reconciles Kserve component CR, manages CRDs, RBAC, webhooks, deployments" "Go Operator (controller-runtime)"
            odhModelController = container "odh-model-controller" "Manages InferenceService networking, RBAC, NIM accounts, webhook configuration" "Go Controller"
            modelServingAPI = container "model-serving-api" "REST API server for model serving operations (Gateway listing, namespace scoping)" "Go HTTP Server" "TLS 8443/TCP"
            isvcController = container "InferenceService Controller" "Reconciles v1beta1 InferenceService into Deployments, Services, Ingress, autoscalers" "Go Controller"
            llmisvcController = container "LLMInferenceService Controller" "Reconciles v1alpha2 LLMInferenceService with LeaderWorkerSets, InferencePools, Gateway API" "Go Controller"
            igController = container "InferenceGraph Controller" "Reconciles InferenceGraph DAG for traffic splitting and ensemble patterns" "Go Controller"
            localModelController = container "LocalModelCache Controller" "Coordinates model pre-caching across cluster nodes via PVs and download Jobs" "Go Controller"
            localModelNodeAgent = container "LocalModelNode Agent" "Per-node agent managing local model download jobs and PVC lifecycle" "Go DaemonSet"
            router = container "Router" "Request router for InferenceGraph traffic: splitter, ensemble, switch, single patterns" "Go HTTP Server"
            qpext = container "qpext" "Queue proxy extension collecting per-model Prometheus metrics" "Go Sidecar"
            pythonSDK = container "KServe Python SDK" "KServe Predict Protocol v2 over REST (FastAPI) and gRPC" "Python"
            modelServers = container "Model Servers" "HuggingFace, sklearn, LightGBM, XGBoost, PMML, PaddlePaddle, AIF360, ART, AutoGluon" "Python"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD, watches, leader election" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks and serving endpoints" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute management for model serving ingress" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic routing, mTLS enforcement, DestinationRules" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform (optional pathway)" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject for model servers" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node LLM serving topology management" "External"
        prometheusOp = softwareSystem "prometheus-operator" "ServiceMonitor/PodMonitor for observability" "External"
        otel = softwareSystem "OpenTelemetry Operator" "Distributed tracing infrastructure" "External"
        kuadrant = softwareSystem "Kuadrant" "API authentication policy for model endpoints" "External"
        dsc = softwareSystem "DataScienceCluster" "RHOAI platform component enablement state" "Internal RHOAI"
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS, MinIO)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        registries = softwareSystem "Container Registries" "OCI model artifact pull and cosign verification" "External"

        user -> kserve "Creates InferenceService / LLMInferenceService via kubectl"
        platformAdmin -> kserve "Configures Kserve CR, ClusterServingRuntimes"

        moduleController -> k8sAPI "Resource CRUD, watches, leader election" "HTTPS/6443"
        moduleController -> certManager "Certificate provisioning" "HTTPS/6443"
        isvcController -> gatewayAPI "Create/manage HTTPRoutes" "HTTPS/6443"
        isvcController -> istio "VirtualService/DestinationRule management" "HTTPS/6443"
        isvcController -> knative "Knative Service lifecycle (optional)" "HTTPS/6443"
        isvcController -> keda "ScaledObject autoscaling" "HTTPS/6443"
        llmisvcController -> lws "LeaderWorkerSet lifecycle" "HTTPS/6443"
        odhModelController -> kuadrant "AuthPolicy for model endpoints" "HTTPS/6443"
        moduleController -> prometheusOp "ServiceMonitor/PodMonitor" "HTTPS/6443"
        moduleController -> otel "OpenTelemetryCollector" "HTTPS/6443"
        moduleController -> dsc "Read platform enablement state" "HTTPS/6443"

        localModelNodeAgent -> s3 "Download model artifacts" "HTTPS/443"
        localModelNodeAgent -> gcs "Download model artifacts" "HTTPS/443"
        localModelNodeAgent -> azure "Download model artifacts" "HTTPS/443"
        moduleController -> registries "OCI model pull, cosign verification" "HTTPS/443"
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
                shape Person
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
