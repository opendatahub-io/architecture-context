workspace {
    model {
        mlEngineer = person "ML Engineer" "Deploys and manages ML models via ModelMesh"

        modelmeshRuntimeAdapter = softwareSystem "modelmesh-runtime-adapter" "Sidecar that bridges ModelMesh with inference runtimes by translating the ModelRuntime gRPC protocol and pulling model artifacts from storage" {
            puller = container "model-serving-puller" "gRPC proxy that downloads model artifacts from storage and forwards load/unload requests to the runtime adapter" "Go Service (sidecar)"
            tritonAdapter = container "model-mesh-triton-adapter" "Translates ModelRuntime gRPC to Triton GRPCInferenceService API" "Go Service (sidecar)"
            mlserverAdapter = container "model-mesh-mlserver-adapter" "Translates ModelRuntime gRPC to MLServer GRPCInferenceService API" "Go Service (sidecar)"
            ovmsAdapter = container "model-mesh-ovms-adapter" "Translates ModelRuntime gRPC to OpenVINO Model Server GRPCInferenceService API" "Go Service (sidecar)"
            torchserveAdapter = container "model-mesh-torchserve-adapter" "Translates ModelRuntime gRPC to TorchServe Management and Inference gRPC APIs" "Go Service (sidecar)"
            pullman = container "pullman" "Pluggable model storage abstraction with providers for S3, Azure, GCS, HTTP, and PVC" "Go Library"
            tfPb = container "tf_pb.py" "Keras HDF5 to TensorFlow SavedModel converter" "Python Script"
        }

        modelMesh = softwareSystem "ModelMesh" "Model serving orchestrator that manages model lifecycle" "Internal RHOAI"
        modelmeshServing = softwareSystem "modelmesh-serving" "Operator that configures and deploys ModelMesh infrastructure" "Internal RHOAI"

        triton = softwareSystem "Triton Inference Server" "NVIDIA model inference runtime" "External"
        mlserver = softwareSystem "MLServer" "Seldon model inference runtime" "External"
        ovms = softwareSystem "OpenVINO Model Server" "Intel model inference runtime" "External"
        torchserve = softwareSystem "TorchServe" "PyTorch model inference runtime" "External"

        s3 = softwareSystem "S3 / IBM COS" "S3-compatible object storage for model artifacts" "External"
        azure = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Google object storage for model artifacts" "External"
        httpEndpoint = softwareSystem "HTTP/HTTPS Endpoints" "HTTP model artifact sources" "External"

        # Relationships
        modelMesh -> puller "Calls LoadModel/UnloadModel/runtimeStatus" "gRPC/8084 plaintext localhost"
        puller -> pullman "Uses for model downloads"
        puller -> tritonAdapter "Forwards model lifecycle commands" "gRPC/8085 plaintext localhost"
        puller -> mlserverAdapter "Forwards model lifecycle commands" "gRPC/8085 plaintext localhost"
        puller -> ovmsAdapter "Forwards model lifecycle commands" "gRPC/8085 plaintext localhost"
        puller -> torchserveAdapter "Forwards model lifecycle commands" "gRPC/8085 plaintext localhost"

        tritonAdapter -> triton "Delegates load/unload/inference" "gRPC plaintext localhost"
        tritonAdapter -> tfPb "Invokes Keras-to-SavedModel conversion" "Process exec"
        mlserverAdapter -> mlserver "Delegates load/unload/inference" "gRPC plaintext localhost"
        ovmsAdapter -> ovms "Delegates load/unload/inference" "gRPC plaintext localhost"
        torchserveAdapter -> torchserve "Delegates management and inference" "gRPC plaintext localhost"

        pullman -> s3 "Downloads model artifacts" "HTTPS/443 TLS"
        pullman -> azure "Downloads model artifacts" "HTTPS/443 TLS"
        pullman -> gcs "Downloads model artifacts" "HTTPS/443 TLS"
        pullman -> httpEndpoint "Downloads model artifacts" "HTTP(S) optional TLS+mTLS"

        modelmeshServing -> modelmeshRuntimeAdapter "Configures sidecar image via model-serving-config ConfigMap"
        mlEngineer -> modelMesh "Deploys models via InferenceService CR"
    }

    views {
        systemContext modelmeshRuntimeAdapter "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshRuntimeAdapter "Containers" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
