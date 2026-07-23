workspace {
    model {
        datascientist = person "Data Scientist" "Deploys ML models for inference via ModelMesh"
        mlops = person "MLOps Engineer" "Configures model serving infrastructure and storage backends"

        modelmeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Multi-binary sidecar that bridges ModelMesh model lifecycle with ML inference runtimes and pulls model artifacts from cloud storage" {
            puller = container "model-serving-puller" "Downloads model artifacts from cloud storage and proxies ModelRuntime gRPC calls to downstream adapter" "Go Service (sidecar), gRPC 8084/TCP"
            pullmanLib = container "PullMan Library" "Plugin-based storage provider abstraction with client caching for S3, GCS, Azure, HTTP, PVC" "Go Library"
            tritonAdapter = container "model-mesh-triton-adapter" "Adapts model layouts and manages lifecycle on NVIDIA Triton via gRPC" "Go Service (sidecar), gRPC 8085/TCP"
            mlserverAdapter = container "model-mesh-mlserver-adapter" "Adapts model layouts and manages lifecycle on Seldon MLServer via gRPC" "Go Service (sidecar), gRPC 8085/TCP"
            ovmsAdapter = container "model-mesh-ovms-adapter" "Adapts model layouts and manages lifecycle on OVMS via REST HTTP (actor-based batching)" "Go Service (sidecar), gRPC 8085/TCP"
            torchserveAdapter = container "model-mesh-torchserve-adapter" "Adapts model layouts and manages lifecycle on TorchServe via gRPC management API" "Go Service (sidecar), gRPC 8085/TCP"
            kerasConverter = container "tf_pb.py" "Converts Keras H5 models to TensorFlow SavedModel format" "Python 3.11 Script"
        }

        modelmesh = softwareSystem "ModelMesh" "Intelligent model routing and placement controller" "Internal RHOAI"
        modelmeshServing = softwareSystem "modelmesh-serving (Controller)" "Kubernetes operator managing ModelMesh ServingRuntimes and configuration" "Internal RHOAI"

        triton = softwareSystem "NVIDIA Triton Inference Server" "Multi-framework model inference server" "Runtime"
        mlserver = softwareSystem "Seldon MLServer" "ML inference server supporting sklearn, XGBoost, LightGBM" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel model inference server optimized for OpenVINO models" "Runtime"
        torchserve = softwareSystem "TorchServe" "PyTorch model serving framework" "Runtime"

        s3 = softwareSystem "S3 / MinIO / IBM COS" "S3-compatible object storage for model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Google cloud object storage for model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure cloud object storage for model artifacts" "External"
        httpSource = softwareSystem "HTTP/HTTPS Model Sources" "Generic HTTP endpoints serving model artifacts" "External"

        kubernetes = softwareSystem "Kubernetes" "Container orchestration, Secrets, PVC management" "Infrastructure"

        # Relationships - System Context
        datascientist -> modelmesh "Deploys InferenceService (via kubectl/Dashboard)"
        mlops -> modelmeshServing "Configures ServingRuntime and storage credentials"
        modelmesh -> modelmeshRuntimeAdapter "Sends LoadModel/UnloadModel RPCs" "gRPC/8084"
        modelmeshServing -> modelmeshRuntimeAdapter "Configures sidecar image via ConfigMap"
        modelmeshRuntimeAdapter -> triton "Manages model lifecycle" "gRPC/8001"
        modelmeshRuntimeAdapter -> mlserver "Manages model lifecycle" "gRPC/8001"
        modelmeshRuntimeAdapter -> ovms "Manages model lifecycle" "HTTP/8001"
        modelmeshRuntimeAdapter -> torchserve "Manages model lifecycle" "gRPC/7071, gRPC/7070"
        modelmeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelmeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelmeshRuntimeAdapter -> azureBlob "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        modelmeshRuntimeAdapter -> httpSource "Downloads model artifacts" "HTTP/HTTPS"
        kubernetes -> modelmeshRuntimeAdapter "Provides Secrets and PVC mounts"

        # Relationships - Container
        puller -> pullmanLib "Uses for storage downloads"
        puller -> tritonAdapter "Proxies LoadModel/UnloadModel after pull" "gRPC/8085 loopback"
        puller -> mlserverAdapter "Proxies LoadModel/UnloadModel after pull" "gRPC/8085 loopback"
        puller -> ovmsAdapter "Proxies LoadModel/UnloadModel after pull" "gRPC/8085 loopback"
        puller -> torchserveAdapter "Proxies LoadModel/UnloadModel after pull" "gRPC/8085 loopback"
        pullmanLib -> s3 "Downloads model artifacts" "HTTPS/443"
        pullmanLib -> gcs "Downloads model artifacts" "HTTPS/443"
        pullmanLib -> azureBlob "Downloads model artifacts" "HTTPS/443"
        pullmanLib -> httpSource "Downloads model artifacts" "HTTP/HTTPS"
        tritonAdapter -> triton "RepositoryModelLoad/Unload" "gRPC/8001"
        tritonAdapter -> kerasConverter "Keras H5 to SavedModel" "subprocess"
        mlserverAdapter -> mlserver "RepositoryModelLoad/Unload" "gRPC/8001"
        ovmsAdapter -> ovms "Config reload + status poll" "HTTP/8001"
        torchserveAdapter -> torchserve "RegisterModel/UnregisterModel" "gRPC/7071"
        modelmesh -> puller "LoadModel/UnloadModel/RuntimeStatus" "gRPC/8084"
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
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
