workspace {
    model {
        client = person "Client / Data Scientist" "Sends inference requests and manages models via gRPC API"
        platformAdmin = person "Platform Admin" "Deploys and configures ModelMesh via modelmesh-serving controller"

        modelmesh = softwareSystem "ModelMesh" "Distributed LRU cache and routing layer for high-scale, high-density model serving" {
            modelMeshApi = container "ModelMeshApi" "External-facing gRPC API for model registration, status, inference routing, and virtual model management" "Java 21, gRPC, Netty" "gRPC Server"
            sidecarModelMesh = container "SidecarModelMesh" "Core distributed model cache, routing engine, and lifecycle manager; runs as sidecar alongside model runtime" "Java 21, Litelinks" "Core Engine"
            vmodelManager = container "VModelManager" "Virtual model management for atomic model version transitions and aliasing" "Java 21" "Component"
            typeConstraintManager = container "TypeConstraintManager" "Routes models to instances with appropriate labels (GPU vs non-GPU)" "Java 21" "Component"
            payloadPipeline = container "PayloadProcessor Pipeline" "Pluggable pipeline for processing inference request/response payloads" "Java 21" "Component"
            metricsExporter = container "Prometheus Metrics" "Prometheus-compatible metrics endpoint via Netty HTTP/HTTPS server on port 2112" "Java 21, Netty" "Metrics"
        }

        modelRuntime = softwareSystem "Model Runtime Container" "Colocated container that loads and serves ML models (Triton, MLServer, or custom)" "Sidecar"
        modelmeshServing = softwareSystem "modelmesh-serving Controller" "Kubernetes operator that deploys ModelMesh as sidecar, manages Deployments, Services, and configuration" "Internal RHOAI"
        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, instance state, leader election, and dynamic configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        statsd = softwareSystem "StatsD / Sysdig" "Alternative metrics emission via UDP push" "External"
        remotePayloadProcessor = softwareSystem "Remote Payload Processor" "External service for inference payload forwarding, monitoring, and auditing" "External"

        # Relationships
        client -> modelmesh "Sends inference requests, registers/manages models" "gRPC/8033 TLS+mTLS (optional)"
        platformAdmin -> modelmeshServing "Configures and deploys ModelMesh"

        modelmeshServing -> modelmesh "Deploys as sidecar, creates Deployments/Services, configures env vars" "Kubernetes API"

        modelMeshApi -> sidecarModelMesh "Routes requests" "In-process Java call"
        sidecarModelMesh -> vmodelManager "Manages virtual model transitions" "In-process"
        sidecarModelMesh -> typeConstraintManager "Checks type constraints for routing" "In-process"
        sidecarModelMesh -> payloadPipeline "Processes inference payloads" "In-process"
        sidecarModelMesh -> metricsExporter "Emits metrics" "In-process"

        sidecarModelMesh -> modelRuntime "Loads/unloads models, forwards inference" "gRPC/8085 or UDS, plaintext"
        sidecarModelMesh -> etcd "Model registry, instance state, leader election, dynamic config" "gRPC/2379, TLS (configurable)"
        sidecarModelMesh -> statsd "Pushes metrics" "StatsD/UDP 8126"
        payloadPipeline -> remotePayloadProcessor "Forwards inference payloads" "HTTP(S), TLS (optional)"

        prometheus -> metricsExporter "Scrapes metrics" "HTTP(S)/2112"
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
            element "Software System" {
                background #438dd5
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
            element "Sidecar" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "gRPC Server" {
                shape hexagon
            }
            element "Core Engine" {
                shape component
            }
            element "Metrics" {
                shape cylinder
            }
        }
    }
}
