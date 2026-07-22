workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using Predictor and InferenceService CRs"
        platformOp = person "Platform Operator" "Configures ServingRuntimes, etcd, storage credentials, and TLS certificates"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator managing multi-model inference serving with ModelMesh placement and routing" {
            controller = container "modelmesh-controller" "Reconciles Predictor, ServingRuntime, ClusterServingRuntime, InferenceService CRDs; manages runtime Deployments with ModelMesh sidecars" "Go Operator (controller-runtime)" "controller"
            webhookServer = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime specs; enforces reserved names, ports, autoscaler config" "Go Webhook (9443/TCP TLS)" "webhook"
            predictorReconciler = container "PredictorReconciler" "Validates Predictor specs, manages VModel entries via gRPC, tracks model load states" "Go Controller" "controller"
            srReconciler = container "ServingRuntimeReconciler" "Creates runtime Deployments from templates, scale-to-zero, HPA autoscaling, PVC mounting" "Go Controller" "controller"
            serviceReconciler = container "ServiceReconciler" "Manages K8s Services, ServiceMonitor for Prometheus, TLS certificate loading" "Go Controller" "controller"
        }

        runtimePod = softwareSystem "ModelMesh Runtime Pod" "Multi-container pod with ModelMesh, REST proxy, oauth-proxy, puller, and model server" {
            mmContainer = container "ModelMesh (mm)" "Model placement, routing, serving orchestration; gRPC API for model management" "Go/Java Sidecar (8033/TCP gRPC)" "sidecar"
            restProxy = container "REST Proxy" "KServe V2 REST-to-gRPC translation for inference requests" "Go Service (8008/TCP HTTP)" "sidecar"
            oauthProxy = container "oauth-proxy" "OpenShift OAuth authentication proxy with SAR authorization" "Go Sidecar (8443/TCP HTTPS)" "sidecar"
            puller = container "Storage Helper/Puller" "Downloads model artifacts from S3/GCS/Azure to shared volume" "Go Sidecar" "sidecar"
            modelServer = container "Model Server" "Inference runtime (Triton, MLServer, OVMS, or TorchServe)" "Various (8001/7070 TCP gRPC)" "runtime"
        }

        etcd = softwareSystem "etcd" "Key-value store for model registry, VModel state, and event coordination" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "API server for CRD management, RBAC, and resource lifecycle" "External"
        s3 = softwareSystem "S3/GCS/Azure Storage" "Object storage for ML model artifacts" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning for webhook server" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "External"
        kserve = softwareSystem "KServe" "Shared CRD types (InferenceService); companion inference platform" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Companion controller managing InferenceService lifecycle" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for model management; consumes Grafana dashboards" "Internal RHOAI"

        # Relationships
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService CRs" "kubectl / Dashboard"
        platformOp -> modelmeshServing "Configures ServingRuntimes, etcd secrets, storage credentials" "kubectl / Kustomize"

        controller -> k8sAPI "Watches CRDs, CRUD for Deployments/Services/Secrets" "HTTPS/443 Bearer Token"
        predictorReconciler -> mmContainer "SetVModel, DeleteVModel, GetVModelStatus" "gRPC/8033 TLS mTLS"
        srReconciler -> k8sAPI "Creates/updates runtime Deployments and HPAs" "HTTPS/443 Bearer Token"
        serviceReconciler -> k8sAPI "Creates Services and ServiceMonitors" "HTTPS/443 Bearer Token"

        mmContainer -> etcd "Model registry, VModel state, event watch" "gRPC/2379 TLS"
        puller -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        oauthProxy -> restProxy "Proxied inference requests" "HTTP/8008 localhost"
        restProxy -> mmContainer "gRPC inference forwarding" "gRPC/8033 localhost"
        mmContainer -> modelServer "Model loading/inference" "gRPC/8001 or 7070 localhost"

        dataScientist -> oauthProxy "Inference requests" "HTTPS/8443 OAuth Token"

        modelmeshServing -> certManager "Webhook TLS certificates" "Certificate CRD"
        modelmeshServing -> prometheusOp "ServiceMonitor for metrics" "ServiceMonitor CRD"
        kserve -> modelmeshServing "Shared InferenceService CRD" "CRD"
        odhModelController -> modelmeshServing "Co-manages InferenceService lifecycle" "CRD Watch"
        dashboard -> modelmeshServing "UI management; Grafana dashboards" "ConfigMap"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshServing "ControlPlaneContainers" {
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
            element "controller" {
                background #4a90e2
                color #ffffff
            }
            element "webhook" {
                background #e74c3c
                color #ffffff
            }
            element "sidecar" {
                background #2ecc71
                color #ffffff
            }
            element "runtime" {
                background #f39c12
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
