workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Sends inference requests for text generation models"

        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Caikit module backend providing gRPC interface for text generation models served by TGIS" {
            caikitModule = container "Caikit Module Backend" "Implements fmaas.GenerationService (Generate, GenerateStream, ModelInfo, Tokenize)" "Python gRPC Service"
            lbProxy = container "GRPCLoadBalancerProxy" "DNS-based client-side load balancer for TGIS connections with configurable TLS" "Python gRPC Client"

            caikitModule -> lbProxy "Delegates inference calls"
        }

        modelMesh = softwareSystem "ModelMesh" "Model serving platform providing TLS termination and authentication boundary" "Platform"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server executing model inference" "Backend"
        caikitRuntime = softwareSystem "Caikit Runtime" "AI runtime framework providing module abstractions" "Library"
        dns = softwareSystem "DNS Service" "Provides endpoint discovery for TGIS instances" "Infrastructure"

        user -> modelMesh "Sends gRPC inference requests" "gRPC/TLS"
        modelMesh -> caikitTgisBackend "Forwards requests via pod-local gRPC" "gRPC (pod-local)"
        caikitTgisBackend -> tgis "Sends inference requests" "gRPC (configurable TLS)"
        caikitTgisBackend -> tgis "Health checks" "HTTP"
        caikitTgisBackend -> dns "Polls for TGIS endpoints" "DNS (10s interval)"
        caikitTgisBackend -> caikitRuntime "Uses as framework" "Python import"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Platform" {
                background #e8a838
                color #ffffff
            }
            element "Backend" {
                background #7ed321
                color #ffffff
            }
            element "Library" {
                background #d5e8d4
                color #333333
            }
            element "Infrastructure" {
                background #fff2cc
                color #333333
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
