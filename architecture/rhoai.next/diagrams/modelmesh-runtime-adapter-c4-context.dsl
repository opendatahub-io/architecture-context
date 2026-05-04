workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and manages ML models via ModelMesh"
        admin = person "Platform Admin" "Configures model serving infrastructure and storage credentials"

        modelmeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar container that retrieves model artifacts from cloud storage and adapts ModelMesh gRPC protocol to runtime-specific APIs" {
            puller = container "model-serving-puller" "Downloads model artifacts from cloud storage backends and proxies load/unload gRPC calls to the runtime adapter" "Go 1.23 gRPC Service (8084/TCP)"
            tritonAdapter = container "model-mesh-triton-adapter" "Translates ModelMesh protocol to NVIDIA Triton gRPC API with model layout transformation and Keras-to-TF conversion" "Go 1.23 gRPC Service (8085/TCP)"
            ovmsAdapter = container "model-mesh-ovms-adapter" "Translates ModelMesh protocol to OpenVINO Model Server REST API with batched config reload" "Go 1.23 gRPC Service (8085/TCP)"
            mlserverAdapter = container "model-mesh-mlserver-adapter" "Translates ModelMesh protocol to Seldon MLServer gRPC API with model-settings.json generation" "Go 1.23 gRPC Service (8085/TCP)"
            torchserveAdapter = container "model-mesh-torchserve-adapter" "Translates ModelMesh protocol to PyTorch TorchServe gRPC management and inference APIs" "Go 1.23 gRPC Service (8085/TCP)"
            pullmanLib = container "pullman" "Pluggable storage provider framework with S3, GCS, Azure, HTTP, and PVC backends" "Go Library"
            tfConverter = container "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format" "Python 3.11 / TensorFlow 2.19"
        }

        modelmesh = softwareSystem "ModelMesh" "Intelligent model routing and management layer that orchestrates model lifecycle" "Internal RHOAI"
        modelmeshController = softwareSystem "ModelMesh Controller" "Kubernetes operator that manages ModelMesh Serving deployments and references runtime adapter image" "Internal RHOAI"
        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference runtime supporting multiple ML frameworks" "External"
        ovms = softwareSystem "OpenVINO Model Server" "Intel-optimized inference runtime for OpenVINO and ONNX models" "External"
        mlserver = softwareSystem "Seldon MLServer" "Inference runtime supporting scikit-learn, XGBoost, LightGBM models" "External"
        torchserve = softwareSystem "PyTorch TorchServe" "Inference runtime for PyTorch models with management API" "External"
        s3 = softwareSystem "S3 / IBM COS" "S3-compatible object storage for model artifacts" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "GCS object storage for model artifacts" "External Cloud"
        azure = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External Cloud"
        k8sSecrets = softwareSystem "Kubernetes Secrets" "Stores cloud storage credentials mounted into pods" "Infrastructure"

        # Relationships
        datascientist -> modelmesh "Deploys models via InferenceService"
        admin -> k8sSecrets "Configures storage credentials"

        modelmesh -> modelmeshRuntimeAdapter "Calls mmesh.ModelRuntime gRPC" "gRPC/8084 or 8085 plaintext"
        modelmeshController -> modelmeshRuntimeAdapter "References container image" "ConfigMap storageHelperImage"

        modelmeshRuntimeAdapter -> triton "Model repository management" "gRPC/8001 plaintext"
        modelmeshRuntimeAdapter -> ovms "Model config management" "HTTP/8001 plaintext"
        modelmeshRuntimeAdapter -> mlserver "Model repository management" "gRPC/8001 plaintext"
        modelmeshRuntimeAdapter -> torchserve "Model registration and health" "gRPC/7071+7070 plaintext"

        modelmeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443 TLS 1.2+ static credentials"
        modelmeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443 TLS 1.2+ SA credentials"
        modelmeshRuntimeAdapter -> azure "Downloads model artifacts" "HTTPS/443 TLS 1.2+ SP credentials"

        k8sSecrets -> modelmeshRuntimeAdapter "Provides credentials via volume mount" "/storage-config"

        # Container-level relationships
        puller -> pullmanLib "Uses for storage operations"
        puller -> tritonAdapter "Forwards load/unload" "gRPC/8085 plaintext"
        puller -> ovmsAdapter "Forwards load/unload" "gRPC/8085 plaintext"
        puller -> mlserverAdapter "Forwards load/unload" "gRPC/8085 plaintext"
        puller -> torchserveAdapter "Forwards load/unload" "gRPC/8085 plaintext"

        tritonAdapter -> tfConverter "Keras-to-TF conversion" "subprocess"

        pullmanLib -> s3 "Downloads model artifacts" "HTTPS/443"
        pullmanLib -> gcs "Downloads model artifacts" "HTTPS/443"
        pullmanLib -> azure "Downloads model artifacts" "HTTPS/443"
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
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
        }
    }
}
