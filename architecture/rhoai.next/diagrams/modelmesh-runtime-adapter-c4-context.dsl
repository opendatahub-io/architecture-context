workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models via ModelMesh Serving"
        platformAdmin = person "Platform Admin" "Configures storage credentials and runtime settings"

        modelmeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar container image with model puller and runtime-specific adapters for ML inference engines" {
            puller = container "model-serving-puller" "Downloads ML models from cloud storage, proxies gRPC between ModelMesh and runtime adapters" "Go gRPC Service" "Sidecar"
            pullmanLib = container "pullman" "Unified storage provider abstraction with client caching (1hr TTL)" "Go Library"
            tritonAdapter = container "triton-adapter" "Adapts ModelMesh lifecycle to NVIDIA Triton gRPC API, generates config.pbtxt" "Go gRPC Service" "Sidecar"
            mlserverAdapter = container "mlserver-adapter" "Adapts ModelMesh lifecycle to SeldonIO MLServer gRPC API, generates model-settings.json" "Go gRPC Service" "Sidecar"
            ovmsAdapter = container "ovms-adapter" "Adapts ModelMesh lifecycle to OVMS HTTP REST API with actor-pattern batch processing" "Go gRPC Service" "Sidecar"
            torchserveAdapter = container "torchserve-adapter" "Adapts ModelMesh lifecycle to TorchServe gRPC Management API" "Go gRPC Service" "Sidecar"
            tfConvert = container "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format" "Python 3.11 Script"

            puller -> pullmanLib "Uses for storage abstraction"
            puller -> tritonAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext localhost"
            puller -> mlserverAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext localhost"
            puller -> ovmsAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext localhost"
            puller -> torchserveAdapter "Forwards LoadModel/UnloadModel" "gRPC/8085 plaintext localhost"
            tritonAdapter -> tfConvert "Subprocess exec for .h5 conversion"
        }

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator managing multi-model serving infrastructure" "Internal RHOAI"
        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance ML inference engine" "Runtime"
        mlserver = softwareSystem "SeldonIO MLServer" "Python-based ML inference server" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel inference engine optimized for OpenVINO" "Runtime"
        torchserve = softwareSystem "PyTorch TorchServe" "PyTorch model serving framework" "Runtime"

        s3 = softwareSystem "AWS S3 / IBM COS" "Object storage for ML model artifacts" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for ML model artifacts" "External Cloud"
        azureBlob = softwareSystem "Azure Blob Storage" "Object storage for ML model artifacts" "External Cloud"
        httpEndpoint = softwareSystem "HTTP/HTTPS Endpoints" "Custom model artifact hosting" "External"
        k8sSecrets = softwareSystem "Kubernetes Secrets" "Storage credential management" "Platform"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator configuring runtime adapter image" "Internal RHOAI"

        modelmeshServing -> modelmeshRuntimeAdapter "Sends LoadModel/UnloadModel" "gRPC/8084 localhost"
        modelmeshRuntimeAdapter -> triton "Repository management" "gRPC/8001 localhost"
        modelmeshRuntimeAdapter -> mlserver "Repository management" "gRPC/8001 localhost"
        modelmeshRuntimeAdapter -> ovms "Config reload" "HTTP/8001 localhost"
        modelmeshRuntimeAdapter -> torchserve "Register/Unregister models" "gRPC/7071 localhost"
        modelmeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443 TLS 1.2+ AccessKey"
        modelmeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443 TLS 1.2+ ServiceAccount"
        modelmeshRuntimeAdapter -> azureBlob "Downloads model artifacts" "HTTPS/443 TLS 1.2+ ServicePrincipal"
        modelmeshRuntimeAdapter -> httpEndpoint "Downloads model artifacts" "HTTP(S) Optional TLS"
        k8sSecrets -> modelmeshRuntimeAdapter "Mounts storage credentials" "Volume mount at /storage-config"
        rhoaiOperator -> modelmeshServing "Configures storageHelperImage" "ConfigMap"

        dataScientist -> modelmeshServing "Deploys InferenceService"
        platformAdmin -> k8sSecrets "Configures storage credentials"
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
                background #999999
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
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #e8e8e8
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
