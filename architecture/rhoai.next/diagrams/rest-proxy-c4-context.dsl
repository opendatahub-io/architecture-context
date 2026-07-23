workspace {
    model {
        client = person "Inference Client" "Application or user sending ML inference requests via REST"

        restProxy = softwareSystem "rest-proxy" "REST-to-gRPC reverse proxy translating KServe V2 REST inference requests into gRPC calls" {
            server = container "REST Server" "Listens on 8008/TCP for KServe V2 REST API requests" "Go Service (gRPC-Gateway)"
            marshaler = container "Custom JSON Marshaler" "Handles tensor data encoding/decoding for multiple data types (BOOL, INT8-64, UINT8-64, FP16, FP32, FP64, BYTES)" "Go Package"
            grpcClient = container "gRPC Client" "Forwards translated requests to ModelMesh gRPC backend" "Go gRPC Client"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform providing gRPC inference endpoints" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar" "Internal RHOAI"
        certManager = softwareSystem "TLS Certificate Provider" "Provides TLS certificates for HTTPS listener" "Internal RHOAI"

        client -> restProxy "Sends inference requests" "REST KServe V2 / 8008/TCP"
        client -> kubeRBACProxy "Authenticates via" "HTTPS"
        kubeRBACProxy -> restProxy "Forwards authenticated requests" "HTTP(S)/8008"
        restProxy -> modelMesh "Forwards as gRPC calls" "gRPC/8033 (localhost)"
        certManager -> restProxy "Provisions TLS certificates" "Mounted volume"

        server -> marshaler "Decodes/encodes tensor data"
        marshaler -> grpcClient "Protobuf messages"
        grpcClient -> modelMesh "gRPC inference calls" "gRPC/8033"
    }

    views {
        systemContext restProxy "SystemContext" {
            include *
            autoLayout
            description "rest-proxy in the context of ModelMesh Serving and RHOAI platform"
        }

        container restProxy "Containers" {
            include *
            autoLayout
            description "Internal structure of rest-proxy showing REST-to-gRPC translation pipeline"
        }

        styles {
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
