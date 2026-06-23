workspace {
    model {
        datascientist = person "Data Scientist" "Deploys ML models for inference via ModelMesh"
        mlops = person "MLOps Engineer" "Configures model serving runtimes and storage credentials"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform that manages model lifecycle across inference runtimes" {
            modelmesh = container "ModelMesh Controller" "Orchestrates model placement, routing, and lifecycle across serving pods" "Go Service"

            runtimeAdapter = container "modelmesh-runtime-adapter" "Sidecar that downloads models and adapts them for specific serving runtimes" "Go Sidecar Container" {
                puller = component "model-serving-puller" "Downloads model artifacts from cloud storage, forwards load/unload to adapter" "Go gRPC Service, port 8084"
                pullmanLib = component "pullman" "Pluggable storage provider framework (S3, GCS, Azure, HTTP, PVC)" "Go Library"
                tritonAdapter = component "triton-adapter" "Adapts ModelRuntime gRPC to Triton GRPCInferenceService" "Go gRPC Service, port 8085"
                mlserverAdapter = component "mlserver-adapter" "Adapts ModelRuntime gRPC to MLServer GRPCInferenceService" "Go gRPC Service, port 8085"
                ovmsAdapter = component "ovms-adapter" "Adapts ModelRuntime gRPC to OVMS HTTP REST API with actor-pattern batching" "Go gRPC Service, port 8085"
                torchserveAdapter = component "torchserve-adapter" "Adapts ModelRuntime gRPC to TorchServe management/inference APIs" "Go gRPC Service, port 8085"

                puller -> pullmanLib "Uses for model downloads"
                puller -> tritonAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
                puller -> mlserverAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
                puller -> ovmsAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
                puller -> torchserveAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext"
            }
        }

        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference runtime for multiple ML frameworks" "Runtime"
        mlserver = softwareSystem "Seldon MLServer" "Inference runtime for scikit-learn, XGBoost, LightGBM, MLlib" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel inference runtime optimized for OpenVINO IR models" "Runtime"
        torchserve = softwareSystem "PyTorch TorchServe" "Model serving runtime for PyTorch models (.mar archives)" "Runtime"

        s3 = softwareSystem "S3-compatible Storage" "Object storage for model artifacts (AWS S3, IBM COS, MinIO)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for model artifacts" "External"
        azure = softwareSystem "Azure Blob Storage" "Object storage for model artifacts" "External"
        httpStorage = softwareSystem "HTTP/HTTPS Endpoints" "Arbitrary HTTP endpoints serving model artifacts" "External"

        k8sSecrets = softwareSystem "Kubernetes Secrets" "Stores cloud storage credentials mounted at /storage-config" "Infrastructure"
        pvcStorage = softwareSystem "PVC Storage" "Persistent Volume Claims for pre-provisioned models" "Infrastructure"

        # Relationships
        datascientist -> modelmeshServing "Deploys models via InferenceService CR"
        mlops -> k8sSecrets "Configures storage credentials"

        modelmesh -> runtimeAdapter "Sends model lifecycle commands" "gRPC/8084 plaintext"

        runtimeAdapter -> triton "Loads/unloads models" "gRPC/8001 plaintext localhost"
        runtimeAdapter -> mlserver "Loads/unloads models" "gRPC/8001 plaintext localhost"
        runtimeAdapter -> ovms "Loads/unloads models via config reload" "HTTP/8001 plaintext localhost"
        runtimeAdapter -> torchserve "Registers/unregisters models" "gRPC/7071 plaintext localhost"

        runtimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443 TLS 1.2+ AWS IAM"
        runtimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443 TLS 1.2+ GCP SA JWT"
        runtimeAdapter -> azure "Downloads model artifacts" "HTTPS/443 TLS 1.2+ Service Principal"
        runtimeAdapter -> httpStorage "Downloads model artifacts" "HTTP/HTTPS Optional TLS"

        runtimeAdapter -> k8sSecrets "Reads storage credentials" "Volume mount /storage-config"
        runtimeAdapter -> pvcStorage "Symlinks pre-provisioned models" "Volume mount /pvc_mounts"
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

        component runtimeAdapter "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #5b9bd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
