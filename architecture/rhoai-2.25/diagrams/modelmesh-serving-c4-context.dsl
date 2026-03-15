workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys multi-model serving workloads using ModelMesh"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes controller managing high-performance multi-model serving infrastructure with ModelMesh orchestration layer" {
            controller = container "modelmesh-controller" "Manages ServingRuntime and InferenceService lifecycle" "Go Operator" "Controller"
            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime resources" "Go Service" "Webhook"
            modelMesh = container "ModelMesh Runtime" "Model serving orchestration layer for placement and routing" "Java Runtime" "Runtime"
            restProxy = container "REST Proxy" "Translates KServe V2 REST API to gRPC" "HTTP Proxy" "Runtime"
            runtimeAdapter = container "Runtime Adapter" "Intermediary between ModelMesh and model servers" "Sidecar" "Runtime"
            modelRuntime = container "Model Runtime" "Executes inference (Triton/MLServer/OpenVINO/TorchServe)" "Container" "Runtime"
            storagePuller = container "Storage Helper" "Retrieves models from S3/PVC storage backends" "Init/Sidecar Container" "Runtime"
        }

        etcd = softwareSystem "ETCD" "Distributed key-value store for model metadata and cluster state" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (shares CRD schema)" "Internal RHOAI"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Service mesh for mTLS and traffic management" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External"

        # User interactions
        user -> modelmeshServing "Creates ServingRuntime, InferenceService via kubectl"
        user -> modelmeshServing "Sends inference requests to deployed models" "HTTP/gRPC"

        # Controller interactions
        controller -> kubernetes "Manages Deployments, Services, ConfigMaps, Secrets" "HTTPS/6443"
        controller -> webhook "Validates resources before creation" "HTTPS/9443"
        controller -> etcd "Initializes model metadata storage" "gRPC/2379"

        # Runtime interactions
        modelMesh -> etcd "Stores and retrieves model metadata" "HTTP/gRPC 2379"
        modelMesh -> runtimeAdapter "Routes inference requests" "gRPC UDS/8001"
        runtimeAdapter -> modelRuntime "Executes model inference" "gRPC"
        restProxy -> modelMesh "Translates REST to gRPC" "gRPC/8033"
        storagePuller -> s3 "Downloads model artifacts" "HTTPS/443"

        # External dependencies
        modelmeshServing -> prometheus "Exposes metrics" "HTTPS/8443, HTTP/2112"
        modelmeshServing -> serviceMesh "Optional mTLS and traffic management" "mTLS"
        modelmeshServing -> kserve "Shares InferenceService CRD schema" "CRD"
        webhook -> certManager "Obtains TLS certificates" "Certificate CRD"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #50e3c2
                color #000000
            }
        }
    }
}
