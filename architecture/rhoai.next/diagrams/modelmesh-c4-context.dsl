workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and serves ML models via InferenceService CRDs"
        mlEngineer = person "ML Engineer" "Configures model serving runtimes and monitors inference"

        modelMesh = softwareSystem "ModelMesh" "Distributed LRU cache for serving runtime models — manages model lifecycle, routes inference requests, and coordinates model placement across a cluster" {
            grpcServer = container "gRPC Server" "External API for model management (register/unregister/status/ensureLoaded) and inference request proxying" "Java 21 / Netty / gRPC" "8033/TCP"
            cacheManager = container "Cache Manager" "Distributed LRU cache — manages model loading, unloading, eviction, and placement decisions across instances" "Java / ConcurrentLinkedHashMap"
            requestRouter = container "Request Router" "Routes inference requests to the correct instance where the target model is loaded, forwarding via litelinks/Thrift" "Java / litelinks"
            vmodelManager = container "VModel Manager" "Virtual model management for zero-downtime model updates — atomic traffic switching between model versions" "Java"
            protoSplicer = container "Proto Splicer" "Binary protobuf splicing for model ID injection into arbitrary gRPC inference messages without deserialization" "Java / Protobuf"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with custom optimized Counter/Gauge/Histogram implementations" "Java / Netty" "2112/TCP"
            payloadProcessor = container "Payload Processor" "Extensible inference payload observation — logging, remote HTTP POST, pattern matching" "Java"
            healthServer = container "Health Server" "Readiness and liveness probe endpoints" "Java / Netty" "8089/TCP"
        }

        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes controller that manages ServingRuntime pods and deploys ModelMesh as a sidecar" "Internal RHOAI"
        modelmeshRuntimeAdapter = softwareSystem "modelmesh-runtime-adapter" "Adapter sidecar implementing ModelRuntime API, bridging to specific model server formats" "Internal RHOAI"
        modelRuntime = softwareSystem "Model Runtime" "Colocated model serving container (Triton, MLServer, custom) that loads and executes ML models" "Internal RHOAI"

        etcd = softwareSystem "etcd" "Distributed KV store for model registry, instance coordination, leader election, and dynamic configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        statsd = softwareSystem "StatsD Collector" "Alternative metrics emission backend (Sysdig or legacy format)" "External"
        remotePayload = softwareSystem "Remote Payload Processor" "External HTTP service for inference payload logging and auditing" "External"

        # Relationships
        dataScientist -> modelmeshServing "Creates InferenceService CRDs"
        modelmeshServing -> modelMesh "Deploys as sidecar; calls register/unregister/ensureLoaded" "gRPC/8033 TLS+mTLS"
        modelMesh -> modelRuntime "Calls loadModel/unloadModel/modelSize/modelStatus" "gRPC/8085 or UDS"
        modelMesh -> etcd "Model records, instance registry, leader election, config" "gRPC/2379 TLS(optional)"
        modelMesh -> prometheus "Exposes /metrics" "HTTPS/2112 Self-signed TLS"
        modelMesh -> statsd "Emits metrics (optional)" "UDP/8126 StatsD"
        modelMesh -> remotePayload "Sends inference payloads (optional)" "HTTP(S) configurable"
        modelmeshRuntimeAdapter -> modelRuntime "Bridges ModelRuntime API to runtime-specific format"

        # Internal container relationships
        grpcServer -> cacheManager "Model lifecycle operations"
        grpcServer -> requestRouter "Inference request dispatch"
        requestRouter -> protoSplicer "Model ID injection"
        requestRouter -> payloadProcessor "Payload observation"
        cacheManager -> vmodelManager "Zero-downtime model updates"
    }

    views {
        systemContext modelMesh "SystemContext" {
            include *
            autoLayout
        }

        container modelMesh "Containers" {
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
