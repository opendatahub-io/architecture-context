workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving runtimes and manages inference deployments"
        developer = person "Application Developer" "Consumes inference API endpoints for predictions"

        modelMeshServing = softwareSystem "ModelMesh Serving" "Multi-model serving system that provides intelligent model placement and routing for efficient resource utilization" {
            controller = container "modelmesh-controller" "Reconciles CRDs and manages ModelMesh runtime deployments" "Go Operator" {
                tags "Controller"
            }
            webhook = container "Webhook Server" "Validates ServingRuntime custom resources" "Go Service" {
                tags "Controller"
            }
            runtimePods = container "ModelMesh Runtime Pods" "Per-ServingRuntime deployments containing model mesh, runtime adapter, puller, and model server containers" "Multi-container Deployment" {
                modelMesh = component "ModelMesh" "Routes inference requests to appropriate models" "Go"
                restProxy = component "REST Proxy" "Translates KServe V2 REST to gRPC" "Go"
                puller = component "Storage Helper (Puller)" "Retrieves models from object storage" "Go"
                runtimeAdapter = component "Runtime Adapter" "Adapts ModelMesh to model server protocol" "Go"
                modelServer = component "Model Server" "Executes model inference" "Triton/MLServer/OpenVINO/TorchServe"
            }
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for ModelMesh state management and model placement coordination" "External"
        s3Storage = softwareSystem "S3/Minio Storage" "Model artifact storage" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Kubernetes cluster API server" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External (Optional)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External (Optional)"

        kserve = softwareSystem "KServe" "KServe platform for InferenceService CRD compatibility" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal RHOAI"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "mTLS encryption and traffic routing for inference requests" "Internal RHOAI (Optional)"

        # User interactions
        dataScientist -> modelMeshServing "Creates Predictor CRs to deploy models" "kubectl/YAML"
        mlEngineer -> modelMeshServing "Defines ServingRuntime CRs for model formats" "kubectl/YAML"
        developer -> modelMeshServing "Sends inference requests" "gRPC/REST (KServe V2 protocol)"

        # Component relationships
        controller -> kubernetesAPI "Reconciles CRDs, creates Deployments/Services" "HTTPS/6443"
        webhook -> kubernetesAPI "Registered as ValidatingWebhook" "HTTPS/9443"
        controller -> etcd "Manages model placement state" "HTTP/2379"
        controller -> runtimePods "Creates and manages" "Kubernetes Resources"

        runtimePods -> etcd "Coordinates model placement and routing" "HTTP/2379"
        runtimePods -> s3Storage "Retrieves model artifacts" "HTTPS/443"

        modelMesh -> etcd "Distributed state management" "HTTP/2379"
        puller -> s3Storage "Downloads models" "HTTPS/443"
        restProxy -> modelMesh "Translates REST to gRPC" "gRPC/8033"
        modelMesh -> runtimeAdapter "Routes inference requests" "gRPC/8085"
        runtimeAdapter -> modelServer "Executes inference" "gRPC/8001"
        puller -> modelServer "Loads models" "gRPC/8001"

        # External integrations
        prometheus -> controller "Scrapes controller metrics" "HTTPS/8443"
        prometheus -> runtimePods "Scrapes runtime metrics" "HTTP/2112"
        certManager -> webhook "Provisions TLS certificates" "Certificate CRDs"
        certManager -> controller "Provisions metrics endpoint TLS" "Certificate CRDs"

        # RHOAI integrations
        modelMeshServing -> kserve "Optional InferenceService CRD compatibility" "CRD Reconciliation"
        modelMeshServing -> modelRegistry "Fetches model metadata" "S3-compatible storage integration"
        serviceMesh -> runtimePods "Provides mTLS for inference traffic" "Istio sidecar injection"
    }

    views {
        systemContext modelMeshServing "SystemContext" {
            include *
            autoLayout lr
        }

        container modelMeshServing "Containers" {
            include *
            autoLayout tb
        }

        component runtimePods "RuntimeComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Internal RHOAI (Optional)" {
                background #b8e986
                color #000000
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
        }

        theme default
    }
}
