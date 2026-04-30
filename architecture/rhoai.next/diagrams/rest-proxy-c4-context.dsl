workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Sends inference requests to deployed models"
        application = person "Application Client" "Automated application consuming model predictions"

        restProxy = softwareSystem "rest-proxy" "REST-to-gRPC reverse proxy implementing KServe V2 REST Predict Protocol" {
            httpListener = container "HTTP Listener" "Accepts incoming REST requests on port 8008" "Go net/http"
            gatewayStubs = container "grpc-gateway Stubs" "Auto-generated HTTP-to-gRPC translation layer from protobuf definitions" "grpc-gateway v2.15.0"
            customMarshaler = container "Custom JSON Marshaler" "Handles KServe V2 tensor data serialization: nested arrays, base64 BYTES, raw output contents" "Go CustomJSONPb"
            grpcClient = container "gRPC Client" "Connects to upstream ModelMesh gRPC server on localhost:8033" "google.golang.org/grpc v1.56.3"
        }

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform providing gRPC inference" "Internal RHOAI"
        kserveProtocol = softwareSystem "KServe V2 Predict Protocol" "Standardized ML inference API specification" "External Standard"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "External"

        # Relationships
        datascientist -> restProxy "Sends inference requests" "HTTP/HTTPS 8008/TCP"
        application -> restProxy "Sends inference requests" "HTTP/HTTPS 8008/TCP"
        restProxy -> modelmeshServing "Forwards gRPC inference calls" "gRPC 8033/TCP localhost"
        certManager -> restProxy "Provisions TLS certificates" "MM_TLS_KEY_CERT_PATH"
        restProxy -> kserveProtocol "Conforms to" "API specification"

        # Container relationships
        httpListener -> gatewayStubs "Routes requests"
        gatewayStubs -> customMarshaler "Decodes/encodes JSON"
        customMarshaler -> grpcClient "Sends protobuf messages"
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
            description "Internal components of rest-proxy sidecar"
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Standard" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
