workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models and inference services"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform managing inference service lifecycle, LLM serving, inference graphs, and local model caching" {
            manager = container "KServe Manager" "Reconciles InferenceService, InferenceGraph, ClusterServingRuntime, TrainedModel CRDs" "Go controller-runtime operator"
            llmisvcController = container "LLMISVC Controller" "Reconciles LLMInferenceService and LLMInferenceServiceConfig CRDs with Gateway API integration" "Go controller-runtime operator"
            localModelController = container "LocalModel Controller" "Manages persistent model caching at cluster level through PV/PVC lifecycle" "Go controller-runtime operator"
            localModelNodeAgent = container "LocalModelNode Agent" "Manages node-level model caching through batch Job-based model downloads" "Go controller-runtime operator"
            moduleOperator = container "KServe Module Operator" "Manages installation and configuration of KServe components on ODH/RHOAI platform" "Go controller-runtime operator"
            webhookServer = container "Webhook Server" "Validates and mutates KServe CRDs, handles CRD version conversion, injects pod sidecars" "Go admission webhook"
            inferenceRouter = container "Inference Router" "Routes requests through InferenceGraph DAGs with Kubernetes-native authentication" "Go HTTP server"
            pythonSDK = container "Python Model Servers" "Framework-specific model servers implementing V2 Inference Protocol" "Python FastAPI/uvicorn + gRPC"
            authProxy = container "odh-kube-auth-proxy" "TLS termination and Kubernetes RBAC authentication for metrics endpoint" "Sidecar proxy"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management via Certificate and ClusterIssuer CRDs" "External"
        gatewayAPI = softwareSystem "Gateway API" "Traffic management via Gateway and HTTPRoute resources" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring resources via ServiceMonitor/PodMonitor CRDs" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject CRDs" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for inference workloads" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management via VirtualService resources" "External"
        objectStorage = softwareSystem "Object Storage" "Model artifact storage (S3, GCS, Azure Blob)" "External"
        odhPlatform = softwareSystem "ODH Platform Utilities" "Platform detection, manifest rendering, and deployment helpers" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI web dashboard for model management" "Internal ODH"

        # User interactions
        dataScientist -> kserve "Creates InferenceService/LLMInferenceService CRs via kubectl/API"
        dataScientist -> inferenceRouter "Sends inference requests via HTTPS"
        dataScientist -> pythonSDK "Sends inference requests (HTTP/gRPC)"
        platformAdmin -> moduleOperator "Configures KServe via Kserve CR"

        # Internal flows
        manager -> kubernetesAPI "Watches CRDs, creates Deployments/Services/Routes" "HTTPS/6443"
        llmisvcController -> kubernetesAPI "Watches LLMInferenceService, creates HPA/LWS/InferencePool" "HTTPS/6443"
        localModelController -> kubernetesAPI "Manages PersistentVolumes/PVCs for model caching" "HTTPS/6443"
        localModelNodeAgent -> kubernetesAPI "Creates batch Jobs for model downloads" "HTTPS/6443"
        moduleOperator -> kubernetesAPI "Installs CRDs, Deployments, RBAC, webhooks" "HTTPS/6443"
        webhookServer -> kubernetesAPI "Called by kube-apiserver for admission" "HTTPS/443"
        inferenceRouter -> kubernetesAPI "TokenReview and SubjectAccessReview for auth" "HTTPS/6443"
        pythonSDK -> objectStorage "Downloads model artifacts" "HTTPS/443"

        # External dependencies
        kserve -> certManager "TLS certificate lifecycle for webhooks"
        llmisvcController -> gatewayAPI "Creates Gateway/HTTPRoute resources (conditional)"
        llmisvcController -> keda "Creates ScaledObject for autoscaling"
        llmisvcController -> prometheusOperator "Creates ServiceMonitor/PodMonitor"
        manager -> knative "Creates Knative Service resources"
        manager -> istio "Creates VirtualService resources"
        authProxy -> prometheus "Exposes authenticated metrics" "HTTPS/8443"
        moduleOperator -> odhPlatform "Platform detection and manifest rendering"
        odhDashboard -> kserve "UI management of inference services"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
