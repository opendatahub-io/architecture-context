workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and manages ML models for inference"
        mlEngineer = person "ML Engineer" "Registers models and monitors inference performance"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for high-scale, high-density model serving" {
            modelmeshApi = container "ModelMeshApi" "External gRPC API for model management (register/unregister/status) and transparent inference request forwarding" "Java 21 / gRPC / Netty"
            sidecarModelMesh = container "SidecarModelMesh" "Core distributed LRU cache engine with ProtoSplicer zero-copy passthrough and ConcurrentLinkedHashMap" "Java 21"
            vmodelManager = container "VModelManager" "Virtual model aliases and zero-downtime model transitions via etcd-backed state" "Java 21"
            prometheusNettyServer = container "Prometheus NettyServer" "HTTPS metrics endpoint on port 2112 with self-signed TLS certificate" "Java 21 / Netty / BouncyCastle"
            preStopServer = container "RuntimeContainersPreStopServer" "HTTP lifecycle hook on port 8090 for colocated runtime container graceful shutdown" "Java 21 / Netty"
            litelinksThrift = container "Litelinks (Thrift RPC)" "Inter-instance communication for model routing, cache coordination, and distributed invocation" "Java 21 / Apache Thrift / litelinks"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, instance registration, leader election, vmodel state, and dynamic configuration" "External"
        modelRuntime = softwareSystem "Model Runtime Container" "Colocated model serving runtime (mlserver, Triton, custom) that loads models and handles inference" "Sidecar"
        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes controller managing ServingRuntimes and InferenceServices CRDs, deploys ModelMesh pods" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "Cluster Service"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing pod lifecycle, health probes, and network policies" "Platform"

        # User relationships
        dataScientist -> modelmesh "Sends inference requests via gRPC" "gRPC/8033"
        mlEngineer -> modelmesh "Registers/unregisters models and monitors status" "gRPC/8033"

        # Internal relationships
        modelmeshApi -> sidecarModelMesh "Delegates model lookups and routing" "In-process method call"
        sidecarModelMesh -> vmodelManager "Manages virtual model aliases" "In-process"
        sidecarModelMesh -> litelinksThrift "Routes requests to remote pods for cache misses" "Thrift RPC/8080"

        # External relationships
        modelmesh -> etcd "Stores model registry, instance state, leader election, vmodel mappings" "gRPC/2379, Optional TLS"
        modelmesh -> modelRuntime "Loads/unloads models, forwards inference requests" "gRPC/8085, Plaintext (localhost)"
        modelmeshServing -> modelmesh "Configures and deploys ModelMesh pods" "ConfigMap"
        prometheus -> modelmesh "Scrapes metrics (latency, cache stats, capacity)" "HTTPS/2112, self-signed TLS"
        kubernetes -> modelmesh "Performs readiness and liveness probes" "HTTP/8089"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
            description "ModelMesh system context showing external systems and users"
        }

        container modelmesh "Containers" {
            include *
            autoLayout
            description "ModelMesh internal container structure"
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
            element "Sidecar" {
                background #4ecdc4
                color #ffffff
            }
            element "Cluster Service" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
