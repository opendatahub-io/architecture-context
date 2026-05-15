workspace {
    model {
        datascientist = person "Data Scientist" "Deploys ML models via ModelMesh Serving"
        mlops = person "MLOps Engineer" "Configures storage backends and runtime settings"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform with intelligent model placement" {
            modelmesh = container "ModelMesh" "Model placement and routing framework" "Go"
            puller = container "model-serving-puller" "Downloads model artifacts from cloud storage to local pod filesystem" "Go gRPC Service (sidecar)"
            tritonAdapter = container "model-mesh-triton-adapter" "Adapts ModelMesh interface to NVIDIA Triton" "Go gRPC Service (sidecar)"
            ovmsAdapter = container "model-mesh-ovms-adapter" "Adapts ModelMesh interface to OpenVINO Model Server" "Go gRPC Service (sidecar)"
            mlserverAdapter = container "model-mesh-mlserver-adapter" "Adapts ModelMesh interface to Seldon MLServer" "Go gRPC Service (sidecar)"
            torchserveAdapter = container "model-mesh-torchserve-adapter" "Adapts ModelMesh interface to PyTorch TorchServe" "Go gRPC Service (sidecar)"
            pullman = component "pullman" "Pluggable storage provider framework" "Go Library" {
                tags "Library"
            }
        }

        triton = softwareSystem "NVIDIA Triton Inference Server" "High-performance inference server" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel inference engine" "Runtime"
        mlserver = softwareSystem "Seldon MLServer" "Multi-framework inference server" "Runtime"
        torchserve = softwareSystem "PyTorch TorchServe" "PyTorch model serving" "Runtime"

        s3 = softwareSystem "S3-Compatible Storage" "AWS S3, MinIO, IBM COS" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Microsoft cloud object storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "Google cloud object storage" "External"
        httpStorage = softwareSystem "HTTP/HTTPS Storage" "Enterprise model repositories" "External"
        pvc = softwareSystem "PVC Volumes" "Kubernetes PersistentVolumeClaims" "Infrastructure"

        modelmeshServingController = softwareSystem "ModelMesh Serving Controller" "Operator managing ModelMesh deployments" "Internal Platform"

        # User interactions
        datascientist -> modelmeshServing "Deploys models via InferenceService CRs"
        mlops -> modelmeshServing "Configures storage backends and runtime settings"

        # Internal flows
        modelmesh -> puller "LoadModel/UnloadModel" "gRPC/8084 localhost"
        puller -> tritonAdapter "Forward after download" "gRPC/8085 localhost"
        puller -> ovmsAdapter "Forward after download" "gRPC/8085 localhost"
        puller -> mlserverAdapter "Forward after download" "gRPC/8085 localhost"
        puller -> torchserveAdapter "Forward after download" "gRPC/8085 localhost"

        # Adapter to runtime
        tritonAdapter -> triton "RepositoryModelLoad/Unload" "gRPC/8001 localhost"
        ovmsAdapter -> ovms "Config query and reload" "HTTP/8001 localhost"
        mlserverAdapter -> mlserver "RepositoryModelLoad/Unload" "gRPC/8001 localhost"
        torchserveAdapter -> torchserve "RegisterModel/UnregisterModel" "gRPC/7071 localhost"

        # Storage egress
        puller -> s3 "Download model artifacts" "HTTPS/443 TLS 1.2+ IAM"
        puller -> azureBlob "Download model artifacts" "HTTPS/443 TLS 1.2+ SP"
        puller -> gcs "Download model artifacts" "HTTPS/443 TLS 1.2+ SA"
        puller -> httpStorage "Download model artifacts" "HTTP(S) optional mTLS"
        puller -> pvc "Symlink model artifacts" "Filesystem"

        # Platform integration
        modelmeshServingController -> modelmeshServing "References sidecar image via ConfigMap" "storageHelperImage"
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

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Runtime" {
                background #775599
                color #ffffff
            }
            element "Infrastructure" {
                background #666666
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Library" {
                background #85BBF0
                color #000000
            }
            relationship "Relationship" {
                dashed false
            }
        }
    }
}
