workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        platformAdmin = person "Platform Admin" "Manages serving runtimes and platform configuration"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes controller that manages multi-model serving deployments with intelligent model placement" {
            controller = container "modelmesh-controller" "Main controller managing ServingRuntime, Predictor, and Service reconciliation" "Go controller-runtime operator"
            serviceReconciler = container "ServiceReconciler" "Manages headless Services, TLS secrets, and ServiceMonitors" "Controller"
            servingRuntimeReconciler = container "ServingRuntimeReconciler" "Generates runtime Deployment manifests with ModelMesh sidecars" "Controller"
            predictorReconciler = container "PredictorReconciler" "Manages model lifecycle via ModelMesh" "Controller"
            hpaReconciler = container "HPAReconciler" "Manages HorizontalPodAutoscaler resources" "Controller"
            webhook = container "ServingRuntimeWebhook" "Validates autoscaler config on ServingRuntime/ClusterServingRuntime" "Validating Webhook (9443/TCP TLS)"
            eventStream = container "ModelMeshEventStream" "Watches etcd for model lifecycle events" "Background Service"
            grpcResolver = container "GrpcResolver" "Custom gRPC name resolver via Kubernetes Endpoints" "Background Service"
        }

        modelmeshRuntime = softwareSystem "ModelMesh Runtime Pods" "Runtime Deployments hosting ModelMesh sidecars and inference runtimes" {
            modelmeshSidecar = container "ModelMesh Sidecar" "Model placement, routing, and caching across pods" "Java Service"
            runtimeAdapter = container "modelmesh-runtime-adapter" "Intermediary for model pull/load operations" "Go Service"
            restProxy = container "REST Proxy" "Translates KServe V2 REST API to gRPC" "Go Service (8008/TCP)"
            inferenceRuntime = container "Inference Runtime" "Model serving engine (Triton, MLServer, OVMS, TorchServe)" "Third-party container"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model metadata coordination" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Certificate provisioning and rotation" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Metrics collection via ServiceMonitor CRDs" "External"
        objectStorage = softwareSystem "Object Storage" "S3-compatible model artifact storage" "External"

        # User interactions
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService CRs" "kubectl / Dashboard"
        platformAdmin -> modelmeshServing "Manages ServingRuntime/ClusterServingRuntime CRs" "kubectl"

        # Controller dependencies
        modelmeshServing -> k8sAPI "CRUD on Deployments, Services, Secrets, ConfigMaps, CRDs" "HTTPS/6443 TLS 1.2+"
        modelmeshServing -> etcd "Model metadata coordination and event streaming" "gRPC/2379 TLS"
        modelmeshServing -> modelmeshRuntime "Model lifecycle operations (load/unload/status)" "gRPC TLS"
        modelmeshServing -> certManager "Webhook TLS certificate provisioning" "Kubernetes API"
        modelmeshServing -> prometheusOperator "Creates ServiceMonitor resources" "Kubernetes API"

        # Runtime dependencies
        modelmeshRuntime -> etcd "Model placement coordination" "gRPC/2379 TLS"
        modelmeshRuntime -> objectStorage "Downloads model artifacts" "HTTPS/443"

        # Inference flow
        dataScientist -> modelmeshRuntime "Sends inference requests" "gRPC/REST"
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

        container modelmeshRuntime "RuntimeContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #6c8ebf
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
