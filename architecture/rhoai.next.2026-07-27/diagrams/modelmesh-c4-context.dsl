workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via inference endpoints"
        mlEngineer = person "ML Engineer" "Configures model serving infrastructure and model runtimes"

        modelMesh = softwareSystem "ModelMesh" "Distributed model-serving mesh that manages model lifecycle, caching, and routing across a cluster" {
            modelMeshApi = container "ModelMeshApi" "gRPC server handling external inference requests; extracts model ID from headers and routes to correct instance" "Java gRPC Service" "Port 8033"
            modelMeshCore = container "ModelMesh Core" "Model lifecycle management (register, load, unload, cache), distributed placement, and scaling decisions" "Java"
            sidecarModelMesh = container "SidecarModelMesh" "Bridge between ModelMesh and collocated model runtime; communicates via UDS or local TCP" "Java"
            dataplaneApiConfig = container "DataplaneApiConfig" "RPC-level routing configuration; model ID extraction paths, method allow-listing" "Java"
            healthProbes = container "Health Probes" "HTTP liveness (/live) and readiness (/ready) endpoints on port 8089" "HTTP"
        }

        modelRuntime = softwareSystem "Model Runtime" "Collocated model runtime container providing ModelRuntime gRPC service for model loading and inference" "Sidecar"
        etcd = softwareSystem "etcd" "Distributed key-value store for model registry (KVTable), leader election, and dynamic configuration" "Infrastructure"
        otherInstances = softwareSystem "Other ModelMesh Instances" "Peer ModelMesh instances in the distributed mesh for request forwarding" "Internal"
        modelMeshServing = softwareSystem "ModelMesh Serving Operator" "Parent operator managing ModelMesh deployments, CRDs, and configuration" "Internal RHOAI"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "Infrastructure"

        # User interactions
        dataScientist -> modelMesh "Sends inference requests" "gRPC/8033"
        mlEngineer -> modelMeshServing "Configures model serving" "kubectl/API"

        # Internal component interactions
        modelMeshApi -> modelMeshCore "Routes inference requests"
        modelMeshCore -> sidecarModelMesh "Delegates model operations"
        modelMeshApi -> dataplaneApiConfig "Reads routing configuration"

        # External interactions
        sidecarModelMesh -> modelRuntime "Model load/unload/predict" "gRPC via UDS or TCP/8085"
        modelMeshCore -> etcd "Model registry, leader election, config" "KVTable (128 buckets)"
        modelMeshCore -> otherInstances "Request forwarding for remote models" "litelinks (Thrift)"
        modelMeshServing -> modelMesh "Deploys and configures" "Kubernetes API"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Sidecar" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #b8d4f0
                color #333333
            }
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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
