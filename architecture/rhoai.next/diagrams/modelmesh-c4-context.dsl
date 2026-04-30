workspace {
    model {
        client = person "ML Engineer / Data Scientist" "Deploys and queries ML models via InferenceService CRDs"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for high-scale, high-density model serving" {
            modelmeshApi = container "ModelMeshApi" "External-facing gRPC API for model management and inference request proxying" "Java gRPC Server, :8033/TCP"
            sidecarModelMesh = container "SidecarModelMesh" "Core distributed LRU cache and model routing engine" "Java Service"
            vmodelManager = container "VModelManager" "Manages versioned/virtual model abstractions with zero-downtime transition logic" "Java Service"
            litelinks = container "Litelinks Service" "Inter-instance communication for model forwarding via Thrift RPC" "Thrift/TCP, :8080/TCP"
            prometheusServer = container "Prometheus Metrics Server" "Exposes Prometheus metrics via custom Netty HTTP server" "Netty HTTPS, :2112/TCP"
            preStopServer = container "PreStop Server" "Handles Kubernetes preStop lifecycle hooks for graceful shutdown" "HTTP, :8089/TCP"
        }

        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes operator that deploys ModelMesh sidecars and manages InferenceService/ServingRuntime CRDs" "Internal RHOAI"
        modelRuntime = softwareSystem "Model Runtime" "Colocated model server (Triton, MLServer) that loads/unloads/serves ML models" "Pod-local Sidecar"
        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, instance registry, leader election, and dynamic configuration" "External"
        zookeeper = softwareSystem "Apache ZooKeeper" "Legacy alternative KV-store backend" "External (Optional)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "ConfigMap file watch, Downward API for pod metadata" "Platform"
        statsd = softwareSystem "StatsD Server" "Optional alternative metrics backend" "External (Optional)"
        payloadProcessor = softwareSystem "Remote Payload Processor" "Optional payload logging/auditing endpoint" "External (Optional)"

        # Relationships
        client -> modelmesh "Sends inference requests and model management RPCs" "gRPC/HTTP2 :8033, TLS + mTLS (opt)"
        modelmeshServing -> modelmesh "Deploys and configures sidecar containers, manages CRDs" "Kubernetes API"

        # Internal container relationships
        modelmeshApi -> sidecarModelMesh "Routes inference and management requests" "in-process"
        sidecarModelMesh -> vmodelManager "Virtual model lookups and transitions" "in-process"
        sidecarModelMesh -> litelinks "Forwards requests to remote instances on cache miss" "Thrift/TCP"

        # External relationships
        modelmesh -> modelRuntime "Model lifecycle: loadModel, unloadModel, inference" "gRPC :8085 or UDS, plaintext"
        modelmesh -> etcd "Model registry, instance registry, leader election, dynamic config" "gRPC :2379, TLS (opt)"
        modelmesh -> zookeeper "Alternative KV-store backend" "ZK Protocol :2181, TLS (opt)"
        litelinks -> litelinks "Inter-instance model inference forwarding" "Thrift :8080, TLS + mTLS (opt)"
        prometheus -> modelmesh "Scrapes metrics" "HTTPS :2112, TLS (self-signed)"
        modelmesh -> kubernetesApi "Pod metadata, ConfigMap watching" "Downward API / file watch"
        modelmesh -> statsd "Optional metrics reporting" "UDP :8125"
        modelmesh -> payloadProcessor "Optional payload logging" "HTTP/HTTPS"
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
            element "External (Optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Pod-local Sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
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
