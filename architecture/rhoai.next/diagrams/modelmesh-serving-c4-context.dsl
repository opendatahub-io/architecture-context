workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference via Predictor or InferenceService CRs"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator for multi-model serving with intelligent model placement, scaling, and routing via an etcd-backed state store" {
            controller = container "modelmesh-controller" "Manages ServingRuntime deployments, Predictor lifecycle, Service reconciliation, HPA autoscaling, and etcd secret propagation" "Go Operator (controller-runtime)"
            webhook = container "ServingRuntime Webhook" "Validates ServingRuntime and ClusterServingRuntime create/update operations for autoscaler config correctness" "Validating Webhook (9443/TCP)"
            eventStream = container "ModelMesh Event Stream" "Watches etcd for model and vmodel state changes, dispatches events to predictor reconciler" "etcd Watcher"
            grpcResolver = container "gRPC Resolver" "Custom gRPC resolver using kube:// scheme for Kubernetes Endpoints-based ModelMesh service discovery" "Kubernetes Service Discovery"
        }

        modelmeshDataPlane = softwareSystem "ModelMesh Data Plane" "Model serving runtime pods with ModelMesh, runtime containers, puller, REST proxy, and oauth-proxy sidecars" {
            mmContainer = container "ModelMesh Container" "Inference routing, model lifecycle management, etcd state coordination" "Java/gRPC (8033/TCP)"
            runtimeContainer = container "Runtime Container" "Framework-specific model serving (Triton, MLServer, OVMS, TorchServe)" "Various"
            pullerSidecar = container "Puller Sidecar" "Downloads model artifacts from external storage (S3, GCS, Azure, PVC, HTTP)" "Go gRPC (8086/TCP)"
            restProxy = container "REST Proxy" "HTTP REST to gRPC protocol translation for inference requests" "Go HTTP (8008/TCP)"
            oauthProxy = container "OAuth Proxy" "OpenShift OAuth authentication proxy with SAR-based access control" "Go HTTPS (8443/TCP)"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry state, vmodel routing, and event streaming" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD CRUD, Deployment, Service, HPA, Secret, ConfigMap management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook serving" "External (Optional)"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor CRDs" "External (Optional)"

        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"
        gcs = softwareSystem "GCS Storage" "Google Cloud model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure model artifact storage" "External"

        kserve = softwareSystem "KServe" "Peer component providing InferenceService CRD types and additional webhooks" "Internal RHOAI"
        odhModelController = softwareSystem "ODH Model Controller" "Peer component with mutating/validating webhooks on InferenceService" "Internal RHOAI"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator defining connection webhooks for InferenceService" "Internal RHOAI"

        # Relationships - Controller
        user -> modelmeshServing "Creates Predictor/InferenceService/ServingRuntime CRs via kubectl"
        controller -> k8sAPI "CRUD for CRDs, Deployments, Services, HPA, Secrets, ConfigMaps" "HTTPS/443 TLS"
        controller -> etcd "Reads etcd secret, copies to user namespaces with namespace-specific root prefix"
        controller -> mmContainer "registerModel, setVModel, getVModelStatus, unregisterModel" "gRPC/8033 Optional TLS/mTLS"
        eventStream -> etcd "Watches model and vmodel key changes" "gRPC/2379 Optional TLS/mTLS"
        webhook -> k8sAPI "Called by API server for admission validation" "HTTPS/9443 TLS"

        # Relationships - Data Plane
        user -> oauthProxy "REST inference requests" "HTTPS/8443 TLS OAuth"
        user -> mmContainer "gRPC inference requests" "gRPC/8033 Optional TLS/mTLS"
        oauthProxy -> restProxy "Forwards authenticated requests" "HTTP/8008 localhost"
        restProxy -> mmContainer "Translates HTTP to gRPC" "gRPC/8033"
        mmContainer -> runtimeContainer "Forwards inference to loaded model" "gRPC localhost/UDS"
        mmContainer -> etcd "Model registry state, vmodel routing" "gRPC/2379 Optional TLS/mTLS"
        pullerSidecar -> s3 "Downloads model artifacts" "HTTPS/443 TLS AWS IAM"
        pullerSidecar -> gcs "Downloads model artifacts" "HTTPS/443 TLS GCP creds"
        pullerSidecar -> azureBlob "Downloads model artifacts" "HTTPS/443 TLS Azure creds"
        pullerSidecar -> runtimeContainer "Loads model via adapter" "gRPC/8085 or UDS"

        # Relationships - Optional/Peer
        controller -> certManager "Requests TLS certificates for webhook" "CRD"
        controller -> prometheusOperator "Creates ServiceMonitor for metrics scraping" "CRD"
        kserve -> modelmeshServing "Provides InferenceService/ServingRuntime CRD types; external webhooks intercept resources"
        odhModelController -> modelmeshServing "Mutating/validating webhooks on InferenceService"
        rhodsOperator -> modelmeshServing "Connection webhook on InferenceService"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (Optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
