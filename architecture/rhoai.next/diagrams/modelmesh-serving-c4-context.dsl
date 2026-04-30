workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        platformAdmin = person "Platform Admin" "Manages ModelMesh Serving infrastructure and runtimes"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform with intelligent model placement and autoscaling" {
            controller = container "modelmesh-controller" "Manages ServingRuntime Deployments, Predictor virtual models, and inference Services" "Go Operator (controller-runtime)"
            webhook = container "ServingRuntime Webhook" "Validates ServingRuntime/ClusterServingRuntime specs for ModelMesh compatibility" "Validating Webhook"
            modelmeshSidecar = container "ModelMesh Sidecar" "Core model management engine; handles model placement, routing, and lifecycle via gRPC" "Java"
            puller = container "modelmesh-runtime-adapter (puller)" "Downloads model artifacts from storage backends to local cache" "Sidecar Container"
            restProxy = container "REST Proxy" "HTTP-to-gRPC bridge for model inference requests" "Sidecar Container"
            oauthProxy = container "oauth-proxy" "OpenShift OAuth authentication proxy for inference endpoints (RHOAI)" "Sidecar Container"
            modelRuntime = container "Model Runtime" "Actual ML inference engine (Triton, OVMS, MLServer, TorchServe)" "Runtime Container"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model placement state, vmodel registry, and cross-pod coordination" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD management, Deployments, Services" "External"
        modelStorage = softwareSystem "Model Storage" "S3, GCS, Azure Blob, or PVC-backed model artifact storage" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhook server" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "User authentication for inference endpoints" "External - RHOAI"
        kserve = softwareSystem "KServe" "CRD type definitions for ServingRuntime, ClusterServingRuntime, InferenceService" "Internal Platform"

        # User interactions
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService CRs, sends inference requests"
        platformAdmin -> modelmeshServing "Creates ServingRuntimes, configures storage and TLS"

        # Internal flows
        controller -> modelmeshSidecar "SetVModel, GetVModelStatus, DeleteVModel" "gRPC/8033"
        controller -> k8sAPI "CRD CRUD, Deployment/Service/HPA management" "HTTPS/443"
        controller -> webhook "Delegates validation" "HTTPS/9443"
        oauthProxy -> restProxy "Forwards authenticated requests" "HTTP/8008 (pod-local)"
        restProxy -> modelmeshSidecar "HTTP-to-gRPC bridge" "gRPC (pod-local)"
        modelmeshSidecar -> modelRuntime "Inference calls" "Unix socket (pod-local)"
        modelmeshSidecar -> puller "Model download requests" "gRPC/8086 (pod-local)"
        modelmeshSidecar -> etcd "Model state, vmodel registry, event streaming" "gRPC/2379 TLS"
        puller -> modelStorage "Download model artifacts" "HTTPS/443"

        # External integrations
        modelmeshServing -> etcd "Model placement state and coordination" "gRPC/2379"
        modelmeshServing -> modelStorage "Model artifact download" "HTTPS/443"
        modelmeshServing -> k8sAPI "Cluster resource management" "HTTPS/443"
        modelmeshServing -> certManager "Webhook TLS certificate provisioning" "CRD"
        modelmeshServing -> prometheusOperator "Metrics scraping configuration" "ServiceMonitor CRD"
        modelmeshServing -> openshiftOAuth "User authentication" "OAuth/HTTPS"
        modelmeshServing -> kserve "CRD type definitions" "Go import"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - RHOAI" {
                background #9b59b6
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
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
        }
    }
}
