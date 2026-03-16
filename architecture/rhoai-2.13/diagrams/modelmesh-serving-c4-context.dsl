workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        appDeveloper = person "Application Developer" "Builds applications that consume model predictions"

        # ModelMesh Serving System
        modelmeshServing = softwareSystem "ModelMesh Serving" "Controller for managing ModelMesh deployments - multi-model serving platform" {
            controller = container "ModelMesh Controller" "Manages Predictor, ServingRuntime, and InferenceService CRDs" "Go Operator" {
                predictorController = component "Predictor Controller" "Model lifecycle management" "Go Reconciler"
                runtimeController = component "ServingRuntime Controller" "Runtime provisioning and management" "Go Reconciler"
                serviceController = component "Service Controller" "Kubernetes Service management" "Go Reconciler"
                autoscalerController = component "Autoscaler Controller" "HPA management" "Go Reconciler"
            }

            webhookServer = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime resources" "Go ValidatingWebhook"

            runtimePod = container "Runtime Pod" "Multi-container pod for model serving" "Kubernetes Pod" {
                modelmesh = component "ModelMesh" "Model routing and placement orchestration" "Java Runtime"
                runtimeAdapter = component "Runtime Adapter" "Model pull, load, and unload intermediary" "Go Service"
                restProxy = component "REST Proxy" "KServe V2 REST to gRPC translation" "Go Service"
                storageHelper = component "Storage Helper" "S3 model artifact retrieval" "Go Service"
                modelServer = component "Model Server" "Actual model inference execution" "Triton/MLServer/OVMS/TorchServe"
            }
        }

        # External Dependencies
        etcd = softwareSystem "etcd" "Distributed key-value store for model metadata and state" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts (MinIO, AWS S3)" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and management" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Optional"

        # Model Server Runtimes (Container Images)
        triton = softwareSystem "Triton Inference Server" "NVIDIA runtime for TensorFlow, PyTorch, ONNX, TensorRT models" "External Runtime"
        mlserver = softwareSystem "MLServer" "Python-based runtime for sklearn, xgboost, lightgbm models" "External Runtime"
        ovms = softwareSystem "OpenVINO Model Server" "Intel runtime for OpenVINO IR and ONNX models" "External Runtime"
        torchserve = softwareSystem "TorchServe" "PyTorch runtime for PyTorch models" "External Runtime"

        # Relationships - People to Systems
        dataScientist -> modelmeshServing "Creates Predictor and ServingRuntime CRs via kubectl"
        appDeveloper -> modelmeshServing "Sends inference requests to model endpoints" "gRPC/8033, REST/8008"

        # Relationships - Controller to External Systems
        controller -> kubernetes "Watches CRDs, manages Deployments, Services, HPAs" "HTTPS/443"
        controller -> etcd "Stores and retrieves model metadata" "HTTP/2379"
        webhookServer -> kubernetes "Receives validation requests from API server" "HTTPS/9443"
        webhookServer -> certManager "Obtains TLS certificates for webhook endpoint" "K8s API"

        # Relationships - Runtime Pod to External Systems
        storageHelper -> s3Storage "Downloads model artifacts" "HTTPS/443 or HTTP/9000"
        runtimeAdapter -> storageHelper "Requests model download" "gRPC/8086"
        modelmesh -> runtimeAdapter "Delegates model load/unload" "gRPC/8085"
        restProxy -> modelmesh "Translates REST to gRPC" "gRPC/8033"
        runtimeAdapter -> modelServer "Loads models and invokes inference" "gRPC/HTTP"

        # Relationships - Runtime Pod to Model Servers
        modelServer -> triton "Uses Triton runtime image" "Container"
        modelServer -> mlserver "Uses MLServer runtime image" "Container"
        modelServer -> ovms "Uses OVMS runtime image" "Container"
        modelServer -> torchserve "Uses TorchServe runtime image" "Container"

        # Relationships - Monitoring
        controller -> prometheus "Exposes controller metrics" "HTTPS/8443"
        modelmesh -> prometheus "Exposes runtime metrics" "HTTP/2112"

        # Relationships - Controller Internal
        controller -> runtimePod "Manages lifecycle, communicates with ModelMesh" "gRPC/8033"
        predictorController -> modelmesh "Registers and loads models" "gRPC/8033"
        runtimeController -> kubernetes "Provisions runtime Deployments" "HTTPS/443"
        serviceController -> kubernetes "Creates and manages Services" "HTTPS/443"
        autoscalerController -> kubernetes "Creates and manages HPAs" "HTTPS/443"

        # Application to Runtime Pod
        appDeveloper -> runtimePod "Sends inference requests" "gRPC/8033 or REST/8008"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout lr
        }

        container modelmeshServing "Containers" {
            include *
            autoLayout lr
        }

        component controller "ControllerComponents" {
            include *
            autoLayout lr
        }

        component runtimePod "RuntimePodComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "External Runtime" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
