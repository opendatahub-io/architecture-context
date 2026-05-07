workspace {
    model {
        mlEngineer = person "ML Engineer" "Deploys and manages ML models via ModelMesh Serving"

        modelMeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar that adapts ModelMesh model lifecycle operations to inference runtime backends and pulls models from cloud storage" {
            tritonAdapter = container "triton-adapter" "Adapts ModelMesh to NVIDIA Triton via gRPC" "Go gRPC Service" "Adapter"
            mlserverAdapter = container "mlserver-adapter" "Adapts ModelMesh to Seldon MLServer via gRPC" "Go gRPC Service" "Adapter"
            ovmsAdapter = container "ovms-adapter" "Adapts ModelMesh to OpenVINO Model Server via HTTP REST" "Go gRPC Service" "Adapter"
            torchserveAdapter = container "torchserve-adapter" "Adapts ModelMesh to TorchServe via gRPC" "Go gRPC Service" "Adapter"
            puller = container "puller" "Downloads model artifacts from cloud storage" "Go gRPC Service" "Puller"
            pullman = container "pullman" "Pluggable storage provider framework (S3, GCS, Azure, HTTP, PVC)" "Go Library" "Library"
            tfConvert = container "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format" "Python Script" "Utility"
        }

        modelMesh = softwareSystem "ModelMesh" "Intelligent model routing and lifecycle orchestration" "Internal"
        modelMeshController = softwareSystem "modelmesh-controller" "Kubernetes operator that deploys and configures ModelMesh Serving pods" "Internal"

        tritonServer = softwareSystem "NVIDIA Triton Inference Server" "High-performance multi-framework inference server" "Runtime"
        mlServer = softwareSystem "Seldon MLServer" "Python ML model inference server (sklearn, xgboost, lightgbm)" "Runtime"
        ovmsServer = softwareSystem "OpenVINO Model Server" "Intel-optimized inference server" "Runtime"
        torchServeServer = softwareSystem "PyTorch TorchServe" "PyTorch model serving framework" "Runtime"

        s3Storage = softwareSystem "S3-compatible Storage" "AWS S3 / IBM Cloud Object Storage for model artifacts" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "GCS buckets for model artifacts" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure containers for model artifacts" "External"
        httpEndpoint = softwareSystem "HTTP Model Endpoint" "Custom HTTP/HTTPS model artifact server" "External"
        pvcStorage = softwareSystem "Kubernetes PVC" "Local persistent volume for model files" "External"

        # Relationships
        modelMeshController -> modelMeshRuntimeAdapter "Deploys as sidecar container (storageHelperImage)" "Container Image Reference"

        modelMesh -> modelMeshRuntimeAdapter "Calls mmesh.ModelRuntime for model lifecycle" "gRPC/8085 localhost plaintext"

        tritonAdapter -> tritonServer "RepositoryModelLoad/Unload" "gRPC/8001 localhost"
        mlserverAdapter -> mlServer "RepositoryModelLoad/Unload" "gRPC/8001 localhost"
        ovmsAdapter -> ovmsServer "Config query and reload" "HTTP/8001 localhost"
        torchserveAdapter -> torchServeServer "RegisterModel/UnregisterModel" "gRPC/7071 localhost"

        puller -> pullman "Uses storage providers"
        tritonAdapter -> tfConvert "Keras .h5 conversion" "subprocess"

        pullman -> s3Storage "Downloads model artifacts" "HTTPS/443 TLS 1.2+ AWS Key Auth"
        pullman -> gcsStorage "Downloads model artifacts" "HTTPS/443 TLS 1.2+ SA OAuth2"
        pullman -> azureStorage "Downloads model artifacts" "HTTPS/443 TLS 1.2+ Connection String"
        pullman -> httpEndpoint "Downloads model artifacts" "HTTP/HTTPS configurable mTLS"
        pullman -> pvcStorage "Symlinks to mounted models" "Filesystem"
    }

    views {
        systemContext modelMeshRuntimeAdapter "SystemContext" {
            include *
            autoLayout
            description "System context showing ModelMesh Runtime Adapter in the broader ModelMesh Serving ecosystem"
        }

        container modelMeshRuntimeAdapter "Containers" {
            include *
            autoLayout
            description "Internal structure of the ModelMesh Runtime Adapter sidecar"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Runtime" {
                background #e8e8e8
                color #333333
            }
            element "Adapter" {
                background #4a90e2
                color #ffffff
            }
            element "Puller" {
                background #50c878
                color #ffffff
            }
            element "Library" {
                background #50c878
                color #ffffff
            }
            element "Utility" {
                background #f5a623
                color #333333
            }
        }
    }
}
