workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via ModelMesh"

        modelmeshRuntimeAdapter = softwareSystem "ModelMesh Runtime Adapter" "Sidecar container that bridges ModelMesh protocol to runtime-specific APIs and handles model artifact retrieval from cloud storage" {
            puller = container "model-serving-puller" "Downloads model artifacts from cloud storage and proxies load/unload gRPC calls to the runtime adapter" "Go gRPC Service :8084"
            tritonAdapter = container "triton-adapter" "Adapts ModelMesh gRPC protocol to NVIDIA Triton model repository management API with Keras-to-TF conversion" "Go gRPC Service :8085"
            ovmsAdapter = container "ovms-adapter" "Adapts ModelMesh gRPC protocol to OpenVINO Model Server REST API with batched config reload" "Go gRPC Service :8085"
            mlserverAdapter = container "mlserver-adapter" "Adapts ModelMesh gRPC protocol to Seldon MLServer gRPC API with model-settings.json generation" "Go gRPC Service :8085"
            torchserveAdapter = container "torchserve-adapter" "Adapts ModelMesh gRPC protocol to TorchServe management and inference gRPC APIs" "Go gRPC Service :8085"
            pullmanLib = component "pullman" "Pluggable storage provider framework with S3, GCS, Azure, HTTP, and PVC backends" "Go Library"
            tfConvert = component "tf_pb.py" "Converts Keras .h5 models to TensorFlow SavedModel format" "Python Script"
        }

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform that manages model lifecycle across heterogeneous runtimes" "Internal Platform"
        modelmeshController = softwareSystem "ModelMesh Controller" "Kubernetes operator managing ModelMesh deployments and runtime configurations" "Internal Platform"

        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference server supporting multiple ML frameworks" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel-optimized model server for OpenVINO IR and ONNX models" "Runtime"
        mlserver = softwareSystem "Seldon MLServer" "Python-based inference server supporting sklearn, xgboost, lightgbm, mllib" "Runtime"
        torchserve = softwareSystem "PyTorch TorchServe" "PyTorch model serving framework with management and inference APIs" "Runtime"

        s3 = softwareSystem "S3 / IBM COS" "S3-compatible object storage for model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "GCS object storage for model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External"
        httpServer = softwareSystem "HTTP/HTTPS Server" "HTTP-accessible model artifact server" "External"

        # Relationships
        modelmeshServing -> modelmeshRuntimeAdapter "Sends LoadModel/UnloadModel/RuntimeStatus gRPC calls" "gRPC/8084,8085"
        modelmeshController -> modelmeshRuntimeAdapter "References via model-serving-config ConfigMap storageHelperImage field" "ConfigMap"

        puller -> pullmanLib "Uses for model artifact download"
        tritonAdapter -> pullmanLib "Uses when embedded puller enabled"
        ovmsAdapter -> pullmanLib "Uses when embedded puller enabled"
        mlserverAdapter -> pullmanLib "Uses when embedded puller enabled"
        torchserveAdapter -> pullmanLib "Uses when embedded puller enabled"
        tritonAdapter -> tfConvert "Invokes for Keras model conversion"

        puller -> tritonAdapter "Forwards load/unload after pulling" "gRPC/8085"
        puller -> ovmsAdapter "Forwards load/unload after pulling" "gRPC/8085"
        puller -> mlserverAdapter "Forwards load/unload after pulling" "gRPC/8085"
        puller -> torchserveAdapter "Forwards load/unload after pulling" "gRPC/8085"

        tritonAdapter -> triton "Model repository management" "gRPC/8001"
        ovmsAdapter -> ovms "Model config management" "HTTP/8001"
        mlserverAdapter -> mlserver "Model repository management" "gRPC/8001"
        torchserveAdapter -> torchserve "Model registration and health check" "gRPC/7071,7070"

        modelmeshRuntimeAdapter -> s3 "Downloads model artifacts" "HTTPS/443"
        modelmeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS/443"
        modelmeshRuntimeAdapter -> azureBlob "Downloads model artifacts" "HTTPS/443"
        modelmeshRuntimeAdapter -> httpServer "Downloads model artifacts" "HTTPS/443"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
