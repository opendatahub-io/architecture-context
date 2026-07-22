workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models via Caikit-based serving runtime"

        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Python library providing a Caikit backend plugin for managing connections to TGIS inference servers" {
            tgisBackend = container "TGISBackend" "Backend plugin implementing BackendBase; manages TGIS connections in remote or local mode" "Python"
            tgisConnection = container "TGISConnection" "Connection manager encapsulating gRPC connection with TLS/mTLS support" "Python"
            loadBalancerProxy = container "GRPCLoadBalancerProxy" "Client-side gRPC load balancer with DNS polling and automatic channel reconnection" "Python"
            managedSubprocess = container "ManagedTGISSubprocess" "Process manager for local TGIS subprocess with health monitoring and auto-recovery" "Python"
            generationProto = container "generation.proto" "FMaaS gRPC service definition — Generate, GenerateStream, Tokenize, ModelInfo" "Protocol Buffers"
        }

        caikitTgisServing = softwareSystem "caikit-tgis-serving" "Serving runtime container that imports caikit-tgis-backend to serve LLM models via TGIS" "Internal RHOAI"
        caikit = softwareSystem "Caikit" "Core AI runtime framework providing BackendBase, module abstractions, and lifecycle management" "External"
        tgisRemote = softwareSystem "TGIS (Remote)" "Text Generation Inference Service — serves LLM models via gRPC (FMaaS protocol)" "External"
        dnsResolver = softwareSystem "DNS Resolver" "Resolves TGIS hostnames to IP addresses for load balancing" "Infrastructure"
        filesystem = softwareSystem "Filesystem" "Stores TLS certificates (CA, client cert/key) and prompt tuning artifacts" "Infrastructure"

        # Relationships
        dataScientist -> caikitTgisServing "Sends inference requests via" "HTTP/gRPC"
        caikitTgisServing -> caikitTgisBackend "Imports and configures backend" "Python import"
        caikitTgisBackend -> caikit "Extends BackendBase interface" "Python import"
        caikitTgisBackend -> tgisRemote "Sends inference requests" "gRPC/HTTP2, TLS/mTLS, configurable/TCP"
        caikitTgisBackend -> dnsResolver "Discovers TGIS endpoints" "DNS, 53/UDP"
        caikitTgisBackend -> filesystem "Reads TLS certs and writes prompt artifacts" "File I/O"

        # Container-level relationships
        tgisBackend -> tgisConnection "Manages connections"
        tgisBackend -> managedSubprocess "Manages local subprocess"
        tgisConnection -> loadBalancerProxy "Uses for remote mode load balancing"
        tgisConnection -> generationProto "Uses gRPC stubs"
        loadBalancerProxy -> dnsResolver "Polls DNS" "53/UDP"
        loadBalancerProxy -> tgisRemote "gRPC calls" "TLS/mTLS"
        managedSubprocess -> generationProto "Uses gRPC stubs (local mode)"
    }

    views {
        systemContext caikitTgisBackend "SystemContext" {
            include *
            autoLayout
            description "System context showing caikit-tgis-backend as a library within the RHOAI model serving ecosystem"
        }

        container caikitTgisBackend "Containers" {
            include *
            autoLayout
            description "Internal components of the caikit-tgis-backend library"
        }

        styles {
            element "Software System" {
                background #438dd5
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #333333
            }
        }
    }
}
