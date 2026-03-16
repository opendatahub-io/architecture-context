workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models for serving"
        client = softwareSystem "Client Application" "Consumes inference API for predictions" "External"

        modelmesh = softwareSystem "ModelMesh Serving" "High-performance, high-density model serving platform for frequently-changing model use cases" {
            controller = container "modelmesh-controller" "Manages model serving lifecycle" "Go Operator" {
                reconciler = component "Reconciler" "Reconciles Predictor, ServingRuntime CRs" "Go"
                webhook = component "Validating Webhook" "Validates ServingRuntime resources" "Go"
            }

            servingPod = container "Serving Runtime Pod" "Hosts model serving components" "Container Group" {
                modelmeshSvc = component "ModelMesh" "Model placement, routing, lifecycle management" "Java Service"
                restProxy = component "REST Proxy" "Translates KServe V2 REST to gRPC" "Go Service"
                adapter = component "Runtime Adapter/Puller" "Pulls models from storage, adapts to frameworks" "Go Service"
                mlFramework = component "ML Framework" "Executes model inference" "Triton/MLServer/OpenVINO/TorchServe"
            }
        }

        etcd = softwareSystem "etcd Cluster" "Distributed key-value store for ModelMesh coordination and state management" "External Dependency"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        istio = softwareSystem "Istio / Service Mesh" "Traffic management, mTLS, authorization" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for TLS" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for model management" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"

        # User interactions
        user -> modelmesh "Creates Predictor, ServingRuntime CRs via kubectl/UI"
        user -> dashboard "Manages models via web interface"

        # Client interactions
        client -> modelmesh "Sends inference requests" "gRPC/8033 or REST/8008"

        # Controller interactions
        controller -> kubernetes "Reconciles CRs, manages Deployments, Services" "HTTPS/6443"
        controller -> etcd "Registers models, updates metadata" "TCP/2379"

        # Serving pod interactions
        servingPod -> etcd "Coordinates model placement, state" "TCP/2379"
        servingPod -> s3 "Downloads model artifacts" "HTTPS/443"
        servingPod -> istio "Uses for traffic routing, mTLS"

        # Internal component interactions
        reconciler -> webhook "Validates resources before admission"
        restProxy -> modelmeshSvc "Translates REST to gRPC" "gRPC/8033"
        modelmeshSvc -> adapter "Routes inference requests" "gRPC/UDS"
        adapter -> mlFramework "Executes model inference" "Framework-specific"

        # Monitoring
        prometheus -> modelmesh "Scrapes metrics" "HTTP/8443, HTTP/2112"

        # Certificate management
        certManager -> modelmesh "Issues TLS certificates" "Kubernetes CR"

        # ODH integrations
        dashboard -> modelmesh "Manages InferenceServices via API"
        pipelines -> modelmesh "Auto-deploys models after training"

        # Dependencies
        modelmesh -> istio "Uses for traffic management and mTLS"
        modelmesh -> kubernetes "Runs on Kubernetes platform"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
        }

        container modelmesh "Containers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component servingPod "ServingPodComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Dependency" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5da5e8
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #333333
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
