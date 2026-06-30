workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via Caikit-based runtimes"

        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Python library providing Caikit backend integration with TGIS for text generation inference" {
            tgisBackend = container "TGISBackend" "Caikit BackendBase plugin managing TGIS connections in remote and local modes" "Python Module"
            tgisConnection = container "TGISConnection" "gRPC connection manager with TLS/mTLS configuration and prompt artifact management" "Python Module"
            loadBalancerProxy = container "GRPCLoadBalancerProxy" "Client-side gRPC load balancer with DNS-based endpoint discovery and automatic channel reconnection" "Python Module"
            managedSubprocess = container "ManagedTGISSubprocess" "Local TGIS process lifecycle manager with health monitoring and auto-recovery" "Python Module"
            protoStubs = container "Protobuf Stubs" "Generated gRPC stubs for fmaas.GenerationService API" "Python Generated Code"
        }

        caikitCore = softwareSystem "Caikit Core Framework" "AI toolkit providing BackendBase registry, model management, and runtime infrastructure" "Internal"
        tgisServer = softwareSystem "TGIS" "Text Generation Inference Service for large language model inference" "Internal Platform"
        caikitNlp = softwareSystem "caikit-nlp" "NLP model modules that consume caikit-tgis-backend for TGIS-backed inference" "Internal Platform"
        caikitTgiServing = softwareSystem "caikit-tgis-serving" "Runtime container image embedding caikit-tgis-backend for model serving" "Internal Platform"
        dnsResolver = softwareSystem "DNS Resolver" "Cluster DNS for TGIS endpoint discovery" "Infrastructure"

        # Relationships - External
        dataScientist -> caikitTgiServing "Sends inference requests to"
        caikitTgiServing -> caikitTgisBackend "Embeds as Python dependency"
        caikitNlp -> caikitTgisBackend "Imports as Python dependency"

        # Relationships - Internal
        tgisBackend -> tgisConnection "Creates per-model connections"
        tgisBackend -> managedSubprocess "Manages local TGIS (dev/test)"
        tgisConnection -> loadBalancerProxy "Creates gRPC client via"
        tgisConnection -> protoStubs "Uses generated stubs"
        loadBalancerProxy -> protoStubs "Wraps gRPC stubs"

        # Relationships - External dependencies
        caikitTgisBackend -> caikitCore "Registers as BackendBase plugin" "Python import"
        caikitTgisBackend -> tgisServer "Connects for inference" "gRPC/50055 TLS/mTLS"
        loadBalancerProxy -> dnsResolver "Polls for endpoint discovery" "DNS/53 UDP"
    }

    views {
        systemContext caikitTgisBackend "SystemContext" {
            include *
            autoLayout
        }

        container caikitTgisBackend "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
