workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Sends inference requests to deployed models via REST API"
        application = person "Application / Service" "Automated client sending inference requests"

        modelMeshPod = softwareSystem "ModelMesh Serving Pod" "Serves ML models with REST and gRPC interfaces" {
            restProxy = container "rest-proxy" "Translates KServe V2 REST HTTP requests into gRPC calls" "Go Service (gRPC-Gateway)" "Sidecar"
            modelMeshGRPC = container "ModelMesh gRPC Server" "Serves model inference via gRPC V2 Predict Protocol" "Java/Go Service"
        }

        modelMeshController = softwareSystem "modelmesh-serving Controller" "Manages ModelMesh deployments and injects rest-proxy sidecar" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Handles authentication via kube-rbac-proxy or oauth-proxy" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        # Relationships
        dataScientist -> platformIngress "Sends inference requests" "HTTPS/443, Bearer Token"
        application -> platformIngress "Sends inference requests" "HTTPS/443, Bearer Token"

        platformIngress -> restProxy "Forwards authenticated requests" "HTTP or HTTPS/8008, Configurable TLS"
        restProxy -> modelMeshGRPC "Translates REST to gRPC" "gRPC/8033, Configurable TLS, localhost"

        modelMeshController -> modelMeshPod "Injects rest-proxy sidecar via model-serving-config ConfigMap" "Kubernetes API"
        certManager -> modelMeshPod "Provisions TLS certificates" "kubernetes.io/tls Secret"
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
            description "Container view showing rest-proxy sidecar alongside ModelMesh gRPC server"
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Sidecar" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
