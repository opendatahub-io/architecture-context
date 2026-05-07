workspace {
    model {
        datascientist = person "Data Scientist" "Deploys ML models for inference via ModelMesh"
        admin = person "Platform Admin" "Configures storage credentials and model serving infrastructure"

        modelmeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar service that retrieves model artifacts from cloud storage and adapts ModelMesh protocol to runtime-specific APIs" {
            puller = container "model-serving-puller" "Downloads model artifacts from cloud storage backends (S3, GCS, Azure, HTTP, PVC) and proxies load/unload requests to runtime adapters" "Go Service, gRPC :8084"
            pullmanLib = container "pullman" "Pluggable storage provider framework with provider registration, client caching (1h TTL), and secure path joining" "Go Library"
            tritonAdapter = container "model-mesh-triton-adapter" "Adapts mmesh.ModelRuntime to Triton gRPC API with model layout transformation, config.pbtxt generation, and Keras-to-TF conversion" "Go Service, gRPC :8085"
            ovmsAdapter = container "model-mesh-ovms-adapter" "Adapts mmesh.ModelRuntime to OVMS REST API with actor-pattern batched config reload (100ms-3s window)" "Go Service, gRPC :8085"
            mlserverAdapter = container "model-mesh-mlserver-adapter" "Adapts mmesh.ModelRuntime to MLServer gRPC API with model-settings.json generation and implementation class mapping" "Go Service, gRPC :8085"
            torchserveAdapter = container "model-mesh-torchserve-adapter" "Adapts mmesh.ModelRuntime to TorchServe gRPC management/inference APIs with mmconfig.properties generation" "Go Service, gRPC :8085"
            tfConverter = container "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format at model-load time" "Python 3.11, TensorFlow 2.19"

            puller -> pullmanLib "Uses for storage operations"
            puller -> tritonAdapter "Forward LoadModel/UnloadModel" "gRPC :8085 plaintext"
            puller -> ovmsAdapter "Forward LoadModel/UnloadModel" "gRPC :8085 plaintext"
            puller -> mlserverAdapter "Forward LoadModel/UnloadModel" "gRPC :8085 plaintext"
            puller -> torchserveAdapter "Forward LoadModel/UnloadModel" "gRPC :8085 plaintext"
            tritonAdapter -> tfConverter "Invokes for .h5 model conversion"
        }

        modelmesh = softwareSystem "ModelMesh" "Intelligent model routing and caching layer that manages model lifecycle across pods" "Internal RHOAI"
        modelmeshController = softwareSystem "ModelMesh Controller" "Kubernetes operator managing ModelMesh Serving deployments and ServingRuntime resources" "Internal RHOAI"

        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance ML inference server supporting multiple frameworks" "Co-located Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel's ML inference server optimized for OpenVINO IR models" "Co-located Runtime"
        mlserver = softwareSystem "Seldon MLServer" "ML inference server supporting scikit-learn, XGBoost, LightGBM, MLlib" "Co-located Runtime"
        torchserve = softwareSystem "PyTorch TorchServe" "PyTorch's production model serving framework" "Co-located Runtime"

        s3 = softwareSystem "S3 / IBM COS" "S3-compatible object storage for model artifacts" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Google's object storage for model artifacts" "External Cloud"
        azure = softwareSystem "Azure Blob Storage" "Microsoft's object storage for model artifacts" "External Cloud"
        httpServer = softwareSystem "HTTP/HTTPS Server" "Generic HTTP endpoint serving model artifacts" "External"

        k8sSecrets = softwareSystem "Kubernetes Secrets" "Stores cloud storage credentials mounted into pods" "Kubernetes"

        datascientist -> modelmesh "Deploys InferenceService" "kubectl / API"
        admin -> k8sSecrets "Provisions storage-config Secret" "kubectl"

        modelmesh -> modelmeshRuntimeAdapter "Calls mmesh.ModelRuntime (loadModel, unloadModel, runtimeStatus)" "gRPC :8084/:8085 plaintext"
        modelmeshController -> modelmeshRuntimeAdapter "References via storageHelperImage in model-serving-config ConfigMap" "ConfigMap"

        modelmeshRuntimeAdapter -> triton "Model repository management" "gRPC :8001 plaintext"
        modelmeshRuntimeAdapter -> ovms "Model config management" "HTTP :8001 plaintext"
        modelmeshRuntimeAdapter -> mlserver "Model repository management" "gRPC :8001 plaintext"
        modelmeshRuntimeAdapter -> torchserve "Model registration/management" "gRPC :7071/:7070 plaintext"

        modelmeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS :443 TLS 1.2+"
        modelmeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS :443 TLS 1.2+"
        modelmeshRuntimeAdapter -> azure "Downloads model artifacts" "HTTPS :443 TLS 1.2+"
        modelmeshRuntimeAdapter -> httpServer "Downloads model artifacts" "HTTP/HTTPS :80/:443"

        k8sSecrets -> modelmeshRuntimeAdapter "Mounted at /storage-config" "Volume mount"
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
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Co-located Runtime" {
                background #e8e8e8
                color #333333
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
