workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models for inference via ModelMesh"
        platformAdmin = person "Platform Admin" "Configures storage credentials and ModelMesh Serving"

        modelMeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar container providing model storage retrieval and runtime-specific adaptation for ModelMesh Serving pods" {
            puller = container "model-serving-puller" "Downloads ML models from cloud storage providers and forwards load/unload requests to runtime adapters" "Go gRPC Service (8084/TCP)"
            pullman = container "pullman" "Pluggable storage provider framework supporting S3, GCS, Azure, HTTP(S), and PVC backends" "Go Library"
            tritonAdapter = container "triton-adapter" "Adapts ModelMesh ModelRuntime protocol to NVIDIA Triton Inference Server gRPC API" "Go gRPC Service (8085/TCP)"
            mlserverAdapter = container "mlserver-adapter" "Adapts ModelMesh ModelRuntime protocol to Seldon MLServer gRPC API" "Go gRPC Service (8085/TCP)"
            ovmsAdapter = container "ovms-adapter" "Adapts ModelMesh ModelRuntime protocol to OpenVINO Model Server HTTP REST API" "Go gRPC Service (8085/TCP)"
            torchserveAdapter = container "torchserve-adapter" "Adapts ModelMesh ModelRuntime protocol to TorchServe gRPC Management/Inference APIs" "Go gRPC Service (8085/TCP)"
            kerasConverter = container "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format for Triton" "Python 3.11 + TensorFlow 2.19"

            puller -> pullman "Uses for storage operations"
            puller -> tritonAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            puller -> mlserverAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            puller -> ovmsAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            puller -> torchserveAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            tritonAdapter -> kerasConverter "Keras-to-TF conversion" "subprocess"
        }

        modelMeshServing = softwareSystem "ModelMesh Serving" "Controller managing model lifecycle and inference routing" "Internal RHOAI"
        tritonServer = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference runtime for multi-framework models" "Runtime"
        mlserver = softwareSystem "Seldon MLServer" "Inference runtime for sklearn, xgboost, lightgbm models" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Inference runtime for ONNX and OpenVINO models" "Runtime"
        torchserve = softwareSystem "TorchServe" "Inference runtime for PyTorch MAR models" "Runtime"

        s3 = softwareSystem "AWS S3 / IBM COS" "S3-compatible object storage for model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Google cloud object storage for model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External"
        httpRepos = softwareSystem "HTTP(S) Repositories" "Generic HTTP endpoints hosting model files" "External"
        k8sSecrets = softwareSystem "Kubernetes Secrets" "Storage credentials mounted as volumes" "Platform"
        k8sPVC = softwareSystem "Kubernetes PVC" "Persistent volume claims for local model storage" "Platform"

        modelMeshServing -> modelMeshRuntimeAdapter "Sends LoadModel/UnloadModel/RuntimeStatus RPCs" "gRPC/8084-8085 plaintext"
        modelMeshRuntimeAdapter -> tritonServer "Model load/unload via RepositoryModelLoad" "gRPC/8001 plaintext"
        modelMeshRuntimeAdapter -> mlserver "Model load/unload via RepositoryModelLoad" "gRPC/8001 plaintext"
        modelMeshRuntimeAdapter -> ovms "Config reload for model management" "HTTP/8001 plaintext"
        modelMeshRuntimeAdapter -> torchserve "Model register/unregister" "gRPC/7071 plaintext"
        modelMeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelMeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelMeshRuntimeAdapter -> azureBlob "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelMeshRuntimeAdapter -> httpRepos "Downloads model artifacts" "HTTP(S)/80,443"
        modelMeshRuntimeAdapter -> k8sSecrets "Reads storage credentials" "Volume mount"
        modelMeshRuntimeAdapter -> k8sPVC "Reads model files via symlinks" "Volume mount"

        dataScientist -> modelMeshServing "Deploys models (creates InferenceService)" "kubectl / API"
        platformAdmin -> k8sSecrets "Configures storage credentials" "kubectl"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #2ecc71
                color #ffffff
            }
            element "Platform" {
                background #8e44ad
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
