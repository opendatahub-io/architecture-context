workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and manages ML models via ModelMesh"

        modelmeshRuntimeAdapter = softwareSystem "modelmesh-runtime-adapter" "gRPC sidecar adapters for Triton, MLServer, and TorchServe model serving runtimes, plus model artifact puller" {
            tritonAdapter = container "model-mesh-triton-adapter" "Translates mmesh.ModelRuntime to Triton GRPCInferenceService" "Go Binary"
            mlserverAdapter = container "model-mesh-mlserver-adapter" "Translates mmesh.ModelRuntime to MLServer GRPCInferenceService" "Go Binary"
            torchserveAdapter = container "model-mesh-torchserve-adapter" "Translates mmesh.ModelRuntime to TorchServe Management/Inference APIs" "Go Binary"
            servingPuller = container "model-serving-puller" "Downloads model artifacts from object storage" "Go Binary"
            pullman = container "pullman" "Multi-cloud storage download library (Azure, GCS, S3)" "Go Library"
        }

        modelmesh = softwareSystem "ModelMesh" "Model serving control plane managing model lifecycle" "Internal"
        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference runtime" "External"
        mlserver = softwareSystem "Seldon MLServer" "KFServing V2 compatible inference server" "External"
        torchserve = softwareSystem "PyTorch TorchServe" "PyTorch model serving framework" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Microsoft cloud object storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "Google cloud object storage" "External"
        ibmCos = softwareSystem "IBM Cloud Object Storage" "IBM S3-compatible object storage" "External"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS and network policy enforcement" "External"

        datascientist -> modelmesh "Deploys models via" "kubectl / API"
        modelmesh -> modelmeshRuntimeAdapter "Sends model lifecycle commands" "gRPC (pod-local)"
        modelmeshRuntimeAdapter -> triton "Forwards inference/management calls" "gRPC"
        modelmeshRuntimeAdapter -> mlserver "Forwards inference calls" "gRPC"
        modelmeshRuntimeAdapter -> torchserve "Forwards inference/management calls" "gRPC"
        modelmeshRuntimeAdapter -> azureBlob "Downloads model artifacts" "HTTPS"
        modelmeshRuntimeAdapter -> gcs "Downloads model artifacts" "HTTPS"
        modelmeshRuntimeAdapter -> ibmCos "Downloads model artifacts" "HTTPS"
        istio -> modelmeshRuntimeAdapter "Enforces mTLS and network policies" "Sidecar proxy"

        servingPuller -> pullman "Uses for multi-cloud downloads"
        pullman -> azureBlob "Azure SDK" "HTTPS"
        pullman -> gcs "GCS SDK" "HTTPS"
        pullman -> ibmCos "IBM COS SDK" "HTTPS"
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
            element "Internal" {
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
