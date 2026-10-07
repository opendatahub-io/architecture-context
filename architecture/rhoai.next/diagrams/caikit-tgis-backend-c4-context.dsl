workspace {
    model {
        developer = person "ML Engineer" "Deploys and manages ML models for inference"

        caikitTGISBackend = softwareSystem "caikit-tgis-backend" "Python library providing Caikit backend for TGIS connections" {
            tgisBackend = container "TGISBackend" "Manages connections to TGIS servers and model lifecycle" "Python (BackendBase)"
            tgisConnection = container "TGISConnection" "Encapsulates gRPC connection with TLS/mTLS support" "Python Dataclass"
            managedSubprocess = container "ManagedTGISSubprocess" "Launches and health-checks local TGIS processes" "Python Class"
            loadBalancer = container "GRPCLoadBalancerProxy" "DNS-based client-side gRPC load balancing" "Python Class"
            generationProto = container "generation.proto" "Defines fmaas.GenerationService gRPC interface" "Protobuf"
        }

        tgisServer = softwareSystem "TGIS" "Text Generation Inference Service running transformer models" "External"
        caikitFramework = softwareSystem "Caikit Framework" "Core AI framework providing BackendBase interface" "External"
        caikitTGISServing = softwareSystem "caikit-tgis-serving" "Serving runtime that imports this library as backend module" "Internal RHOAI"
        sharedFS = softwareSystem "Shared Filesystem" "Prompt tuning artifact storage (prompt_dir)" "Infrastructure"
        dnsResolver = softwareSystem "DNS Resolver" "Endpoint discovery for load balancing" "Infrastructure"

        # External relationships
        caikitTGISServing -> caikitTGISBackend "Imports as backend module" "Python import"
        caikitTGISBackend -> caikitFramework "Implements BackendBase interface" "Python import"
        caikitTGISBackend -> tgisServer "Inference requests" "gRPC / TLS or mTLS"
        caikitTGISBackend -> sharedFS "Prompt tuning artifacts" "Filesystem I/O"
        caikitTGISBackend -> dnsResolver "Endpoint discovery" "DNS/53 UDP"

        # Container relationships
        tgisBackend -> tgisConnection "Creates connections"
        tgisBackend -> managedSubprocess "Manages local TGIS"
        tgisConnection -> loadBalancer "Uses for remote connections"
        tgisConnection -> generationProto "Uses generated stubs"
        tgisConnection -> tgisServer "gRPC Generate/GenerateStream/Tokenize/ModelInfo" "gRPC/TLS"
        managedSubprocess -> tgisServer "Launches subprocess + gRPC" "gRPC/50055 + HTTP/3000"
        loadBalancer -> dnsResolver "Polls for new endpoints" "DNS/53 UDP"
        tgisBackend -> sharedFS "Copies prompt artifacts" "Filesystem"
    }

    views {
        systemContext caikitTGISBackend "SystemContext" {
            include *
            autoLayout
        }

        container caikitTGISBackend "Containers" {
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
        }
    }
}
