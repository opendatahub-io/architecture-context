workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference serving"
        admin = person "Platform Admin" "Configures cluster-wide serving runtimes and platform settings"
        client = person "Inference Client" "Sends inference requests to deployed models"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform with intelligent model placement and autoscaling" {
            controller = container "modelmesh-controller" "Manages ServingRuntime Deployments, Predictor virtual models, and inference Services" "Go Operator (controller-runtime)"
            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime specs for ModelMesh compatibility" "Go HTTPS Service (9443/TCP)"
            modelmesh = container "ModelMesh Sidecar" "Core model management engine; handles model placement, routing, and lifecycle via gRPC" "Java gRPC Service (8033/TCP)"
            puller = container "Runtime Adapter (Puller)" "Downloads model artifacts from storage backends to local cache" "Go gRPC Service (8086/TCP)"
            restProxy = container "REST Proxy" "HTTP-to-gRPC bridge for inference requests" "Go HTTP Service"
            oauthProxy = container "oauth-proxy" "OpenShift OAuth authentication proxy for inference endpoints (RHOAI)" "Go HTTPS Service (8443/TCP)"
            modelRuntime = container "Model Runtime" "Actual ML inference engine that loads and serves models" "Triton / OVMS / MLServer / TorchServe"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model placement state and vmodel registry" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        modelStorage = softwareSystem "Model Storage" "Object storage for ML model artifacts (S3, GCS, Azure Blob, PVC)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhook server" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Metrics scraping configuration via ServiceMonitor CRD" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift authentication and authorization" "External"

        # User interactions
        user -> modelmeshServing "Creates Predictor / InferenceService / ServingRuntime CRs via kubectl"
        admin -> modelmeshServing "Creates ClusterServingRuntime CRs and configures platform defaults"
        client -> oauthProxy "Sends inference requests" "HTTPS/8443 (OAuth)"
        client -> modelmesh "Sends inference requests" "gRPC/8033 (mTLS optional)"

        # Internal container interactions
        controller -> webhook "Webhook validation" "HTTPS/9443"
        controller -> modelmesh "SetVModel, GetVModelStatus, DeleteVModel" "gRPC/8033"
        controller -> k8sAPI "CRD CRUD, Deployment/Service/HPA management" "HTTPS/443"
        oauthProxy -> restProxy "Forward authenticated requests" "HTTP (pod-local)"
        restProxy -> modelmesh "HTTP-to-gRPC bridge" "gRPC (pod-local)"
        modelmesh -> modelRuntime "Inference execution" "Unix socket / gRPC (pod-local)"
        modelmesh -> puller "Model download requests" "gRPC/8086 (pod-local)"

        # External dependencies
        modelmesh -> etcd "Model placement state, vmodel registry, event streaming" "gRPC/2379 (TLS optional)"
        puller -> modelStorage "Download model artifacts" "HTTPS/443"
        webhook -> certManager "TLS certificate provisioning" "Certificate CRD"
        controller -> prometheusOp "ServiceMonitor creation" "CRD"
        oauthProxy -> openshiftOAuth "User authentication" "HTTPS"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshServing "Containers" {
            include *
            autoLayout
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
        }
    }
}
