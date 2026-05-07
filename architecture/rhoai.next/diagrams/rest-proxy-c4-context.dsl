workspace {
    model {
        client = person "ML Application / Client" "Sends REST inference requests using KServe V2 Predict Protocol"

        restProxy = softwareSystem "rest-proxy" "gRPC-to-REST reverse proxy that translates KServe V2 REST requests into gRPC calls" {
            httpListener = container "HTTP Listener" "Receives REST requests on port 8008" "Go HTTP Server"
            grpcGateway = container "gRPC-Gateway" "Auto-generated REST-to-gRPC routing from protobuf definitions" "grpc-gateway v2.15.0"
            customMarshaler = container "Custom Marshaler" "Handles tensor data marshalling: multi-dim arrays, base64 BYTES, numeric types" "Go"
            grpcClient = container "gRPC Client" "Forwards translated requests to ModelMesh gRPC service" "google.golang.org/grpc v1.56.3"
        }

        modelMeshServing = softwareSystem "ModelMesh Serving" "gRPC-based model serving infrastructure that hosts ML models" "Internal RHOAI"
        modelMeshOperator = softwareSystem "ModelMesh Serving Operator" "Deploys rest-proxy as sidecar via model-serving-config ConfigMap" "Internal RHOAI"
        kserveProtocol = softwareSystem "KServe V2 Predict Protocol" "Standardized ML inference API specification" "External Standard"

        client -> restProxy "Sends inference requests" "HTTP(S)/8008"
        restProxy -> modelMeshServing "Forwards as gRPC calls" "gRPC/8033 (localhost)"
        modelMeshOperator -> restProxy "Deploys as sidecar container" "ConfigMap: restProxy.image"
        restProxy -> kserveProtocol "Implements" "REST API conformance"
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
                background #438dd5
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
                shape person
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
