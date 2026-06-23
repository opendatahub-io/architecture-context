workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        platformAdmin = person "Platform Admin" "Manages model serving infrastructure"

        modelMesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for colocated model serving. Manages model lifecycle, placement, and inference routing across a cluster of pods." {
            modelMeshApi = container "ModelMeshApi" "gRPC server handling external model management and inference routing. Supports registerModel, unregisterModel, getModelStatus, ensureLoaded, setVModel, deleteVModel, plus arbitrary inference RPCs." "Java 21 / gRPC / Netty" "Sidecar"
            routingLogic = container "Routing / LRU Cache" "Distributed LRU cache manager. Determines model placement, handles cache eviction, and routes inference requests to the correct instance." "Java 21"
            vmodelManager = container "VModel Manager" "Virtual model alias system enabling blue-green model deployments. Atomically transitions aliases between concrete model IDs." "Java 21"
            litelinksRPC = container "Litelinks RPC" "Inter-pod communication layer using Thrift-over-TCP for model invocation forwarding and cache miss routing." "Litelinks 1.7.2 / Thrift"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint exposing request latency, cache metrics, model counts, and instance utilization over HTTPS." "Java 21 / Netty / BouncyCastle"
        }

        modelMeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes controller that manages ServingRuntimes and InferenceServices. Creates Deployments with ModelMesh sidecar containers." "Internal RHOAI"
        modelRuntime = softwareSystem "Model Runtime" "Colocated model server (Triton Inference Server, Seldon MLServer, or custom) implementing the ModelRuntime gRPC interface." "Internal"
        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, instance tracking, leader election, and dynamic configuration." "External"
        modelStorage = softwareSystem "Model Storage (S3/PVC)" "Persistent storage for ML model artifacts." "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes metrics from ModelMesh instances." "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Container orchestration platform providing pod lifecycle, service discovery, and secrets management." "External"

        # Relationships - People
        dataScientist -> modelMesh "Sends inference requests and registers models" "gRPC/8033 TLS"
        platformAdmin -> modelMeshServing "Configures ServingRuntimes and InferenceServices" "kubectl / API"

        # Relationships - System level
        modelMeshServing -> modelMesh "Deploys as sidecar, configures via env vars and mounted secrets" "Kubernetes API"
        modelMesh -> etcd "Stores model registry, instance state, leader election, dynamic config, vmodel state" "gRPC/2379 TLS"
        modelMesh -> modelRuntime "Sends loadModel, unloadModel, inference requests" "gRPC/8085 plaintext (localhost)"
        modelRuntime -> modelStorage "Downloads model artifacts" "HTTPS/443 (S3) or volume mount (PVC)"
        prometheus -> modelMesh "Scrapes metrics" "HTTPS/2112 TLS (self-signed)"
        modelMeshServing -> kubernetesAPI "Creates Deployments, Services, Secrets" "HTTPS/6443"

        # Container-level relationships
        dataScientist -> modelMeshApi "registerModel, inference RPCs" "gRPC/8033 TLS + mTLS"
        modelMeshApi -> routingLogic "Routes by model ID"
        routingLogic -> vmodelManager "Resolves virtual model aliases"
        routingLogic -> litelinksRPC "Forwards cache miss requests" "Thrift/8080 TLS"
        routingLogic -> etcd "Model registry operations" "gRPC/2379 TLS"
        vmodelManager -> etcd "Persists vmodel state" "gRPC/2379 TLS"
        routingLogic -> modelRuntime "Model load/unload/inference" "gRPC/8085 plaintext"
        prometheus -> metricsServer "Scrapes /metrics" "HTTPS/2112"
    }

    views {
        systemContext modelMesh "SystemContext" {
            include *
            autoLayout
            description "ModelMesh system context showing external interactions"
        }

        container modelMesh "Containers" {
            include *
            autoLayout
            description "ModelMesh internal container view"
        }

        styles {
            element "Software System" {
                background #4a90e2
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
