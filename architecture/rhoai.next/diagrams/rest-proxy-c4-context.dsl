workspace {
    model {
        restClient = person "REST Client" "Application or user sending KServe V2 REST inference requests"

        modelMeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform that manages inference backends" {
            restProxy = container "rest-proxy" "Translates KServe V2 REST API calls to gRPC V2 Predict Protocol" "Go 1.23.6 / gRPC-Gateway" "Sidecar"
            grpcInferenceServer = container "gRPC Inference Server" "Serves ML model inference via gRPC V2 Predict Protocol" "Runtime Container"
            modelMeshController = container "ModelMesh Controller" "Manages model serving pods, injects sidecar containers" "Go Operator"
        }

        platformIngress = softwareSystem "Platform Ingress" "Handles external traffic routing, TLS termination, and authentication" "External"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane for ConfigMaps and pod management" "External"

        # Relationships
        restClient -> platformIngress "Sends REST inference requests" "HTTPS/443"
        platformIngress -> restProxy "Routes to ModelMesh pod" "HTTP or HTTPS/8008"
        restProxy -> grpcInferenceServer "Translates REST to gRPC" "gRPC/8033 (localhost, TLS optional)"
        modelMeshController -> restProxy "Injects as sidecar container via model-serving-config ConfigMap"
        modelMeshController -> k8sAPI "Reads ConfigMaps, manages pods" "HTTPS/6443"
        certManager -> restProxy "Provisions TLS certificates" "File mount"
    }

    views {
        systemContext modelMeshServing "SystemContext" {
            include *
            autoLayout
            description "System context showing rest-proxy within the ModelMesh Serving ecosystem"
        }

        container modelMeshServing "Containers" {
            include *
            autoLayout
            description "Container view showing rest-proxy sidecar alongside inference server"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
