workspace {
    model {
        client = person "Client / Data Scientist" "Sends inference requests and manages model lifecycle"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for high-scale, high-density model serving" {
            modelMeshApi = container "ModelMeshApi" "External-facing gRPC API for model management and inference proxying" "Java gRPC Server, port 8033"
            sidecarModelMesh = container "SidecarModelMesh" "Core distributed LRU cache engine with model placement and routing" "Java Service"
            vModelManager = container "VModelManager" "Virtual model abstraction layer with zero-downtime transitions" "Java Service"
            litelinks = container "Litelinks Service" "Inter-instance Thrift RPC for model forwarding" "Thrift/TCP, port 8080"
            prometheusServer = container "Prometheus Metrics Server" "Custom Netty-based HTTP server for metrics" "HTTPS, port 2112"
            preStopServer = container "PreStop Server" "Kubernetes preStop lifecycle hook handler" "HTTP, port 8089"
        }

        modelRuntime = softwareSystem "Model Runtime" "Colocated model server (Triton, MLServer, custom) that loads and serves ML models" "Internal Pod"
        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes operator managing ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        etcd = softwareSystem "etcd" "Distributed KV store for model registry, instance registry, leader election, and dynamic config" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "Internal Platform"
        kubernetesApi = softwareSystem "Kubernetes API" "ConfigMap file watch and Downward API for pod metadata" "Internal Platform"

        zookeeper = softwareSystem "ZooKeeper" "Legacy alternative KV-store backend" "External (optional)"
        payloadProcessor = softwareSystem "Payload Processor" "External HTTP endpoint for payload logging/auditing" "External (optional)"
        statsd = softwareSystem "StatsD Server" "Alternative metrics reporting backend" "External (optional)"

        # External relationships
        client -> modelmesh "Sends gRPC inference requests and model management RPCs" "gRPC/HTTP2, port 8033, TLS + mTLS (optional)"
        modelmeshServing -> modelmesh "Deploys and configures ModelMesh sidecar containers" "Kubernetes API"

        # Internal container relationships
        modelMeshApi -> sidecarModelMesh "Routes requests" "in-process Java method call"
        sidecarModelMesh -> vModelManager "Resolves virtual models" "in-process Java method call"
        sidecarModelMesh -> litelinks "Forwards inference to remote instances" "Thrift/TCP, port 8080, TLS + mTLS (optional)"

        # Integration relationships
        modelmesh -> modelRuntime "Manages model lifecycle and forwards inference" "gRPC, port 8085 or UDS, plaintext"
        modelmesh -> etcd "Persists model/instance/vmodel records, leader election, dynamic config" "gRPC, port 2379, TLS (optional)"
        modelmesh -> zookeeper "Alternative KV-store backend" "ZooKeeper protocol, port 2181, TLS (optional)"
        modelmesh -> payloadProcessor "Optional payload logging to external endpoint" "HTTP/HTTPS, configurable port"
        modelmesh -> statsd "Optional metrics reporting" "StatsD/UDP, port 8125"
        prometheus -> modelmesh "Scrapes model serving metrics" "HTTPS, port 2112, TLS (self-signed)"
        kubernetesApi -> modelmesh "Provides ConfigMap updates and pod metadata" "File system watch, Downward API"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Pod" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #85bbf0
                color #ffffff
            }
            element "External (optional)" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
