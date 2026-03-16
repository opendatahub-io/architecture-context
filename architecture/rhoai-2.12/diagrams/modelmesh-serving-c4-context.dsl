workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys machine learning models for inference"
        client = person "Application Developer" "Builds applications that consume ML inference predictions"

        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform that manages and routes ML inference requests to multiple model servers" {
            controller = container "modelmesh-controller" "Manages InferenceService, Predictor, ServingRuntime lifecycle" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime configurations" "Go HTTPS Service" {
                tags "Webhook"
            }
            runtimePod = container "ModelMesh Runtime Pod" "Hosts model servers with intelligent routing and caching" "Multi-container Pod" {
                tags "Runtime"

                modelmeshContainer = component "ModelMesh Container" "Routes inference requests to appropriate model servers" "Go Service"
                restProxy = component "REST Proxy" "Translates REST API to gRPC for ModelMesh" "Go Sidecar"
                modelServer = component "Model Server" "Loads and executes ML models (Triton/MLServer/OpenVINO/TorchServe)" "Python/C++"
                puller = component "Storage Puller" "Pulls model artifacts from storage backends" "Init/Sidecar Container"
            }
        }

        etcd = softwareSystem "Etcd" "Distributed key-value store for ModelMesh cluster coordination and model metadata" "External - Required"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External - Required"
        s3 = softwareSystem "S3 Storage" "Object storage for trained model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External - Optional"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS and traffic management" "External - Optional"

        kserve = softwareSystem "KServe" "Serverless ML inference platform (optional integration)" "Internal ODH - Optional"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing ML workloads" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External - Optional"

        # User interactions
        user -> modelmesh "Creates InferenceService via kubectl or Dashboard"
        client -> modelmesh "Sends inference requests (gRPC/REST)"

        # ModelMesh to external dependencies
        modelmesh -> etcd "Stores cluster state and model metadata" "gRPC/2379, TLS 1.2+, mTLS/Password"
        modelmesh -> k8s "Manages Kubernetes resources (Deployments, Services, ConfigMaps)" "HTTPS/6443, ServiceAccount Token"
        modelmesh -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM/Access Keys"
        modelmesh -> prometheus "Exposes metrics for scraping" "HTTP/2112, HTTPS/8443"
        modelmesh -> istio "Uses for optional mTLS and traffic routing" "Service Mesh Integration"

        # Optional integrations
        kserve -> modelmesh "Optional v1beta1 InferenceService reconciliation" "CRD Watch"
        dashboard -> modelmesh "Provides UI for creating and managing inference services" "Kubernetes API"
        certManager -> modelmesh "Provisions TLS certificates for webhook server" "Certificate CRD"

        # Internal component relationships
        controller -> webhook "Validates resources before admission"
        controller -> runtimePod "Creates and manages runtime deployments"
        controller -> etcd "Coordinates cluster state"
        runtimePod -> s3 "Pulls model artifacts during initialization"
    }

    views {
        systemContext modelmesh "ModelMeshSystemContext" {
            include *
            autoLayout
        }

        container modelmesh "ModelMeshContainers" {
            include *
            autoLayout
        }

        component runtimePod "ModelMeshRuntimeComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External - Required" {
                background #e74c3c
                color #ffffff
            }
            element "External - Optional" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal ODH - Optional" {
                background #95e852
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #5a9ff2
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #000000
            }
        }

        theme default
    }
}
