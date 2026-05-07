workspace {
    model {
        datascientist = person "Data Scientist" "Creates Predictor/InferenceService CRs to deploy and serve ML models"
        platformops = person "Platform Operator" "Manages ServingRuntime configurations and platform setup"

        modelmeshServing = softwareSystem "ModelMesh Serving Controller" "Kubernetes controller that orchestrates multi-model inference serving by managing ModelMesh runtime deployments, model lifecycle, and inference service endpoints" {
            controller = container "modelmesh-controller" "Go Operator with three reconciliation controllers (ServiceReconciler, ServingRuntimeReconciler, PredictorReconciler)" "Go, controller-runtime v0.16.3"
            webhookServer = container "Webhook Server" "ValidatingWebhookConfiguration for ServingRuntime validation" "Go, :9443/TCP"
            eventStream = container "ModelMeshEventStream" "Watches etcd for vmodel and model state changes, translates to controller-runtime GenericEvents" "Go"
            predictorSources = container "Predictor Source Plugins" "PredictorCRRegistry, InferenceServiceRegistry with cached source and min-heap deletion queue" "Go"
        }

        runtimePod = softwareSystem "ModelMesh Runtime Pod" "Multi-container pod with ModelMesh, runtime, and optional sidecars" {
            modelmeshContainer = container "ModelMesh Container" "Java-based model serving engine with gRPC API" "Java, :8033/TCP gRPC"
            runtimeContainer = container "Runtime Container" "Inference server (OVMS, Triton, MLServer, or TorchServe)" "Varies"
            restProxy = container "REST Proxy" "HTTP-to-gRPC translation proxy for REST inference" "Go, :8008/TCP"
            oauthProxy = container "OAuth Proxy" "OpenShift OAuth authentication with SAR authorization" "Go, :8443/TCP"
            pullerSidecar = container "Puller/Adapter Sidecar" "Downloads model artifacts from storage backends" "Go, :8085-8086/TCP"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry state, vmodel lifecycle, and cross-pod coordination" "External Infrastructure"
        k8sApi = softwareSystem "Kubernetes API Server" "Kubernetes control plane for CRD management and resource CRUD" "External Infrastructure"
        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        gcs = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Azure model artifact storage" "External Service"
        prometheusOp = softwareSystem "Prometheus Operator" "Automatic metrics scraping via ServiceMonitor CRDs" "External Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhook server" "External Infrastructure"
        openshiftServingCert = softwareSystem "OpenShift Serving Cert Controller" "Auto-generates TLS certificates for OpenShift Services" "External Infrastructure"

        # User interactions
        datascientist -> modelmeshServing "Creates Predictor/InferenceService CRs via kubectl" "HTTPS/6443"
        platformops -> modelmeshServing "Manages ServingRuntime/ClusterServingRuntime CRs" "HTTPS/6443"
        datascientist -> runtimePod "Sends inference requests" "gRPC/8033 or HTTPS/8443"

        # Controller → Runtime
        modelmeshServing -> runtimePod "Manages runtime deployments, sends model lifecycle gRPC calls (SetVModel, DeleteVModel)" "gRPC/8033"

        # Controller → Infrastructure
        modelmeshServing -> etcd "Reads/writes model registry state, watches vmodel events" "gRPC/2379, Optional TLS/mTLS"
        modelmeshServing -> k8sApi "Watches CRDs, creates Deployments/Services/ConfigMaps/Secrets/HPAs" "HTTPS/6443"

        # Runtime → Infrastructure
        runtimePod -> etcd "Stores model state, coordinates across pods" "gRPC/2379"
        runtimePod -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        runtimePod -> gcs "Downloads model artifacts" "HTTPS/443, GCP credentials"
        runtimePod -> azure "Downloads model artifacts" "HTTPS/443, Azure credentials"

        # Infrastructure integrations
        modelmeshServing -> prometheusOp "Creates ServiceMonitor CRs" ""
        modelmeshServing -> certManager "Uses for webhook TLS certs (upstream)" ""
        modelmeshServing -> openshiftServingCert "Uses for Service TLS certs (ODH/RHOAI)" ""
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
