workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models, sends inference requests via REST"

        restProxy = softwareSystem "rest-proxy" "gRPC-Gateway reverse proxy that translates KServe V2 REST inference requests into gRPC calls for ModelMesh Serving" {
            gatewayServer = container "gRPC-Gateway Server" "Accepts HTTP/REST requests on port 8008 and translates to gRPC" "Go Service (grpc-gateway v2.15.0)"
            jsonMarshaler = container "Custom JSON Marshaler" "Handles tensor data type transformations (BOOL, INT8-64, UINT8-64, FP16-64, BYTES), nested arrays, base64 encoding" "Go"
            requestTransformer = container "Request Transformer" "Converts REST JSON parameters to/from gRPC InferParameter messages" "Go"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "gRPC-native model inference serving infrastructure" "Internal Platform"
        modelServingConfig = softwareSystem "model-serving-config ConfigMap" "Kubernetes ConfigMap that configures rest-proxy image via restProxy.image field" "Configuration"
        certManager = softwareSystem "cert-manager" "Manages TLS certificates for HTTPS endpoints" "External"

        # Relationships
        user -> restProxy "Sends inference requests" "HTTP/HTTPS on port 8008, KServe V2 REST Protocol"
        restProxy -> modelMesh "Forwards translated inference requests" "gRPC on localhost:8033, TLS optional"
        modelServingConfig -> restProxy "Configures container image" "restProxy.image field"
        certManager -> restProxy "Provides TLS certificates" "MM_TLS_KEY_CERT_PATH / MM_TLS_PRIVATE_KEY_PATH"

        # Internal relationships
        gatewayServer -> jsonMarshaler "Parses/serializes JSON"
        gatewayServer -> requestTransformer "Transforms requests/responses"
        requestTransformer -> modelMesh "gRPC calls" "localhost:8033"
    }

    views {
        systemContext restProxy "SystemContext" {
            include *
            autoLayout
            description "rest-proxy in the context of ModelMesh Serving ecosystem"
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
            element "Configuration" {
                background #e8e8e8
                color #333333
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
        }
    }
}
