workspace {
    model {
        client = person "Cluster Client" "Application or service within the cluster that needs REST-based model inference"

        restProxy = softwareSystem "rest-proxy" "Reverse-proxy sidecar translating KServe V2 REST inference requests into gRPC calls" {
            proxyService = container "rest-proxy" "Accepts HTTP/REST requests and translates to gRPC V2 Predict Protocol" "Go Service"
            customMarshaler = container "CustomJSONPb Marshaler" "Custom JSON marshaler/unmarshaler for tensor data type conversion" "Go Library"
            grpcGatewayStubs = container "gRPC-Gateway Stubs" "Auto-generated HTTP-to-gRPC reverse proxy handlers" "Generated Go Code"
        }

        modelMeshServing = softwareSystem "ModelMesh Serving" "Manages model serving deployments and injects rest-proxy as sidecar" "Internal RHOAI"
        inferenceServer = softwareSystem "ModelMesh Inference Server" "gRPC-based model inference server co-located in same pod" "Internal RHOAI"

        client -> restProxy "Sends REST inference requests" "HTTP/HTTPS 8008/TCP"
        restProxy -> inferenceServer "Forwards as gRPC requests" "gRPC 8033/TCP localhost"
        modelMeshServing -> restProxy "Deploys as sidecar container" "restProxy.image config"
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
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
