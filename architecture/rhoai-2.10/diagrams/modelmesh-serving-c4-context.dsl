workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys machine learning models for inference"
        inferenceClient = person "Application / End User" "Sends inference requests to deployed models"

        modelmesh = softwareSystem "ModelMesh Serving" "Kubernetes operator for managing multi-model serving infrastructure with ModelMesh routing layer" {
            controller = container "modelmesh-controller" "Reconciles Predictor, ServingRuntime, and InferenceService CRDs; manages runtime deployments" "Go Operator" {
                reconciler = component "CRD Reconciler" "Watches and reconciles custom resources" "controller-runtime"
                deployer = component "Runtime Deployer" "Creates and manages runtime pod deployments" "Kubernetes client-go"
            }

            webhook = container "Validating Webhook" "Validates ServingRuntime CR specifications" "Go Service, Port 9443/TCP HTTPS"

            runtimePod = container "Runtime Pod" "Multi-container pod hosting ModelMesh, model server, and supporting services" "Deployment" {
                modelMesh = component "ModelMesh Container" "Routes inference requests, manages model loading/unloading" "Java Service, Port 8033/TCP gRPC"
                restProxy = component "REST Proxy" "Translates KServe V2 REST API to gRPC" "Go Service, Port 8008/TCP HTTP"
                storagePuller = component "Storage Puller" "Pulls models from S3/PVC storage" "Go Service, Port 8086/TCP gRPC"
                runtimeAdapter = component "Runtime Adapter" "Bridges ModelMesh and model server" "Go Service, Port 8001/TCP gRPC"
                modelServer = component "Model Server Runtime" "Executes ML inference (Triton/MLServer/OVMS/TorchServe)" "Container, Port 8085/TCP gRPC"
            }
        }

        # External Dependencies
        etcd = softwareSystem "etcd" "Distributed key-value store for model metadata and pod coordination" "External Required"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes cluster API server" "External Required"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts (AWS S3, MinIO, Ceph)" "External Optional"
        pvcStorage = softwareSystem "PersistentVolumeClaim" "On-cluster storage for model artifacts (alternative to S3)" "External Optional"

        # Model Server Runtimes (one of many)
        triton = softwareSystem "Triton Inference Server" "NVIDIA model server runtime for TensorFlow, PyTorch, ONNX" "External Optional"
        mlserver = softwareSystem "MLServer" "Seldon Python model server runtime" "External Optional"
        ovms = softwareSystem "OpenVINO Model Server" "Intel model server runtime" "External Optional"
        torchserve = softwareSystem "TorchServe" "PyTorch model server runtime" "External Optional"

        # Internal ODH Dependencies
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science components" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External Optional"

        # User interactions
        user -> modelmesh "Creates Predictor, ServingRuntime, InferenceService CRs via kubectl"
        user -> dashboard "Manages models via web UI"
        inferenceClient -> modelmesh "Sends inference requests" "HTTP/8008 REST or gRPC/8033"

        # Controller interactions
        controller -> k8sAPI "Watches CRDs and manages resources" "HTTPS/6443, ServiceAccount token"
        webhook -> k8sAPI "Validates ServingRuntime CRs" "HTTPS/9443, TLS client auth"
        controller -> runtimePod "Creates and manages deployments"

        # Runtime pod interactions
        modelMesh -> etcd "Stores model metadata, coordinates placement" "HTTP/2379, Basic auth (optional)"
        storagePuller -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS IAM or access keys"
        storagePuller -> pvcStorage "Reads model artifacts (alternative to S3)" "PVC mount"
        runtimeAdapter -> modelServer "Loads models and executes inference" "gRPC/8001, 8085"

        # Model server runtime selection (one of many)
        modelServer -> triton "Uses Triton for inference (option 1)" "Container runtime"
        modelServer -> mlserver "Uses MLServer for inference (option 2)" "Container runtime"
        modelServer -> ovms "Uses OpenVINO for inference (option 3)" "Container runtime"
        modelServer -> torchserve "Uses TorchServe for inference (option 4)" "Container runtime"

        # Integration points
        dashboard -> modelmesh "Integrates for model management UI" "Kubernetes API"
        prometheus -> runtimePod "Scrapes runtime metrics" "HTTP/2112"
        prometheus -> controller "Scrapes controller metrics" "HTTPS/8443, mTLS"
        certManager -> webhook "Provisions TLS certificates" "kubernetes.io/tls secret"
        certManager -> controller "Provisions metrics proxy TLS" "kubernetes.io/tls secret"

        # Data flow - inference request
        restProxy -> modelMesh "Converts REST to gRPC"
        modelMesh -> runtimeAdapter "Routes inference request"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout lr
        }

        container modelmesh "Containers" {
            include *
            autoLayout tb
        }

        component controller "ControllerComponents" {
            include *
            autoLayout lr
        }

        component runtimePod "RuntimePodComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "External Required" {
                background #cc0000
                color #ffffff
            }
            element "External Optional" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }

        theme default
    }
}
