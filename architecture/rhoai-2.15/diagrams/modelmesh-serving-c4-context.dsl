workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys machine learning models for inference"
        admin = person "Platform Administrator" "Manages cluster-wide serving runtimes and infrastructure"
        inferenceClient = person "Application / End User" "Sends inference requests to deployed models"

        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform with intelligent routing and placement" {
            controller = container "modelmesh-controller" "Reconciles CRDs and manages ModelMesh infrastructure" "Go Operator" {
                tags "Controller"
            }
            webhook = container "Validation Webhook" "Validates ServingRuntime and ClusterServingRuntime specifications" "Go Webhook Server" {
                tags "Controller"
            }
            runtimePods = container "Runtime Pods" "Serves models via ModelMesh routing layer" "ModelMesh + Runtime + Adapter" {
                modelmesh_component = component "ModelMesh" "Intelligent routing and multi-model placement" "gRPC Service"
                adapter_component = component "Runtime Adapter" "Translates ModelMesh protocol to runtime-specific API" "gRPC Bridge"
                runtime_component = component "Model Server" "Executes inference (Triton/MLServer/OVMS/TorchServe)" "ML Runtime"
                restproxy_component = component "REST Proxy" "Translates REST API to gRPC" "HTTP-to-gRPC Gateway"
            }
            metricsService = container "Metrics Service" "Exposes Prometheus metrics with RBAC protection" "kube-rbac-proxy + Controller" {
                tags "Metrics"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and enforces RBAC" "External Kubernetes"
        etcd = softwareSystem "etcd" "Distributed key-value store for model metadata and routing" "External"
        s3 = softwareSystem "S3 / MinIO" "Object storage for trained model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides mTLS encryption and service discovery" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External Kubernetes"

        # User interactions
        user -> modelmesh "Creates Predictor and ServingRuntime CRs via kubectl/UI"
        admin -> modelmesh "Creates ClusterServingRuntime CRs for cluster-wide runtimes"
        inferenceClient -> runtimePods "Sends inference requests (gRPC/REST)" "8033/TCP gRPC, 8008/TCP HTTP/HTTPS"

        # Controller interactions
        modelmesh -> k8sAPI "Watches CRDs, creates Deployments/Services" "HTTPS/6443, TLS 1.2+"
        k8sAPI -> webhook "Validates ServingRuntime/ClusterServingRuntime CRs" "HTTPS/9443, mTLS"
        controller -> etcd "Stores runtime configuration metadata" "HTTP/HTTPS 2379, TLS optional"

        # Runtime pod interactions
        runtimePods -> etcd "Reads/writes model routing tables" "HTTP/HTTPS 2379, TLS optional"
        runtimePods -> s3 "Downloads model artifacts" "HTTPS/HTTP 443/9000, AWS SigV4"

        # Integration with ODH components
        prometheus -> metricsService "Scrapes controller metrics" "HTTPS/8443, ServiceAccount Token"
        prometheus -> runtimePods "Scrapes ModelMesh metrics" "HTTP/2112"
        runtimePods -> serviceMesh "Optional mTLS for inference traffic" "Envoy sidecar"
        runtimePods -> modelRegistry "May reference models from registry" "Storage reference"

        # Certificate management
        certManager -> webhook "Provisions TLS certificates for webhook server" "HTTPS/6443, TLS 1.2+"
        certManager -> runtimePods "Provisions optional TLS certs for inference endpoints" "HTTPS/6443, TLS 1.2+"
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
            description "System context diagram for ModelMesh Serving showing external dependencies and users"
        }

        container modelmesh "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of ModelMesh Serving"
        }

        component runtimePods "RuntimeComponents" {
            include *
            autoLayout
            description "Component diagram showing containers within a ModelMesh runtime pod"
        }

        styles {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Metrics" {
                background #f5a623
                color #000000
            }
        }

        theme default
    }
}
