workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via serving runtimes"

        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Python library providing Caikit backend for TGIS inference connections" {
            tgisBackend = container "TGISBackend" "Manages model-to-connection mapping and TGIS lifecycle" "Python (BackendBase)"
            tgisConnection = container "TGISConnection" "gRPC channel setup with TLS/mTLS credential loading" "Python (Dataclass)"
            managedSubprocess = container "ManagedTGISSubprocess" "Launches and health-monitors local TGIS processes with auto-recovery" "Python"
            loadBalancer = container "GRPCLoadBalancerProxy" "Client-side DNS-based gRPC load balancer with periodic endpoint discovery" "Python"
            generationProto = container "generation.proto" "Defines fmaas.GenerationService gRPC interface" "Protobuf"
        }

        caikitFramework = softwareSystem "Caikit Framework" "Core AI framework providing BackendBase, registration, and error handling" "External"
        caikitTgisServing = softwareSystem "caikit-tgis-serving" "Serving runtime that imports caikit-tgis-backend as a backend module" "Internal RHOAI"
        tgisServer = softwareSystem "TGIS (Text Generation Inference Service)" "Inference backend running transformer models" "Internal RHOAI"
        dnsResolver = softwareSystem "DNS Resolver" "Provides endpoint discovery for gRPC load balancing" "Infrastructure"
        sharedFilesystem = softwareSystem "Shared Filesystem" "Stores prompt tuning artifacts accessible by TGIS" "Infrastructure"

        # Relationships
        dataScientist -> caikitTgisServing "Submits inference requests"
        caikitTgisServing -> caikitTgisBackend "Imports as Python library"

        caikitTgisBackend -> caikitFramework "Extends BackendBase interface"
        caikitTgisBackend -> tgisServer "gRPC (fmaas.GenerationService) over TLS/mTLS or plaintext"
        caikitTgisBackend -> dnsResolver "DNS queries for endpoint discovery" "UDP/53"
        caikitTgisBackend -> sharedFilesystem "Reads/writes prompt tuning artifacts" "File I/O"

        # Internal container relationships
        tgisBackend -> tgisConnection "Creates and manages connections"
        tgisBackend -> managedSubprocess "Launches local TGIS (local mode)"
        tgisConnection -> loadBalancer "Uses for remote endpoint discovery"
        tgisConnection -> generationProto "Implements gRPC client stubs"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
