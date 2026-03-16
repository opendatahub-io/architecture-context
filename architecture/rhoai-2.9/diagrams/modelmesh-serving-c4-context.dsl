workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for multi-model serving"

        modelmesh = softwareSystem "ModelMesh Serving" "Controller for managing ModelMesh multi-model inference workloads" {
            controller = container "modelmesh-controller" "Reconciles InferenceService, Predictor, ServingRuntime CRDs" "Go Operator"
            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime resources" "Go Service"
            runtimePod = container "ModelMesh Runtime Pod" "Multi-container pod with model serving capabilities" "Container Group" {
                modelmesh = component "ModelMesh" "Model orchestration and routing layer" "Go"
                adapter = component "Runtime Adapter" "Intermediary for model server communication" "Go"
                server = component "Model Server" "Triton/MLServer/OpenVINO/TorchServe" "Various"
                restProxy = component "REST Proxy" "HTTP-to-gRPC translation" "Go"
                oauthProxy = component "OAuth Proxy" "Authentication proxy" "Go"
            }
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model metadata and cluster coordination" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for model artifacts (AWS S3, MinIO, IBM COS)" "External"
        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        osAuth = softwareSystem "OpenShift OAuth" "User authentication service" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        dashboard = softwareSystem "RHOAI Dashboard" "Model serving management and monitoring UI" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"

        # Relationships
        user -> modelmesh "Creates InferenceService, Predictor, ServingRuntime via kubectl"
        user -> modelmesh "Sends inference requests via HTTPS" "HTTPS/443"

        modelmesh -> kubernetes "Reconciles CRDs and manages deployments" "HTTPS/6443"
        modelmesh -> etcd "Stores model metadata and placement decisions" "gRPC/2379"
        modelmesh -> s3 "Downloads model artifacts" "HTTPS/443"
        modelmesh -> osAuth "Authenticates users for inference endpoints" "OAuth 2.0"
        modelmesh -> prometheus "Exposes metrics" "HTTP/2112, HTTPS/8443"
        modelmesh -> certManager "Requests TLS certificates for webhooks" "HTTPS"

        dashboard -> modelmesh "Manages model deployments via UI"
        prometheus -> modelmesh "Scrapes metrics"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
        }

        container modelmesh "Containers" {
            include *
            autoLayout
        }

        component runtimePod "RuntimePodComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Container Group" {
                background #4a90e2
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
