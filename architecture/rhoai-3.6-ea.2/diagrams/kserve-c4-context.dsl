workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService / LLMInferenceService CRs"
        mlEngineer = person "ML Engineer" "Manages serving runtimes, local model caching, and inference pipelines"
        externalClient = person "External Client" "Sends inference requests to deployed models"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for RHOAI" {
            moduleController = container "kserve-module-controller" "Meta-operator: deploys/manages all KServe sub-controllers, CRDs, webhooks, RBAC, serving runtimes" "Go Operator"
            controllerManager = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, TrainedModel; manages model serving lifecycle" "Go Operator"
            llmisvcController = container "llmisvc-controller" "Reconciles LLMInferenceService/Config; Gateway API inference extensions, multi-node inference" "Go Operator"
            localmodelController = container "localmodel-controller" "Reconciles LocalModelCache/NamespaceCache; manages PV/PVC and download Jobs" "Go Operator"
            localmodelnodeAgent = container "localmodelnode-agent" "DaemonSet: per-node model cache management via LocalModelNode" "Go DaemonSet"
            webhookServer = container "Webhook Server" "16+ admission webhooks (mutating, validating, conversion)" "Go Service"
            storageInitializer = container "storage-initializer" "Init container: downloads models from S3/GCS/Azure/HF/OCI" "Python"
            router = container "router" "InferenceGraph request routing: ensemble, splitter, switch topologies" "Go HTTP Server"
            modelServers = container "Model Servers" "Pluggable serving runtimes: vLLM, OpenVINO, MLServer, HuggingFace, AutoGluon" "Python/C++"
            pythonSDK = container "Python SDK" "Client library, model server framework, storage handlers" "Python"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes authorization for metrics" "Go Sidecar"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress routing" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh: VirtualService routing, mTLS" "Internal Platform"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform" "Internal Platform"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject" "Internal Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Multi-node inference topology" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI user interface" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3)" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage (GCS)" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model download hub" "External"
        ociRegistries = softwareSystem "OCI Registries" "Container image and model registries" "External"

        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl / Dashboard"
        mlEngineer -> kserve "Manages ServingRuntimes, LocalModelCache"
        externalClient -> kserve "Sends inference requests" "HTTPS/443"

        kserve -> kubernetesAPI "All controller resource operations" "HTTPS/6443"
        kserve -> certManager "TLS certificate lifecycle for webhooks" "HTTPS/6443"
        kserve -> gatewayAPI "HTTPRoute management for model endpoints" "HTTPS/6443"
        kserve -> istio "VirtualService and DestinationRule management" "HTTPS/6443"
        kserve -> knativeServing "Serverless model deployment and autoscaling" "HTTPS/6443"
        kserve -> keda "Event-driven autoscaling" "HTTPS/6443"
        kserve -> leaderWorkerSet "Multi-node inference" "HTTPS/6443"
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443"
        kserve -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        kserve -> azureStorage "Downloads model artifacts" "HTTPS/443"
        kserve -> huggingFaceHub "Downloads models" "HTTPS/443"
        kserve -> ociRegistries "Downloads models from registries" "HTTPS/443"
        prometheus -> kserve "Scrapes metrics" "HTTPS/8443"
        odhDashboard -> kserve "UI management of InferenceServices"

        moduleController -> controllerManager "Deploys and manages"
        moduleController -> llmisvcController "Deploys and manages"
        moduleController -> localmodelController "Deploys and manages"
        moduleController -> localmodelnodeAgent "Deploys and manages"
        moduleController -> webhookServer "Installs webhook configurations"
        controllerManager -> storageInitializer "Injects as init container"
        controllerManager -> modelServers "Creates serving pods"
        controllerManager -> router "Creates for InferenceGraph"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
