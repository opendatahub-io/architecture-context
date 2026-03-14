workspace {
    model {
        user = person "Data Scientist" "Deploys and manages ML models for inference"
        admin = person "Platform Admin" "Configures ModelMesh infrastructure and runtimes"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving platform with intelligent model placement and routing" {
            controller = container "modelmesh-controller" "Manages ServingRuntime, Predictor, and InferenceService custom resources" "Go Operator" {
                tags "Controller"
            }
            webhook = container "Webhook Server" "Validates ServingRuntime and ClusterServingRuntime resources" "Go Admission Controller" {
                tags "Controller"
            }
            modelMesh = container "ModelMesh Runtime" "Model serving orchestration layer for placement and routing" "Java Runtime" {
                tags "Runtime"
            }
            restProxy = container "REST Proxy" "Translates KServe V2 REST API to gRPC" "HTTP Proxy" {
                tags "Runtime"
            }
            runtimeAdapter = container "Runtime Adapter" "Intermediary between ModelMesh and model servers" "Sidecar" {
                tags "Runtime"
            }
            puller = container "Storage Helper" "Retrieves models from storage backends" "Init Container" {
                tags "Runtime"
            }

            controller -> webhook "Validates via"
            controller -> modelMesh "Creates and manages"
            restProxy -> modelMesh "Translates REST to gRPC"
            modelMesh -> runtimeAdapter "Routes requests to"
            puller -> runtimeAdapter "Loads models for"
        }

        etcd = softwareSystem "ETCD" "Distributed key-value store for model metadata and cluster coordination" "External" {
            tags "External"
        }
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage backend" "External" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External" {
            tags "External" "Optional"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "External" "Optional"
        }

        kserve = softwareSystem "KServe" "Model serving platform sharing InferenceService CRD schema" "Internal RHOAI" {
            tags "Internal"
        }
        serviceMesh = softwareSystem "OpenShift Service Mesh" "mTLS and traffic management" "Internal RHOAI" {
            tags "Internal" "Optional"
        }

        # User interactions
        user -> modelmeshServing "Creates InferenceServices via kubectl/API" "HTTPS/6443"
        user -> modelmeshServing "Sends inference requests" "gRPC/8033, HTTP/8008"
        admin -> modelmeshServing "Configures ServingRuntimes and storage" "kubectl"

        # System interactions
        modelmeshServing -> etcd "Stores and retrieves model metadata" "HTTP/gRPC:2379"
        modelmeshServing -> kubernetes "Manages deployments and services" "HTTPS/6443"
        modelmeshServing -> s3 "Downloads model artifacts" "HTTPS/443"
        modelmeshServing -> certManager "Requests TLS certificates for webhooks" "K8s API"
        modelmeshServing -> prometheus "Exposes metrics" "HTTPS/8443, HTTP/2112"
        modelmeshServing -> kserve "Shares InferenceService CRD schema" "API compatibility"
        modelmeshServing -> serviceMesh "Integrates for mTLS and routing" "Service Mesh"

        # External to Internal
        kubernetes -> modelmeshServing "Calls webhook for validation" "HTTPS/9443"
        prometheus -> modelmeshServing "Scrapes metrics" "HTTPS/8443, HTTP/2112"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                opacity 60
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
