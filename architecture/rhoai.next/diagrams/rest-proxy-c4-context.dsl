workspace {
    model {
        client = person "Data Scientist / ML Engineer" "Sends inference requests via KServe V2 REST API"

        modelMeshPod = softwareSystem "ModelMesh Serving Pod" "Hosts model inference with REST and gRPC interfaces" {
            restProxy = container "rest-proxy" "Translates KServe V2 REST requests into gRPC calls" "Go Service (gRPC-Gateway)" "Sidecar"
            inferenceServer = container "gRPC Inference Server" "Executes model inference using loaded models" "ModelMesh" "Primary"
        }

        modelMeshOperator = softwareSystem "ModelMesh Serving Operator" "Deploys and manages ModelMesh pods including rest-proxy sidecar" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and service identity" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Enforces authentication and authorization on API access" "External"
        configMap = softwareSystem "model-serving-config ConfigMap" "Stores rest-proxy image reference and serving configuration" "Internal RHOAI"

        client -> restProxy "Sends JSON inference requests" "HTTP/HTTPS 8008/TCP"
        restProxy -> inferenceServer "Forwards translated gRPC inference calls" "gRPC 8033/TCP"

        modelMeshOperator -> restProxy "Deploys as sidecar container" "Container Image Reference"
        configMap -> modelMeshOperator "Provides restProxy.image config" "ConfigMap"
        istio -> modelMeshPod "Enforces mTLS between services" "mTLS"
        kubeRBACProxy -> modelMeshPod "Enforces AuthN/AuthZ before traffic reaches proxy" "RBAC"
    }

    views {
        systemContext modelMeshPod "SystemContext" {
            include *
            autoLayout
            description "System context showing rest-proxy within the ModelMesh Serving ecosystem"
        }

        container modelMeshPod "Containers" {
            include *
            autoLayout
            description "Container view showing rest-proxy as a sidecar alongside the gRPC inference server"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "Primary" {
                background #50e3c2
                color #333333
            }
            element "Person" {
                shape person
                background #f5a623
                color #ffffff
            }
        }
    }
}
