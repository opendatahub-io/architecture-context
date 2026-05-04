workspace {
    model {
        dataScientist = person "Data Scientist" "Sends inference requests to deployed ML models via REST API"
        mlPipeline = person "ML Pipeline" "Automated pipeline that invokes model inference via REST"

        restProxy = softwareSystem "rest-proxy" "gRPC-to-REST reverse proxy that translates KServe V2 REST API requests into gRPC V2 Predict Protocol calls" {
            httpListener = container "HTTP Listener" "Receives KServe V2 REST API requests on port 8008" "Go HTTP Server"
            grpcGateway = container "gRPC-Gateway" "Auto-generated REST-to-gRPC translation layer from grpc_predict_v2.proto" "grpc-ecosystem/grpc-gateway v2.15.0"
            customMarshaler = container "Custom Marshaler" "Handles JSON tensor data marshalling: multi-dimensional arrays, base64 BYTES, raw byte content" "Go"
            grpcClient = container "gRPC Client" "Sends translated gRPC requests to ModelMesh on port 8033" "google.golang.org/grpc v1.56.3"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "gRPC-based multi-model serving infrastructure that hosts and serves ML models" "Internal RHOAI"
        modelMeshOperator = softwareSystem "ModelMesh Operator" "Deploys and manages ModelMesh pods, injects rest-proxy as sidecar via model-serving-config ConfigMap" "Internal RHOAI"
        kserveProtocol = softwareSystem "KServe V2 Protocol" "Standardized ML inference protocol (REST and gRPC variants) defined by grpc_predict_v2.proto" "External Standard"

        # Relationships
        dataScientist -> restProxy "Sends inference requests" "HTTP/HTTPS 8008/TCP"
        mlPipeline -> restProxy "Invokes model inference" "HTTP/HTTPS 8008/TCP"
        restProxy -> modelMesh "Forwards translated gRPC inference calls" "gRPC 8033/TCP (localhost)"
        modelMeshOperator -> restProxy "Deploys as sidecar container" "ConfigMap restProxy.image"
        restProxy -> kserveProtocol "Implements V2 REST API specification"

        # Internal container relationships
        httpListener -> grpcGateway "Routes REST requests"
        grpcGateway -> customMarshaler "Marshals/unmarshals tensor data"
        grpcGateway -> grpcClient "Sends gRPC calls"
        grpcClient -> modelMesh "gRPC ModelInfer / ModelMetadata RPCs" "gRPC 8033/TCP"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
