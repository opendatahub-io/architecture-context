workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using Predictor/InferenceService CRs"
        mlEngineer = person "ML Engineer" "Configures ServingRuntimes and manages model serving infrastructure"
        externalClient = person "External Client" "Sends inference requests to deployed models via gRPC or REST"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator for multi-model serving with intelligent model placement, scaling, and routing" {
            controller = container "modelmesh-controller" "Manages ServingRuntime deployments, Predictor lifecycle, Service reconciliation, and HPA autoscaling" "Go Operator (controller-runtime)" "Controller"
            webhook = container "ServingRuntime Webhook" "Validates ServingRuntime and ClusterServingRuntime create/update operations" "Validating Webhook" "Webhook"
            eventStream = container "ModelMesh Event Stream" "Watches etcd for model and vmodel state changes, dispatches events to predictor reconciler" "etcd Watcher" "EventStream"
            grpcResolver = container "gRPC Resolver" "Custom gRPC resolver using kube:// scheme for Kubernetes Endpoints discovery" "Go Service" "Resolver"
            mmDataPlane = container "ModelMesh Data Plane" "Multi-model serving runtime with intelligent model placement and routing" "Java/Go Container" "DataPlane"
            pullerSidecar = container "Puller Sidecar" "Downloads model artifacts from S3, GCS, Azure, PVC, HTTP" "Go Container (modelmesh-runtime-adapter)" "Sidecar"
            restProxy = container "REST Proxy" "HTTP REST to gRPC protocol translation for inference requests" "Go Container (kserve/rest-proxy)" "Sidecar"
            oauthProxy = container "OAuth Proxy" "OpenShift OAuth authentication proxy for REST inference endpoints" "Go Container (ose-oauth-proxy)" "Sidecar"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry state, vmodel routing, and event streaming" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane for CRD management, Deployments, Services, RBAC" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook serving" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "External"

        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External Service"
        gcsStorage = softwareSystem "GCS Storage" "Google Cloud model artifact storage" "External Service"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure model artifact storage" "External Service"

        triton = softwareSystem "Triton Inference Server" "NVIDIA model serving runtime" "Runtime"
        mlserver = softwareSystem "MLServer" "Seldon model serving runtime for sklearn, xgboost, lightgbm" "Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel model serving runtime" "Runtime"
        torchserve = softwareSystem "TorchServe" "PyTorch model serving runtime" "Runtime"

        # Relationships - Users
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService CRs" "kubectl/oc"
        mlEngineer -> modelmeshServing "Configures ServingRuntimes" "kubectl/oc"
        externalClient -> oauthProxy "REST inference" "HTTPS/8443"
        externalClient -> mmDataPlane "gRPC inference" "gRPC/8033"

        # Relationships - Internal
        controller -> webhook "Validates CRs" "HTTPS/9443"
        controller -> mmDataPlane "registerModel, setVModel" "gRPC/8033"
        controller -> k8sAPI "CRUD CRDs, Deployments, Services" "HTTPS/443"
        eventStream -> etcd "Watches model/vmodel state" "gRPC/2379"
        eventStream -> controller "Triggers reconciliation" "GenericEvent"
        grpcResolver -> k8sAPI "Watches Endpoints" "HTTPS/443"

        oauthProxy -> restProxy "Pre-authenticated requests" "HTTP/8008"
        restProxy -> mmDataPlane "REST→gRPC translation" "gRPC/8033"
        mmDataPlane -> etcd "Model registry state" "gRPC/2379"
        pullerSidecar -> s3Storage "Downloads model artifacts" "HTTPS/443"
        pullerSidecar -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        pullerSidecar -> azureStorage "Downloads model artifacts" "HTTPS/443"

        # Runtime relationships
        mmDataPlane -> triton "Inference execution" "gRPC (localhost)"
        mmDataPlane -> mlserver "Inference execution" "gRPC (localhost)"
        mmDataPlane -> ovms "Inference execution" "gRPC (localhost)"
        mmDataPlane -> torchserve "Inference execution" "gRPC (localhost)"

        # Platform relationships
        controller -> certManager "Requests TLS certificates" "Certificate CRD"
        controller -> prometheusOperator "Creates ServiceMonitors" "ServiceMonitor CRD"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
                color #ffffff
            }
            element "EventStream" {
                background #4a90e2
                color #ffffff
            }
            element "Resolver" {
                background #4a90e2
                color #ffffff
            }
            element "DataPlane" {
                background #50c878
                color #ffffff
            }
            element "Sidecar" {
                background #50c878
                color #ffffff
            }
        }
    }
}
