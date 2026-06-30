workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models via InferenceService / ServingRuntime CRs"

        modelMeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar container that intermediates between ModelMesh and model-server runtimes, handling storage retrieval and protocol adaptation" {
            puller = container "model-serving-puller" "Intercepts ModelRuntime gRPC calls to download model artifacts from remote storage before delegating to runtime adapter" "Go gRPC Service" "Sidecar"
            pullmanLib = container "pullman" "Pluggable storage provider framework with client caching — supports S3, GCS, Azure Blob, HTTP, PVC" "Go Library"
            tritonAdapter = container "triton-adapter" "Translates ModelRuntime gRPC to Triton gRPC API; Keras-to-TF conversion" "Go gRPC Service" "Sidecar"
            mlserverAdapter = container "mlserver-adapter" "Translates ModelRuntime gRPC to MLServer gRPC API" "Go gRPC Service" "Sidecar"
            ovmsAdapter = container "ovms-adapter" "Translates ModelRuntime gRPC to OVMS HTTP REST API; actor-pattern batched config reloads" "Go gRPC Service" "Sidecar"
            torchserveAdapter = container "torchserve-adapter" "Translates ModelRuntime gRPC to TorchServe management/inference gRPC APIs" "Go gRPC Service" "Sidecar"
            tfPbScript = container "tf_pb.py" "Converts Keras H5 models to TensorFlow SavedModel format" "Python Script"

            puller -> pullmanLib "Uses for model downloads"
            puller -> tritonAdapter "Delegates model lifecycle" "gRPC/8085 plaintext"
            puller -> mlserverAdapter "Delegates model lifecycle" "gRPC/8085 plaintext"
            puller -> ovmsAdapter "Delegates model lifecycle" "gRPC/8085 plaintext"
            puller -> torchserveAdapter "Delegates model lifecycle" "gRPC/8085 plaintext"
            tritonAdapter -> tfPbScript "Keras H5 to TF conversion" "exec subprocess"
        }

        modelMesh = softwareSystem "ModelMesh" "Intelligent model serving orchestration — manages model placement, scaling, and lifecycle across pods" "Internal RHOAI"
        modelMeshServing = softwareSystem "modelmesh-serving" "Defines ServingRuntime CRs and configures model-serving-config ConfigMap" "Internal RHOAI"

        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance multi-framework inference runtime" "External Runtime"
        mlserver = softwareSystem "Seldon MLServer" "Multi-model inference server for scikit-learn, XGBoost, LightGBM, etc." "External Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel inference runtime optimized for OpenVINO and ONNX models" "External Runtime"
        torchserve = softwareSystem "TorchServe" "PyTorch model serving framework" "External Runtime"

        s3 = softwareSystem "S3 / IBM COS" "Object storage for model artifacts" "External Storage"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for model artifacts" "External Storage"
        azure = softwareSystem "Azure Blob Storage" "Cloud object storage for model artifacts" "External Storage"
        httpEndpoint = softwareSystem "HTTP(S) Endpoints" "Generic HTTP model artifact servers" "External Storage"

        # System-level relationships
        dataScientist -> modelMeshServing "Creates ServingRuntime / InferenceService CRs"
        modelMesh -> modelMeshRuntimeAdapter "Calls LoadModel/UnloadModel/RuntimeStatus" "gRPC/8084"
        modelMeshServing -> modelMeshRuntimeAdapter "References container image in ServingRuntime CR"

        modelMeshRuntimeAdapter -> triton "Triton adapter calls runtime" "gRPC/8001"
        modelMeshRuntimeAdapter -> mlserver "MLServer adapter calls runtime" "gRPC/8001"
        modelMeshRuntimeAdapter -> ovms "OVMS adapter calls runtime" "HTTP/8001"
        modelMeshRuntimeAdapter -> torchserve "TorchServe adapter calls runtime" "gRPC/7071,7070"

        modelMeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443 TLS 1.2+ Static credentials"
        modelMeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443 TLS 1.2+ SA JSON"
        modelMeshRuntimeAdapter -> azure "Downloads model artifacts" "HTTPS/443 TLS 1.2+ Service principal"
        modelMeshRuntimeAdapter -> httpEndpoint "Downloads model artifacts" "HTTP(S) Optional TLS+mTLS"
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
            element "External Runtime" {
                background #bd10e0
                color #ffffff
            }
            element "External Storage" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
