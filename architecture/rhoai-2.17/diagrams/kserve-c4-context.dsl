workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        endUser = person "End User" "Consumes ML predictions via API calls"

        # KServe System
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for predictive and generative ML models with standardized inference protocols" {
            # Control Plane
            controller = container "KServe Controller Manager" "Reconciles InferenceService, InferenceGraph, ServingRuntime, TrainedModel CRDs" "Go Operator" {
                tags "ControlPlane"
            }
            webhook = container "Webhook Server" "Validates and mutates InferenceService resources, injects sidecars" "Go Service" {
                tags "ControlPlane"
            }

            # Data Plane
            storageInit = container "Storage Initializer" "Downloads models from cloud storage into serving containers" "Python Init Container" {
                tags "DataPlane"
            }
            agent = container "KServe Agent" "Manages model lifecycle, health checks, request batching" "Go Sidecar" {
                tags "DataPlane"
            }
            modelServer = container "Model Servers" "Framework-specific inference servers (sklearn, xgboost, huggingface, custom)" "Python Runtimes" {
                tags "DataPlane"
            }
            router = container "KServe Router" "Routes requests through InferenceGraph pipelines for multi-model ensembles" "Go Service" {
                tags "DataPlane"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling and traffic routing platform" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and authorization" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management" "External"

        # Internal ODH/RHOAI Dependencies
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides VirtualService, Gateway, and mTLS for InferenceServices" "Internal ODH"
        authorino = softwareSystem "Authorino" "Request authentication and authorization for inference endpoints" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versioning, and lineage" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing InferenceServices and model deployments" "Internal ODH"
        dataScienceCluster = softwareSystem "DataScienceCluster" "Operator-managed cluster configuration that enables/disables KServe" "Internal ODH"

        # Storage Systems
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Storage"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage for GCP" "External Storage"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage for Azure" "External Storage"

        # Relationships - Users to KServe
        dataScientist -> kserve "Creates InferenceService, manages models" "kubectl/oc CLI"
        dataScientist -> odhDashboard "Manages models via web UI" "HTTPS"
        endUser -> kserve "Sends inference requests" "HTTPS (REST/gRPC)"

        # Relationships - KServe Containers
        dataScientist -> controller "Creates InferenceService CR" "Kubernetes API"
        controller -> webhook "Validates/mutates InferenceServices" "HTTPS/9443"
        controller -> modelServer "Creates and manages" "Kubernetes API"
        controller -> agent "Injects as sidecar" "Pod mutation"
        storageInit -> modelServer "Provides model artifacts" "Volume mount"
        agent -> modelServer "Manages lifecycle, routes requests" "HTTP/8080"
        router -> modelServer "Routes multi-model requests" "HTTP/80, mTLS"
        endUser -> router "Sends InferenceGraph requests" "HTTPS/443"

        # Relationships - KServe to External Dependencies
        kserve -> kubernetes "Manages workloads, watches CRDs" "HTTPS/6443"
        kserve -> knativeServing "Uses for serverless autoscaling" "Kubernetes API"
        kserve -> istio "Uses for traffic routing and mTLS" "xDS API/15010"
        kserve -> certManager "Provisions webhook TLS certificates" "Kubernetes API"

        # Relationships - KServe to Internal ODH/RHOAI
        kserve -> serviceMesh "Creates VirtualServices and Gateways for external access" "Kubernetes API"
        kserve -> authorino "Enforces JWT authentication and authorization" "gRPC/5001"
        kserve -> modelRegistry "Fetches model metadata and versioning" "HTTP/8080"
        odhDashboard -> kserve "Manages InferenceServices via API" "Kubernetes API"
        dataScienceCluster -> kserve "Enables/disables component" "CRD watch"

        # Relationships - KServe to Storage
        storageInit -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS IAM"
        storageInit -> gcsStorage "Downloads model artifacts" "HTTPS/443, GCP SA"
        storageInit -> azureStorage "Downloads model artifacts" "HTTPS/443, Azure creds"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for KServe showing users, external dependencies, and ODH/RHOAI integrations"
        }

        container kserve "Containers" {
            include *
            autoLayout tb
            description "Container diagram for KServe showing control plane and data plane components"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "ControlPlane" {
                background #4a90e2
                color #ffffff
            }
            element "DataPlane" {
                background #50c878
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
