workspace {
    model {
        client = person "Client" "Sends inference requests and model management RPCs"
        operator = person "Platform Operator" "Configures and monitors ModelMesh deployments"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for high-scale, high-density model serving" {
            mmContainer = container "mm Container" "Distributed model cache, routing, and lifecycle management sidecar" "Java 21"
            apiServer = container "ModelMeshApi" "External gRPC server exposing management and inference proxy API" "gRPC :8033"
            vmodelMgr = container "VModelManager" "Virtual model alias management for zero-downtime updates" "Java"
            preStop = container "RuntimeContainersPreStopServer" "Pre-stop hook server for graceful shutdown coordination" "HTTP"
        }

        modelRuntime = softwareSystem "Model Runtime" "Colocated container that performs actual model loading and inference (Triton, MLServer, OVMS)" "Sidecar"
        etcd = softwareSystem "etcd" "Distributed KV store for model registry, instance table, leader election, dynamic config" "External"
        modelmeshServing = softwareSystem "modelmesh-serving" "Kubernetes controller managing ModelMesh pod lifecycle, ServingRuntime/InferenceService CRDs" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        client -> modelmesh "Sends gRPC inference and management requests" "gRPC/8033 TLS optional"
        operator -> modelmeshServing "Configures ServingRuntime and InferenceService CRDs" "kubectl"
        modelmeshServing -> modelmesh "Creates and manages ModelMesh Deployments" "Kubernetes API"
        modelmesh -> etcd "Stores model registry, instance table, leader election state" "gRPC/2379 TLS optional"
        modelmesh -> modelRuntime "Delegates model loading and inference via local gRPC" "gRPC/8085 or UDS"
        prometheus -> modelmesh "Scrapes metrics" "HTTPS/2112 self-signed TLS"
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
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
