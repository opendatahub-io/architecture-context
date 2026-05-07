workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and serves ML models via InferenceService"
        platform_admin = person "Platform Admin" "Manages RHOAI platform and serving runtimes"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache for model serving — manages model lifecycle, routes inference requests, coordinates placement across cluster" {
            cacheManager = container "Cache Manager" "Distributed LRU cache with eviction policies and model placement decisions" "Java 21 (ConcurrentLinkedHashMap)"
            requestRouter = container "Request Router" "Routes inference gRPC requests to correct instance where model is loaded" "Java 21 (gRPC)"
            vmodelManager = container "VModel Manager" "Virtual model abstraction for zero-downtime model updates" "Java 21"
            protoSplicer = container "Proto Splicer" "Binary protobuf splicing for model ID injection without deserialization" "Java 21"
            payloadProcessor = container "Payload Processor" "Extensible observation framework for inference payloads (logging, remote POST)" "Java 21"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with custom optimized client extensions" "Java 21 (Netty, port 2112)"
            healthServer = container "Health Server" "Readiness/liveness probes and pre-stop hook" "Java 21 (Netty, ports 8089/8090)"
        }

        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes controller that manages ServingRuntime pods with ModelMesh sidecars" "Internal RHOAI"
        modelRuntime = softwareSystem "Model Runtime" "Colocated model server (Triton, MLServer, custom) that executes inference" "Colocated Sidecar"
        runtimeAdapter = softwareSystem "modelmesh-runtime-adapter" "Adapter implementing ModelRuntime API, bridges to specific model server formats" "Colocated Sidecar"
        etcd = softwareSystem "etcd" "Distributed KV store for model registry, instance coordination, leader election" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        statsd = softwareSystem "StatsD Collector" "Alternative metrics backend (Sysdig or legacy format)" "External"
        payloadEndpoint = softwareSystem "Remote Payload Processor" "External HTTP endpoint for inference payload logging/auditing" "External"

        # Relationships
        datascientist -> modelmeshServing "Creates InferenceService/ServingRuntime via kubectl/Dashboard"
        modelmeshServing -> modelmesh "Registers/unregisters models, deploys sidecar" "gRPC/8033 TLS/mTLS"

        requestRouter -> cacheManager "Routes based on model placement"
        requestRouter -> protoSplicer "Injects model ID into inference requests"
        requestRouter -> vmodelManager "Resolves virtual model to concrete model"
        requestRouter -> payloadProcessor "Sends payload for observation"
        cacheManager -> etcd "Model records, placement, leader election" "gRPC/2379 Optional TLS"
        cacheManager -> modelRuntime "Load/unload/size/status" "gRPC/8085 or UDS (localhost)"
        modelRuntime -> runtimeAdapter "Bridges to runtime-specific format"
        payloadProcessor -> payloadEndpoint "Sends inference payloads" "HTTP(S) configurable"

        modelmesh -> etcd "Model registry, coordination, leader election, dynamic config" "gRPC/2379"
        modelmesh -> modelRuntime "Model load/unload/status operations" "gRPC/8085 or UDS"
        modelmesh -> modelmesh "Inter-instance inference forwarding" "Thrift/gRPC/8033 TLS"
        prometheus -> modelmesh "Scrapes metrics" "HTTPS/2112 self-signed TLS"
        modelmesh -> statsd "Emits metrics" "StatsD/8126 UDP"
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
            element "Colocated Sidecar" {
                background #4ecdc4
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
