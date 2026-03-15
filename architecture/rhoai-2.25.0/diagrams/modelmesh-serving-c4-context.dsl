workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and manages ML models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and infrastructure"
        client = person "API Client" "Consumes model inference endpoints"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes controller for multi-model serving with ModelMesh orchestration" {
            controller = container "modelmesh-controller" "Manages ServingRuntime, InferenceService, and Predictor lifecycle" "Go Operator" {
                reconciler = component "Reconciler" "Watches CRDs and reconciles desired state" "Controller Runtime"
                webhookServer = component "Webhook Server" "Validates ServingRuntime resources" "Admission Webhook"
                metricsExporter = component "Metrics Exporter" "Exposes Prometheus metrics" "kube-rbac-proxy"
            }

            runtimePod = container "Runtime Pod" "Multi-container pod for model serving" "Kubernetes Deployment" {
                modelMesh = component "ModelMesh" "Model orchestration and routing layer" "Java Runtime"
                restProxy = component "REST Proxy" "Translates KServe V2 REST to gRPC" "Go Service"
                runtimeAdapter = component "Runtime Adapter" "Bridges ModelMesh to model server" "Sidecar"
                modelServer = component "Model Server" "Executes model inference" "Triton/MLServer/OpenVINO/TorchServe"
                storagePuller = component "Storage Puller" "Downloads models from storage" "Init Container"
            }
        }

        etcd = softwareSystem "ETCD" "Distributed key-value store for model metadata and cluster state" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"
        kserve = softwareSystem "KServe" "Serverless model serving platform (shared CRD schema)" "Internal ODH"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Optional service mesh for mTLS and traffic management" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management" "Optional"

        # User interactions
        dataScientist -> modelmeshServing "Creates InferenceService and Predictor via kubectl"
        mlEngineer -> modelmeshServing "Configures ServingRuntime and ClusterServingRuntime"
        client -> modelmeshServing "Sends inference requests" "gRPC/8033 or HTTP/8008"

        # Controller interactions
        controller -> kubernetes "Manages deployments, services, configmaps, secrets" "HTTPS/6443"
        controller -> etcd "Coordinates cluster state (via created deployments)" "gRPC/2379"
        controller -> prometheus "Exposes controller metrics" "HTTPS/8443"
        controller -> certManager "Requests webhook TLS certificates" "K8s API"

        # Runtime pod interactions
        runtimePod -> etcd "Stores and retrieves model metadata" "gRPC/2379, Optional TLS"
        runtimePod -> s3 "Downloads model artifacts" "HTTPS/443, AWS Signature V4"
        runtimePod -> prometheus "Exposes runtime metrics" "HTTP/2112"
        runtimePod -> serviceMesh "Optional mTLS and traffic routing" "Service Mesh"

        # Integration points
        modelmeshServing -> kserve "Shares InferenceService CRD schema (v1beta1)" "CRD"
        kubernetes -> controller "Sends admission requests to webhook" "HTTPS/9443"

        # Component-level interactions
        modelMesh -> modelServer "Routes inference requests" "gRPC via UDS or 8001/TCP"
        restProxy -> modelMesh "Translates REST to gRPC" "gRPC/8033"
        storagePuller -> s3 "Pulls model files" "HTTPS/443"
        reconciler -> kubernetes "Reconciles CRDs and resources" "HTTPS/6443"
        webhookServer -> kubernetes "Validates ServingRuntime CRs" "HTTPS/9443"
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

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component runtimePod "RuntimePodComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Optional" {
                background #cccccc
                color #000000
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85c1e9
                color #000000
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
