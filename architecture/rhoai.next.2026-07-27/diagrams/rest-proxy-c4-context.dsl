workspace {
    model {
        user = person "Inference Consumer" "Application or service sending ML inference requests via REST/JSON"

        restProxy = softwareSystem "rest-proxy" "REST-to-gRPC reverse proxy translating KServe Predict V2 HTTP/JSON requests into gRPC calls" {
            server = container "rest-proxy Server" "HTTP server accepting KServe V2 REST requests and forwarding as gRPC" "Go Binary (CGO_ENABLED=0)"
            gateway = container "grpc-gateway Runtime" "Auto-generated REST-to-gRPC routing from protobuf definitions" "grpc-gateway v2.15.0"
            marshaler = container "CustomJSONPb Marshaler" "Custom JSON encoding/decoding for tensor data types, multi-dim arrays, base64 bytes" "Go"
        }

        modelMesh = softwareSystem "ModelMesh Inference Service" "Co-located gRPC inference service implementing GRPCInferenceService" "Internal - Same Pod"

        grpcLib = softwareSystem "gRPC" "gRPC framework for Go" "External Library"
        protobuf = softwareSystem "Protocol Buffers" "Protobuf serialization for inference messages" "External Library"
        controllerRuntime = softwareSystem "controller-runtime" "Kubernetes operator framework" "External Library"

        user -> restProxy "Sends inference requests" "HTTP/JSON port 8008"
        restProxy -> modelMesh "Forwards translated requests" "gRPC localhost:8033"

        server -> gateway "Routes HTTP requests"
        gateway -> marshaler "Encodes/decodes tensor JSON"
    }

    views {
        systemContext restProxy "SystemContext" {
            include *
            autoLayout
        }

        container restProxy "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
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
            element "Internal - Same Pod" {
                background #7ed321
                color #ffffff
            }
            element "External Library" {
                background #999999
                color #ffffff
            }
        }
    }
}
