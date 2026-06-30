workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models for inference"
        admin = person "Platform Admin" "Configures serving runtimes and cluster settings"
        client = person "Inference Client" "Sends inference requests to deployed models"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator managing multi-model inference with scale-to-zero, autoscaling, and dynamic model placement" {
            controller = container "modelmesh-controller" "Manages ServingRuntime, Predictor, and Service resources; deploys ModelMesh runtime pods" "Go Operator (controller-runtime)"
            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime autoscaling configuration" "Go Service, 9443/TCP HTTPS"
            servingRuntimeCtrl = container "ServingRuntime Controller" "Creates and manages Deployments for each runtime with sidecars" "controller-runtime Reconciler"
            predictorCtrl = container "Predictor Controller" "Communicates with ModelMesh gRPC API to register, load, manage models" "controller-runtime Reconciler"
            serviceCtrl = container "Service Controller" "Creates Kubernetes Services and Prometheus ServiceMonitors" "controller-runtime Reconciler"
        }

        runtimePod = softwareSystem "ModelMesh Runtime Pod" "Multi-container pod serving inference requests" {
            modelmesh = container "ModelMesh" "Core inference routing engine, receives gRPC requests and routes to loaded models" "Go/Java, 8033/TCP gRPC"
            restProxy = container "REST Proxy" "HTTP-to-gRPC translation proxy for REST inference" "Go, 8008/TCP HTTP"
            puller = container "Puller / Storage Helper" "Downloads model artifacts from object storage" "Go, 8086/TCP gRPC"
            oauthProxy = container "oauth-proxy" "OpenShift OAuth proxy for authenticated REST access" "Go, 8443/TCP HTTPS"
            runtimeContainer = container "Runtime Container" "Model server (e.g., Triton, MLServer, OpenVINO)" "Varies"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, vmodel state, and cluster coordination" "External"
        objectStorage = softwareSystem "Object Storage (S3/MinIO)" "Model artifact storage" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and CRD watches" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth token validation for REST inference authentication" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor" "External"
        kserveCRDs = softwareSystem "KServe CRDs" "ServingRuntime, ClusterServingRuntime, InferenceService CRD definitions" "Internal RHOAI"
        certManager = softwareSystem "cert-manager / OpenShift serving-certificates" "TLS certificate provisioning for webhooks and proxies" "External"

        # User interactions
        datascientist -> modelmeshServing "Creates Predictor / InferenceService CRs via kubectl/dashboard"
        admin -> modelmeshServing "Configures ServingRuntime / ClusterServingRuntime CRs"
        client -> runtimePod "Sends inference requests" "gRPC/8033 or HTTPS/8443"

        # Controller interactions
        controller -> servingRuntimeCtrl "Runs reconciliation loop"
        controller -> predictorCtrl "Runs reconciliation loop"
        controller -> serviceCtrl "Runs reconciliation loop"
        servingRuntimeCtrl -> k8sAPI "Creates/updates Deployments and HPAs" "HTTPS/443"
        predictorCtrl -> modelmesh "Registers/loads models via gRPC" "gRPC/8033"
        serviceCtrl -> k8sAPI "Creates Services and ServiceMonitors" "HTTPS/443"
        controller -> k8sAPI "Watches CRDs (Predictor, ServingRuntime, InferenceService)" "HTTPS/443"
        webhook -> k8sAPI "Receives admission requests" "HTTPS/9443"

        # Runtime pod interactions
        oauthProxy -> restProxy "Forwards authenticated requests" "HTTP/8008"
        restProxy -> modelmesh "Translates HTTP to gRPC" "gRPC/8033"
        modelmesh -> runtimeContainer "Routes inference to loaded model" "gRPC/UDS"
        modelmesh -> puller "Requests model download" "gRPC/8086"

        # External dependencies
        modelmesh -> etcd "Stores/watches model registry state" "gRPC/2379, Optional TLS"
        predictorCtrl -> etcd "Watches model events (ModelMeshEventStream)" "gRPC/2379"
        puller -> objectStorage "Downloads model artifacts" "HTTPS/443"
        oauthProxy -> openshiftOAuth "Validates OAuth tokens (SAR check)" "HTTPS"
        modelmeshServing -> kserveCRDs "Consumes CRD definitions"
        modelmeshServing -> certManager "Provisions TLS certificates"
        modelmeshServing -> prometheusOperator "Creates ServiceMonitor for metrics scraping"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshServing "ControllerContainers" {
            include *
            autoLayout
        }

        container runtimePod "RuntimePodContainers" {
            include *
            autoLayout
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
        }
    }
}
