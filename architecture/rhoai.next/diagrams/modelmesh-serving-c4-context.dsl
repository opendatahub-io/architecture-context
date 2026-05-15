workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference serving"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and manages model deployments"

        modelMeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator that manages distributed multi-model inference serving via ModelMesh" {
            controller = container "modelmesh-controller" "Manages ServingRuntime Deployments, Predictor model registration, Service reconciliation, and HPA autoscaling" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime resources (autoscaler config rules)" "Go HTTPS Server" "9443/TCP"
            modelMeshContainer = container "ModelMesh Container" "Distributed model serving runtime - handles model placement, routing, caching, and inference" "Java Sidecar" "8033/TCP gRPC"
            restProxy = container "REST Proxy" "Translates KServe v2 REST API to gRPC for ModelMesh" "Go Sidecar" "8008/TCP HTTP"
            oauthProxy = container "oauth-proxy" "Authentication proxy for inference endpoints in RHOAI" "OpenShift OAuth Proxy" "8443/TCP HTTPS"
            storagePuller = container "Storage Puller" "Downloads and caches model artifacts from storage backends" "Go Sidecar" "8086/TCP gRPC"
            modelRuntime = container "Model Runtime" "Actual model inference execution (Triton, MLServer, OVMS, TorchServe)" "ML Framework Container"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model state coordination and event streaming" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane for CRD management and resource orchestration" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management (optional, used by platform)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "External"
        prometheusOperator = softwareSystem "Prometheus" "Metrics collection for inference and controller metrics" "External"
        kserve = softwareSystem "KServe" "ML inference serving platform - provides CRD types and optional InferenceService integration" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys and configures modelmesh-serving" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "ODH model controller that manages webhooks for InferenceService" "Internal RHOAI"

        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage (GCS)" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External"

        # User interactions
        dataScientist -> modelMeshServing "Creates Predictor / InferenceService CRs via kubectl"
        dataScientist -> oauthProxy "Sends inference requests" "HTTPS/8443"
        mlEngineer -> modelMeshServing "Configures ServingRuntimes"

        # Internal container relationships
        controller -> webhookServer "Delegates validation"
        controller -> modelMeshContainer "Registers/unregisters models" "gRPC/8033"
        controller -> etcd "Watches model state events" "gRPC/2379 TLS"
        oauthProxy -> restProxy "Forwards authenticated requests" "HTTP/8008"
        restProxy -> modelMeshContainer "Translates REST to gRPC" "gRPC/8033"
        modelMeshContainer -> modelRuntime "Forwards inference" "gRPC (UDS/TCP)"
        modelMeshContainer -> storagePuller "Triggers model download" "gRPC/8086"
        modelMeshContainer -> etcd "State synchronization" "gRPC/2379 TLS mTLS"

        # External dependencies
        controller -> kubernetesAPI "Watches/manages CRDs, Deployments, Services, Secrets" "HTTPS/443"
        kubernetesAPI -> webhookServer "Admission webhook calls" "HTTPS/9443"
        storagePuller -> s3Storage "Downloads model artifacts" "HTTPS/443"
        storagePuller -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        storagePuller -> azureStorage "Downloads model artifacts" "HTTPS/443"
        certManager -> webhookServer "Provisions TLS certificates"
        prometheusOperator -> modelMeshContainer "Scrapes metrics" "HTTPS/2112"

        # Platform relationships
        rhodsOperator -> modelMeshServing "Deploys via kustomize manifests"
        kserve -> modelMeshServing "Provides CRD types (ServingRuntime, InferenceService)"
        odhModelController -> modelMeshServing "Webhook interception for InferenceService"
    }

    views {
        systemContext modelMeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelMeshServing "Containers" {
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
