workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models for inference"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and model serving infrastructure"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache for model serving — manages model lifecycle, routes inference requests, coordinates placement across instances" {
            cacheManager = container "Cache Manager" "Distributed LRU cache with eviction policies and model placement decisions" "Java 21 / ConcurrentLinkedHashMap"
            requestRouter = container "Request Router" "Routes inference requests to correct instance where model is loaded" "Java 21 / gRPC"
            grpcServer = container "gRPC API Server" "External API for model management (register/unregister/status) and inference proxying" "Java 21 / Netty / gRPC" "8033/TCP"
            vmodelManager = container "VModel Manager" "Zero-downtime model updates via virtual model mapping layer" "Java 21"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with custom optimized counters/gauges/histograms" "Java 21 / Netty" "2112/TCP HTTPS"
            payloadProcessor = container "Payload Processor" "Extensible observation of inference payloads for logging/auditing" "Java 21"
        }

        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes controller that deploys ModelMesh sidecar into ServingRuntime pods, manages CRDs (InferenceService, ServingRuntime)" "Internal RHOAI"
        runtimeAdapter = softwareSystem "modelmesh-runtime-adapter" "Adapter sidecar implementing ModelRuntime gRPC API, bridges to specific model server formats" "Internal RHOAI"
        modelRuntime = softwareSystem "Model Runtime" "Model server (Triton, MLServer, or custom) that loads and serves ML models" "Internal RHOAI"
        etcd = softwareSystem "etcd" "Distributed KV store for model registry, instance coordination, leader election, and dynamic configuration" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        statsd = softwareSystem "StatsD Collector" "Alternative metrics emission backend" "Infrastructure"
        remotePayloadProc = softwareSystem "Remote Payload Processor" "External HTTP endpoint for inference payload logging/auditing" "External"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "External ingress gateway for model serving traffic" "Internal RHOAI"

        datascientist -> modelmesh "Sends inference requests" "gRPC/8033"
        platformadmin -> modelmeshServing "Manages ServingRuntimes and InferenceServices" "kubectl/API"
        modelmeshServing -> modelmesh "Deploys sidecar, registers/unregisters models" "gRPC/8033 TLS"
        rhoaiGateway -> modelmesh "Routes external inference traffic" "gRPC/8033 TLS"
        modelmesh -> etcd "Model records, leader election, dynamic config" "gRPC/2379 TLS optional"
        modelmesh -> runtimeAdapter "Load/unload/size/status operations" "gRPC/8085 or UDS"
        runtimeAdapter -> modelRuntime "Translates ModelRuntime API calls" "Native API"
        modelmesh -> modelmesh "Inter-instance inference forwarding" "Thrift+gRPC/8033 TLS mTLS"
        prometheus -> modelmesh "Scrapes metrics" "HTTPS/2112 self-signed"
        modelmesh -> statsd "Emits metrics (alternative)" "UDP/8126 StatsD"
        modelmesh -> remotePayloadProc "Sends inference payloads for logging" "HTTP/HTTPS configurable"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
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
