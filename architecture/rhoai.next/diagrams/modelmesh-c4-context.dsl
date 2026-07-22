workspace {
    model {
        client = person "Client Application" "Sends inference requests and manages model lifecycle via gRPC"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for ML model serving at scale" {
            grpcApi = container "ModelMesh gRPC API" "External gRPC interface for model registration, inference routing, vmodel management" "Java / gRPC 1.63.2" "8033/TCP"
            routingEngine = container "Routing Engine" "Distributed LRU cache with leader-elected model placement, eviction, and request routing" "Java 21"
            thriftRpc = container "LiteLinks Thrift RPC" "Inter-instance communication for model routing, load balancing, and state sync" "Thrift / LiteLinks 1.7.2" "8080/TCP"
            runtimeClient = container "ModelRuntime Client" "Sidecar-to-runtime interface for model lifecycle (load/unload/predict)" "gRPC" "8085/TCP or UDS"
            metricsServer = container "Prometheus Metrics Server" "HTTPS metrics endpoint with self-signed TLS (BouncyCastle)" "Netty HTTP" "2112/TCP"
            healthServer = container "Health Probe Server" "Readiness and liveness probes" "Netty HTTP" "8089/TCP"
            payloadProcessor = container "Payload Processor" "Configurable pipeline for inference payload logging/auditing" "Java"
            configWatcher = container "ConfigMap Watcher" "Watches mounted ConfigMap files for dynamic configuration updates" "Java"
        }

        modelRuntime = softwareSystem "Model Runtime" "Co-located model server (Triton, MLServer, custom) that loads models and handles inference" "Runtime"
        etcd = softwareSystem "etcd" "Distributed KV store for model registry, instance registry, leader election" "External"
        zookeeper = softwareSystem "ZooKeeper" "Alternative distributed KV store backend (legacy, being phased out)" "External"
        modelmeshController = softwareSystem "modelmesh-controller" "Kubernetes operator that deploys ModelMesh as sidecar in ServingRuntime pods" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        statsd = softwareSystem "StatsD" "Alternative metrics reporting (Datadog/Sysdig formats)" "External"
        remotePayloadSvc = softwareSystem "Remote Payload Service" "External logging/auditing service for inference payloads" "External"

        # Relationships
        client -> modelmesh "Sends inference requests, registers/unregisters models" "gRPC/8033 TLS(opt)"
        modelmesh -> modelRuntime "Loads/unloads models, forwards inference requests" "gRPC/8085 or UDS, plaintext"
        modelmesh -> etcd "Stores model registry, instance state, leader election" "gRPC/2379 TLS(opt)"
        modelmesh -> zookeeper "Alternative KV store (legacy)" "Custom/2181 TLS(opt)"
        modelmesh -> modelmesh "Inter-instance routing, load balancing" "Thrift/8080 TLS/mTLS(opt)"
        modelmeshController -> modelmesh "Deploys as sidecar, configures env/TLS/storage" "Kubernetes API"
        prometheus -> modelmesh "Scrapes metrics" "HTTPS/2112 TLS(self-signed)"
        modelmesh -> statsd "Reports metrics (alternative)" "UDP/8126"
        modelmesh -> remotePayloadSvc "Sends inference payloads for logging" "HTTP(S) configurable"

        # Internal container relationships
        grpcApi -> routingEngine "Routes requests" "in-process"
        routingEngine -> thriftRpc "Forwards to peer instances" "Thrift/8080"
        routingEngine -> runtimeClient "Dispatches to local runtime" "in-process"
        runtimeClient -> modelRuntime "Model lifecycle and inference" "gRPC/8085 or UDS"
        grpcApi -> payloadProcessor "Intercepts payloads" "in-process"
        payloadProcessor -> remotePayloadSvc "Sends payloads" "HTTP(S)"
        configWatcher -> routingEngine "Dynamic config updates" "in-process"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
            description "ModelMesh system context showing external interactions"
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
            element "Runtime" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
