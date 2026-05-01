workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Sends inference requests to deployed models via REST API"

        restProxy = softwareSystem "rest-proxy" "Stateless sidecar that translates KServe V2 REST requests into gRPC V2 Predict Protocol calls" {
            httpListener = container "HTTP Listener" "Accepts REST requests on port 8008 with optional TLS" "Go net/http"
            customJsonMarshaler = container "CustomJSONPb Marshaler" "Handles KServe V2 tensor serialization: nested arrays, base64 BYTES, raw output contents, typed parameters" "Go Library"
            grpcGateway = container "grpc-gateway" "Auto-generated HTTP-to-gRPC reverse proxy from protobuf service definitions" "grpc-gateway v2.15.0"
            grpcClient = container "gRPC Client" "Connects to upstream gRPC inference service on localhost:8033" "google.golang.org/grpc v1.56.3"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform providing gRPC V2 Predict Protocol inference" "Internal RHOAI"
        kserveV2 = softwareSystem "KServe V2 Predict Protocol" "Open standard for model inference REST and gRPC APIs" "Specification"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates" "External"

        # Relationships
        user -> restProxy "Sends inference/metadata requests" "HTTP/HTTPS 8008/TCP"
        restProxy -> modelMesh "Forwards as gRPC calls" "gRPC 8033/TCP (localhost)"
        restProxy -> kserveV2 "Implements specification" ""
        certManager -> restProxy "Provisions TLS certificates" "TLS cert/key files"

        # Internal container relationships
        httpListener -> customJsonMarshaler "Passes raw JSON body"
        customJsonMarshaler -> grpcGateway "Decoded protobuf messages"
        grpcGateway -> grpcClient "gRPC method invocations"
        grpcClient -> modelMesh "gRPC V2 Predict Protocol" "gRPC 8033/TCP"
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
                background #f5a623
                color #ffffff
                shape Person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Specification" {
                background #e8e8e8
                color #333333
            }
        }
    }
}
