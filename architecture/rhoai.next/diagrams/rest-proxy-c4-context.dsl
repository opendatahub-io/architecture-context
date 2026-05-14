workspace {
    model {
        client = person "ML Application / Client" "Sends REST inference requests using KServe V2 Predict Protocol"

        restProxy = softwareSystem "rest-proxy" "gRPC-to-REST reverse proxy translating KServe V2 REST requests into gRPC calls for ModelMesh Serving" {
            httpListener = container "HTTP Listener" "Accepts REST requests on port 8008, optional TLS" "Go net/http"
            grpcGateway = container "gRPC-Gateway" "Auto-generated REST-to-gRPC routing from grpc_predict_v2.proto" "grpc-gateway v2.15.0"
            customMarshaler = container "Custom Marshaler" "Transforms JSON tensors (nested arrays, base64 BYTES, multi-dimensional shapes) to/from protobuf tensor contents" "Go"
        }

        modelMeshServing = softwareSystem "ModelMesh Serving" "gRPC-native model serving infrastructure that hosts and serves ML models" "Internal RHOAI"
        modelMeshOperator = softwareSystem "ModelMesh Serving Operator" "Deploys and manages ModelMesh pods, injects rest-proxy as sidecar" "Internal RHOAI"
        kserveV2Protocol = softwareSystem "KServe V2 Predict Protocol" "Standard ML inference protocol specification (protobuf)" "External Standard"

        client -> restProxy "Sends inference & metadata requests" "HTTP(S)/8008"
        restProxy -> modelMeshServing "Forwards translated gRPC inference calls" "gRPC/8033 (localhost)"
        modelMeshOperator -> restProxy "Deploys as sidecar via model-serving-config ConfigMap" ""
        restProxy -> kserveV2Protocol "Implements REST API specification" ""
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Standard" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
