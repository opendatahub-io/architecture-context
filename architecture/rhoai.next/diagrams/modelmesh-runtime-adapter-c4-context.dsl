workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models via InferenceService CRs"
        platformAdmin = person "Platform Admin" "Configures storage credentials and runtime images"

        modelMeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar container providing model downloading and runtime-specific adapter logic for ML inference engines" {
            puller = container "model-serving-puller" "Downloads ML models from cloud storage, proxies gRPC ModelRuntime between ModelMesh and adapters" "Go gRPC Service (sidecar)" "sidecar"
            pullmanLib = container "pullman" "Unified storage provider abstraction with client caching (1h TTL)" "Go Library"
            tritonAdapter = container "triton-adapter" "Adapts ModelMesh lifecycle to Triton gRPC repository API, generates config.pbtxt" "Go gRPC Service (sidecar)" "adapter"
            mlserverAdapter = container "mlserver-adapter" "Adapts ModelMesh lifecycle to MLServer gRPC API, generates model-settings.json" "Go gRPC Service (sidecar)" "adapter"
            ovmsAdapter = container "ovms-adapter" "Adapts ModelMesh lifecycle to OVMS HTTP REST API with actor-pattern batch processor" "Go gRPC Service (sidecar)" "adapter"
            torchserveAdapter = container "torchserve-adapter" "Adapts ModelMesh lifecycle to TorchServe gRPC Management API" "Go gRPC Service (sidecar)" "adapter"
            tfConverter = container "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format" "Python 3.11 Script"

            puller -> pullmanLib "Uses for storage operations"
            puller -> tritonAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            puller -> mlserverAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            puller -> ovmsAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            puller -> torchserveAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            tritonAdapter -> tfConverter "Keras-to-TF conversion" "subprocess exec"
        }

        modelMesh = softwareSystem "ModelMesh (modelmesh-serving)" "Intelligent model routing and placement controller" "Internal RHOAI"
        tritonRuntime = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference runtime" "Inference Runtime"
        mlserverRuntime = softwareSystem "SeldonIO MLServer" "Python-based inference runtime" "Inference Runtime"
        ovmsRuntime = softwareSystem "OpenVINO Model Server" "Intel-optimized inference runtime" "Inference Runtime"
        torchserveRuntime = softwareSystem "PyTorch TorchServe" "PyTorch model serving runtime" "Inference Runtime"
        s3Storage = softwareSystem "AWS S3 / IBM COS" "S3-compatible object storage for model artifacts" "External Cloud"
        gcsStorage = softwareSystem "Google Cloud Storage" "Google object storage for model artifacts" "External Cloud"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External Cloud"
        k8sSecrets = softwareSystem "Kubernetes Secrets" "Stores cloud storage credentials" "Kubernetes"

        modelMesh -> modelMeshRuntimeAdapter "Sends model lifecycle commands" "gRPC/8084"
        modelMeshRuntimeAdapter -> tritonRuntime "Manages Triton models" "gRPC/8001"
        modelMeshRuntimeAdapter -> mlserverRuntime "Manages MLServer models" "gRPC/8001"
        modelMeshRuntimeAdapter -> ovmsRuntime "Manages OVMS models" "HTTP/8001"
        modelMeshRuntimeAdapter -> torchserveRuntime "Manages TorchServe models" "gRPC/7071, 7070"
        modelMeshRuntimeAdapter -> s3Storage "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelMeshRuntimeAdapter -> gcsStorage "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelMeshRuntimeAdapter -> azureStorage "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        k8sSecrets -> modelMeshRuntimeAdapter "Provides storage credentials" "Volume mount at /storage-config"

        platformAdmin -> k8sSecrets "Configures storage credentials"
        dataScientist -> modelMesh "Deploys models (InferenceService CR)"
    }

    views {
        systemContext modelMeshRuntimeAdapter "SystemContext" {
            include *
            autoLayout
        }

        container modelMeshRuntimeAdapter "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "Inference Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #e74c3c
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "adapter" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
