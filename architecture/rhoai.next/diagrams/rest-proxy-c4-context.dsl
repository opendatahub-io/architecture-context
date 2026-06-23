workspace {
    model {
        client = person "ML Client" "Sends inference requests via REST API"

        restProxy = softwareSystem "rest-proxy" "Reverse-proxy that translates KServe V2 REST inference requests into gRPC calls for ModelMesh backends" {
            httpListener = container "HTTP/HTTPS Listener" "Receives KServe V2 REST requests on port 8008/TCP" "Go net/http"
            jsonMarshaler = container "CustomJSONPb Marshaler" "Transforms JSON tensor data to/from protobuf with support for BOOL, INT8-64, UINT8-64, FP32, FP64, BYTES types" "Go gRPC-Gateway"
            grpcClient = container "gRPC Client" "Forwards protobuf inference requests to ModelMesh via gRPC on port 8033/TCP" "Go google.golang.org/grpc"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform with gRPC inference interface" "Internal Platform"

        grpcGateway = softwareSystem "gRPC-Gateway v2" "Framework for gRPC-to-REST reverse proxy generation" "External Library"
        protobuf = softwareSystem "Protocol Buffers" "Serialization framework for gRPC messages" "External Library"

        # Relationships
        client -> restProxy "Sends inference and metadata requests" "HTTP/HTTPS 8008/TCP"
        restProxy -> modelMesh "Forwards inference/metadata as gRPC calls" "gRPC 8033/TCP (localhost)"

        # Internal container relationships
        httpListener -> jsonMarshaler "Passes request body"
        jsonMarshaler -> grpcClient "Sends protobuf message"
        grpcClient -> modelMesh "gRPC ModelInfer / ModelMetadata RPC"

        # Library dependencies
        restProxy -> grpcGateway "Uses for HTTP-to-gRPC translation" "Go import"
        restProxy -> protobuf "Uses for message serialization" "Go import"
    }

    views {
        systemContext restProxy "SystemContext" {
            include *
            autoLayout
            description "rest-proxy in the context of ModelMesh Serving"
        }

        container restProxy "Containers" {
            include *
            autoLayout
            description "Internal structure of the rest-proxy sidecar"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Library" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
        }
    }
}
