workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using Predictor/InferenceService CRs"
        mlEngineer = person "ML Engineer" "Configures ServingRuntimes and manages model serving infrastructure"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator for multi-model serving with intelligent placement, scaling, and routing" {
            controller = container "modelmesh-controller" "Manages ServingRuntime deployments, Predictor lifecycle, Service reconciliation, HPA autoscaling" "Go Operator (controller-runtime)"
            webhook = container "ServingRuntime Webhook" "Validates ServingRuntime and ClusterServingRuntime create/update operations" "Validating Webhook (9443/TCP)"
            eventStream = container "ModelMesh Event Stream" "Watches etcd for model/vmodel state changes, dispatches events to predictor reconciler" "etcd Watcher"
            grpcResolver = container "gRPC Resolver" "Custom gRPC resolver using kube:// scheme for Kubernetes service discovery" "Kubernetes Endpoints Watcher"
        }

        modelmeshDataPlane = softwareSystem "ModelMesh Data Plane" "Model serving runtime pods with inference routing" {
            mmContainer = container "ModelMesh Container" "Inference routing, model lifecycle, vmodel management" "Java/gRPC (8033/TCP)"
            runtimeContainer = container "Runtime Container" "ML framework serving (Triton, MLServer, OVMS, TorchServe)" "Container"
            pullerSidecar = container "Puller Sidecar" "Downloads model artifacts from external storage" "modelmesh-runtime-adapter (8086/TCP)"
            restProxy = container "REST Proxy" "HTTP REST to gRPC protocol translation" "kserve/rest-proxy (8008/TCP)"
            oauthProxy = container "oauth-proxy" "OpenShift OAuth authentication proxy for REST endpoints" "ose-oauth-proxy (8443/TCP)"
            builtInAdapter = container "Built-in Adapter" "Runtime-specific model management adapter" "gRPC (8085/TCP)"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry state, vmodel routing, event streaming" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD, Deployment/Service management" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External"
        gcsStorage = softwareSystem "GCS Storage" "Google Cloud model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure model artifact storage" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook serving" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth token validation and SAR enforcement" "External"

        # User interactions
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService CRs via kubectl"
        mlEngineer -> modelmeshServing "Creates ServingRuntime/ClusterServingRuntime CRs"
        dataScientist -> modelmeshDataPlane "Sends inference requests" "gRPC/8033, HTTPS/8443"

        # Controller dependencies
        controller -> etcd "Reads etcd secret config, copies to namespaces" "Secret mount"
        controller -> k8sApi "CRUD for CRDs, Deployments, Services, Secrets, ConfigMaps, HPAs" "HTTPS/443"
        controller -> mmContainer "setVModel, registerModel, model lifecycle commands" "gRPC/8033"
        controller -> webhook "Registers webhook configuration" "HTTPS/9443"
        eventStream -> etcd "Watches model/vmodel state changes" "gRPC/2379"
        grpcResolver -> k8sApi "Watches Endpoints for ModelMesh service discovery" "HTTPS/443"

        # Data plane dependencies
        mmContainer -> etcd "Model registry state, vmodel routing" "gRPC/2379"
        mmContainer -> runtimeContainer "Forward inference to runtime" "gRPC (localhost/UDS)"
        oauthProxy -> restProxy "Forward authenticated requests" "HTTP/8008"
        restProxy -> mmContainer "Translate REST to gRPC" "gRPC/8033"
        pullerSidecar -> s3Storage "Download model artifacts" "HTTPS/443"
        pullerSidecar -> gcsStorage "Download model artifacts" "HTTPS/443"
        pullerSidecar -> azureBlob "Download model artifacts" "HTTPS/443"
        pullerSidecar -> builtInAdapter "Load model into runtime" "gRPC/8085"
        builtInAdapter -> runtimeContainer "Manage model lifecycle" "gRPC"
        oauthProxy -> openshiftOAuth "Validate OAuth tokens" "HTTPS"

        # Optional integrations
        controller -> certManager "Requests TLS certificates for webhook" "Certificate CRD"
        controller -> prometheusOp "Creates ServiceMonitor for metrics scraping" "ServiceMonitor CRD"
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

        container modelmeshDataPlane "DataPlaneContainers" {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
