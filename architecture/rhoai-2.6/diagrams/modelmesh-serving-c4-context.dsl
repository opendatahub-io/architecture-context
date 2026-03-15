workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and manages machine learning models for inference"
        admin = person "Platform Administrator" "Manages ModelMesh infrastructure and serving runtimes"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform for ML inference at scale" {
            controller = container "modelmesh-controller" "Manages ModelMesh lifecycle and resources" "Go Operator" {
                reconciler = component "Reconciler" "Watches CRDs and reconciles desired state"
                deploymentManager = component "Deployment Manager" "Creates/updates runtime deployments"
                etcdClient = component "etcd Client" "Manages model registry state"
            }

            webhook = container "Validating Webhook" "Validates ServingRuntime configurations" "Go Admission Controller"

            runtimePod = container "Runtime Pod" "Multi-model serving pod" "Container Pod" {
                modelMesh = component "ModelMesh" "Model routing, placement, caching orchestration"
                runtimeAdapter = component "Runtime Adapter" "Bridges ModelMesh to model server"
                modelRuntime = component "Model Runtime" "Executes inference (Triton/MLServer/OpenVINO/TorchServe)"
                storageHelper = component "Storage Helper" "Retrieves model artifacts"
                restProxy = component "REST Proxy" "Translates REST to gRPC"
            }
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry" "External"
        s3 = softwareSystem "S3 Object Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        kubernetes = softwareSystem "Kubernetes API Server" "Cluster orchestration and CRD storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"

        serviceMesh = softwareSystem "Service Mesh (Istio)" "mTLS enforcement and traffic management" "Internal ODH/RHOAI"
        dashboard = softwareSystem "ODH/RHOAI Dashboard" "Web UI for model deployment and management" "Internal ODH/RHOAI"

        # User interactions
        user -> dashboard "Deploys models via web UI"
        user -> kubernetes "Creates Predictor/ServingRuntime CRs via kubectl"

        # Dashboard interactions
        dashboard -> kubernetes "Manages resources via K8s API" "HTTPS/6443"

        # Controller interactions
        kubernetes -> controller "Notifies of CR changes" "Watch API"
        controller -> kubernetes "Creates/updates Deployments, Services" "HTTPS/6443"
        controller -> etcd "Stores model registry state" "gRPC/HTTPS/2379"
        controller -> webhook "Validates configurations" "HTTPS/9443"
        controller -> prometheus "Exposes metrics" "HTTPS/8443"
        webhook -> certManager "Obtains TLS certificates" "K8s API"

        # Runtime pod interactions
        runtimePod -> etcd "Reads model registry" "gRPC/HTTPS/2379"
        storageHelper -> s3 "Downloads model artifacts" "HTTPS/443"
        user -> runtimePod "Sends inference requests" "HTTP/8008 or gRPC/8085"
        runtimePod -> serviceMesh "Uses for mTLS and AuthZ" "Service mesh sidecar"

        # Monitoring
        prometheus -> controller "Scrapes metrics" "HTTPS/8443"
        prometheus -> runtimePod "Scrapes runtime metrics" "HTTP/8080"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout lr
        }

        container modelmeshServing "Containers" {
            include *
            autoLayout tb
        }

        component controller "ControllerComponents" {
            include *
            autoLayout lr
        }

        component runtimePod "RuntimePodComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH/RHOAI" {
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
