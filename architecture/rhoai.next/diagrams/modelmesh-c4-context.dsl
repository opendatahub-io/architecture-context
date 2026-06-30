workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and invokes ML models via gRPC"
        platform = person "Platform Admin" "Manages ServingRuntime deployments and etcd cluster"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache framework for ML model serving — manages routing, lifecycle, and placement of models across a cluster of serving pods" {
            modelMeshApi = container "ModelMeshApi" "External gRPC server exposing model management RPCs (register/unregister/status) and inference request proxying with zero-copy ByteBuf passthrough" "Java 21, gRPC, Netty" "Service"
            modelMeshCore = container "ModelMesh Core" "Distributed LRU cache engine — manages model placement decisions, leader election, cache eviction, and inter-pod coordination via Litelinks" "Java 21, Litelinks, Thrift" "Core"
            sidecarModelMesh = container "SidecarModelMesh" "gRPC client communicating with colocated model runtime container via ModelRuntime API for load/unload/serve operations" "Java 21, gRPC" "Client"
            vModelManager = container "VModelManager" "Virtual model alias manager enabling blue-green model transitions without client changes" "Java 21" "Manager"
            metricsReporter = container "Metrics Reporter" "Collects and exports operational metrics (inference latency, cache hits/misses, model load times)" "Prometheus / StatsD" "Metrics"
            preStopServer = container "RuntimeContainersPreStopServer" "HTTP pre-stop hook server blocking colocated containers from exiting during graceful shutdown" "Java 21, Netty HTTP" "Hook"
        }

        modelRuntime = softwareSystem "Model Runtime" "Colocated container implementing model loading/unloading and inference execution (Triton, MLServer, or custom)" "External"
        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, instance records, leader election, and dynamic configuration" "External"
        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes operator that creates model-mesh Deployment pods with ModelMesh sidecar and model runtime containers" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage (S3/PVC)" "Persistent storage for ML model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting system" "External"
        otherModelMeshPods = softwareSystem "Other ModelMesh Pods" "Peer model-mesh instances in the same deployment for distributed model serving" "Internal"

        # User interactions
        dataScientist -> modelmesh "Sends inference requests and model management RPCs" "gRPC/8033 TLS+mTLS(opt)"
        platform -> modelmeshServing "Configures ServingRuntime deployments"

        # Internal container interactions
        modelMeshApi -> modelMeshCore "Routes requests to core engine"
        modelMeshCore -> sidecarModelMesh "Delegates model operations"
        modelMeshCore -> vModelManager "Manages virtual model aliases"
        modelMeshCore -> metricsReporter "Reports operational metrics"

        # External interactions
        sidecarModelMesh -> modelRuntime "Load/unload/serve models" "gRPC/8085 or UDS, plaintext"
        modelMeshCore -> etcd "Model registry, leader election, instance records" "gRPC/2379 TLS(configurable)"
        vModelManager -> etcd "vModel state management" "gRPC/2379 TLS(configurable)"
        modelMeshCore -> otherModelMeshPods "Forward inference requests to pods with loaded models" "Thrift/8080 TLS+mTLS(opt)"
        modelRuntime -> modelStorage "Download model artifacts" "HTTPS/443 IAM"
        prometheus -> metricsReporter "Scrapes operational metrics" "HTTPS/2112 self-signed TLS"
        modelmeshServing -> modelmesh "Creates pods with ModelMesh sidecar" "Kubernetes API"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
        }

        container modelmesh "Containers" {
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
            element "Internal" {
                background #9b59b6
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Core" {
                background #2c6fbb
                color #ffffff
            }
            element "Client" {
                background #5ba8f7
                color #ffffff
            }
            element "Manager" {
                background #3d7cc9
                color #ffffff
            }
            element "Metrics" {
                background #f5a623
                color #ffffff
            }
            element "Hook" {
                background #e67e22
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
