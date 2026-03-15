workspace {
    model {
        user = person "Data Scientist" "Deploys and manages ML model serving"
        inferenceUser = person "Application/End User" "Consumes ML model predictions via API"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Model serving management and routing layer for deploying machine learning models at scale" {
            controller = container "ModelMesh Controller" "Reconciles InferenceService, ServingRuntime, Predictor CRDs; manages model serving deployments" "Go Operator" {
                reconciler = component "Reconciler" "Watches CRDs and reconciles desired state"
                webhookServer = component "Webhook Server" "Validates ServingRuntime custom resources"
            }

            runtimePod = container "ModelMesh Runtime Pod" "Orchestrates model loading, routing, and inference execution" "Multi-container Pod" {
                modelmesh = component "ModelMesh" "Routes inference requests to loaded models"
                runtimeAdapter = component "Runtime Adapter" "Handles model pull, load, and unload operations"
                restProxy = component "REST Proxy" "Translates KServe V2 REST to gRPC"
                modelServer = component "Model Server" "Executes model inference (Triton/MLServer/etc)"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane" "External"
        etcd = softwareSystem "etcd" "Distributed key-value store for model metadata and placement" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts (MinIO, AWS S3)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        dashboard = softwareSystem "ODH/RHOAI Dashboard" "Web UI for model serving management" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Network proxy for ingress/egress routing and mTLS" "Internal ODH"

        # User interactions
        user -> modelmeshServing "Creates InferenceService, ServingRuntime, Predictor CRs via kubectl"
        user -> dashboard "Manages model deployments via UI"
        inferenceUser -> modelmeshServing "Sends inference requests" "HTTP/8008 or gRPC/8033"

        # Controller interactions
        modelmeshServing -> k8sAPI "Watches CRDs, creates Deployments/Services" "HTTPS/6443"
        modelmeshServing -> etcd "Stores/queries model metadata and routing" "HTTP/2379"
        modelmeshServing -> certManager "Requests TLS certificates for webhook" "K8s CRD"
        modelmeshServing -> s3Storage "Downloads model artifacts during loading" "HTTPS/443"
        modelmeshServing -> prometheus "Exposes metrics" "HTTP/8443, HTTP/2112"
        modelmeshServing -> serviceMesh "Optional: Routes traffic, enforces mTLS" "Sidecar"

        # Dashboard integration
        dashboard -> modelmeshServing "Deploys models via InferenceService API"

        # Monitoring
        prometheus -> modelmeshServing "Scrapes controller and runtime metrics"
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

        component runtimePod "RuntimeComponents" {
            include *
            autoLayout lr
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
            element "Software System" {
                background #4a90e2
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
        }
    }
}
