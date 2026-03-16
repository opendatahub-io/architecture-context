workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models using ModelMesh for multi-model serving"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator managing ModelMesh deployments for intelligent multi-model serving with automatic model placement and routing" {
            controller = container "ModelMesh Controller" "Reconciles CRDs and manages ModelMesh lifecycle" "Go Operator" {
                predictorCtrl = component "Predictor Controller" "Reconciles InferenceService and Predictor CRs"
                runtimeCtrl = component "ServingRuntime Controller" "Reconciles ServingRuntime and ClusterServingRuntime CRs"
                serviceCtrl = component "Service Controller" "Manages ModelMesh service deployments per namespace"
            }

            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime CRs" "Go ValidatingWebhook" {
                tags "Webhook"
            }

            mmRuntime = container "ModelMesh Runtime" "Multi-model serving runtime with intelligent placement" "Java + Python/C++" {
                mmContainer = component "ModelMesh Container" "Model routing and placement logic" "Java"
                serverContainer = component "Model Server" "Inference runtime (Triton/MLServer/OpenVINO/TorchServe)" "Python/C++"
                adapterContainer = component "Runtime Adapter" "Model pulling and runtime integration" "Go"
            }
        }

        k8s = softwareSystem "Kubernetes API" "Kubernetes control plane" {
            tags "External"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for ModelMesh state and model registry" {
            tags "External"
        }

        s3 = softwareSystem "S3/MinIO" "Object storage for model artifacts" {
            tags "External"
        }

        triton = softwareSystem "Triton Inference Server" "NVIDIA model server for TensorFlow, PyTorch, ONNX, TensorRT" {
            tags "External"
        }

        mlserver = softwareSystem "MLServer" "Seldon's Python-based model server for scikit-learn, XGBoost" {
            tags "External"
        }

        openvino = softwareSystem "OpenVINO Model Server" "Intel's model server for optimized inference" {
            tags "External"
        }

        torchserve = softwareSystem "TorchServe" "PyTorch native model serving" {
            tags "External"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS and traffic management" {
            tags "Internal ODH"
        }

        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" {
            tags "Internal ODH"
        }

        certManager = softwareSystem "cert-manager" "Certificate provisioning and management" {
            tags "Internal ODH"
        }

        inferenceClient = person "Inference Client" "Application or service making inference requests"

        # User interactions
        user -> modelmeshServing "Creates InferenceService, Predictor, ServingRuntime CRs via kubectl/API"
        inferenceClient -> mmRuntime "Sends inference requests via gRPC" "8033/TCP gRPC"

        # Core component interactions
        controller -> k8s "Watches CRDs and manages deployments" "HTTPS/6443 TLS 1.2+"
        webhook -> k8s "Called by API server for validation" "HTTPS/9443 TLS 1.2+"
        controller -> mmRuntime "Manages ModelMesh deployment lifecycle"

        # ModelMesh Runtime dependencies
        mmContainer -> etcd "Stores model registry and coordinates state" "HTTP/2379 plaintext"
        adapterContainer -> s3 "Downloads model artifacts" "HTTPS/443 or HTTP/9000"
        serverContainer -> triton "Uses as runtime (optional)" "gRPC/8001"
        serverContainer -> mlserver "Uses as runtime (optional)" "gRPC/8001"
        serverContainer -> openvino "Uses as runtime (optional)" "gRPC/8001"
        serverContainer -> torchserve "Uses as runtime (optional)" "gRPC/7070"

        # Internal ODH integrations
        modelmeshServing -> istio "Optional mTLS and traffic management" "mTLS"
        controller -> prometheus "Exposes metrics for collection" "HTTP/8080"
        webhook -> certManager "Obtains TLS certificates (optional)" "Certificate API"

        # Internal component interactions
        predictorCtrl -> k8s "Creates ModelMesh deployments"
        runtimeCtrl -> k8s "Manages runtime configurations"
        serviceCtrl -> k8s "Creates ClusterIP services"
        mmContainer -> serverContainer "Routes inference requests to model server" "gRPC/8001 plaintext"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshServing "Containers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component mmRuntime "RuntimeComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6db33f
                color #ffffff
            }
            element "Component" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Webhook" {
                background #9b59b6
                color #ffffff
            }
        }

        theme default
    }
}
