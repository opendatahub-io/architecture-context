workspace {
    model {
        client = person "ML Platform User" "Sends inference requests and manages model lifecycle via gRPC API"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and intelligent routing layer for high-scale, high-density model serving (Java 21 sidecar)" {
            apiServer = container "ModelMesh gRPC API" "External gRPC API for model management (register, unregister, status) and inference request routing with mm-model-id header injection" "Java 21 / Netty / gRPC :8033"
            core = container "ModelMesh Core" "Distributed LRU cache engine with model placement, eviction, and lifecycle management. ConcurrentLinkedHashMap-based cache with leader-elected placement decisions" "Java 21 / Litelinks"
            litelinks = container "Litelinks Service" "Inter-instance communication and service discovery for model routing, replication, and cache coordination" "Java 21 / gRPC+Thrift :8080"
            prometheusServer = container "Prometheus Metrics Server" "Exposes Prometheus metrics endpoint with self-signed TLS cert" "Java 21 / Netty HTTPS :2112"
            preStopServer = container "Pre-Stop Hook Server" "Coordinates graceful shutdown with colocated runtime containers" "Java 21 / Netty HTTP :8090"
            vmodelManager = container "VModel Manager" "Manages virtual model transitions for zero-downtime model updates" "Java 21"

            apiServer -> core "Routes requests" "In-process"
            core -> litelinks "Inter-pod communication" "gRPC/Thrift"
            core -> vmodelManager "VModel transitions" "In-process"
        }

        modelmeshServing = softwareSystem "modelmesh-serving" "Controller that creates and manages ModelMesh sidecar deployments alongside model runtimes" "Internal RHOAI"
        modelRuntime = softwareSystem "Model Runtime" "Colocated container (Triton, MLServer, custom) that performs actual model loading/unloading and inference" "Pod-local"
        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, instance coordination, leader election, and dynamic configuration" "Infrastructure"
        zookeeper = softwareSystem "ZooKeeper" "Alternative distributed KV store backend (legacy)" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection system" "Infrastructure"
        statsd = softwareSystem "StatsD" "Alternative metrics emission agent (optional)" "Infrastructure"
        payloadProcessor = softwareSystem "Remote Payload Processor" "Optional HTTP(S) service for inference payload forwarding and observability" "External"
        k8sApi = softwareSystem "Kubernetes API" "Provides pod identity via Downward API (pod name, IP, host IP)" "Infrastructure"

        client -> modelmesh "gRPC inference and model management" "gRPC/8033 TLS+mTLS (optional)"
        modelmeshServing -> modelmesh "Creates/manages Deployments" "Kubernetes API"
        modelmesh -> modelRuntime "Model load/unload/inference" "gRPC/8085 or UDS Plaintext"
        modelmesh -> etcd "Model registry, leader election, config" "gRPC/2379 TLS (optional)"
        modelmesh -> zookeeper "Alternative KV store" "ZooKeeper/2181 TLS (optional)"
        modelmesh -> modelmesh "Inter-pod routing and replication" "gRPC+Thrift/8080 TLS (optional)"
        prometheus -> modelmesh "Scrapes metrics" "HTTPS/2112 self-signed TLS"
        modelmesh -> statsd "Emits metrics" "UDP/8126"
        modelmesh -> payloadProcessor "Forwards inference payloads" "HTTP(S) configurable"
        modelmesh -> k8sApi "Reads pod identity" "Downward API"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Pod-local" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
