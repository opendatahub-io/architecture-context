workspace {
    model {
        // Users
        dataScientist = person "Data Scientist" "Creates and deploys machine learning models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and performance"
        endUser = person "End User / Application" "Consumes inference API endpoints for predictions"

        // KServe System
        kserve = softwareSystem "KServe" "Cloud-native model inference platform providing standardized ML model serving on Kubernetes with autoscaling, canary deployments, and multi-framework support" {
            controlPlane = container "KServe Control Plane" "Manages InferenceService lifecycle and orchestration" "Go Operator" {
                controller = component "kserve-controller-manager" "Reconciles InferenceService, ServingRuntime, InferenceGraph, and TrainedModel CRDs" "Go Controller"
                webhook = component "kserve-webhook-server" "Validates and mutates InferenceService resources; injects sidecars" "Go Webhook Server"
            }

            dataPlane = container "KServe Data Plane" "Serves inference requests using model servers" "Multi-framework Runtime" {
                storageInitializer = component "storage-initializer" "Downloads model artifacts from S3/GCS/Azure before model server starts" "Python Init Container"
                modelServer = component "Model Server Runtimes" "Framework-specific serving containers (sklearn, xgboost, tensorflow, pytorch, triton, etc.)" "Python/C++"
                agent = component "kserve-agent" "Provides request logging, response logging, and batching" "Go Sidecar"
                router = component "kserve-router" "Routes requests through multi-step inference graphs" "Go Service"
                explainer = component "Explainer Servers" "Model explanation services (Alibi, ART)" "Python"
            }
        }

        // External Dependencies
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, VirtualServices, and Gateways" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless platform for autoscaling and scale-to-zero capabilities" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        // Internal ODH/RHOAI Components
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versioning, and lineage" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for creating and managing InferenceServices" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration for training and deployment" "Internal ODH"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication and authorization for inference endpoints" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides mTLS encryption and traffic routing for all services" "Internal ODH"

        // External Services
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (primary backend for RHOAI)" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage (optional)" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage (optional)" "External"

        // User Relationships
        dataScientist -> odhDashboard "Creates InferenceServices via web UI"
        dataScientist -> kserve "Creates InferenceService CRs via kubectl/API"
        mlEngineer -> kserve "Configures ServingRuntimes and InferenceGraphs"
        mlEngineer -> prometheus "Monitors model server metrics"
        endUser -> kserve "Sends inference requests to model endpoints" "HTTPS/443"

        // KServe Internal Relationships
        controller -> webhook "Validates resources during admission"
        webhook -> kubernetes "Watches and mutates Kubernetes resources" "HTTPS/6443"
        controller -> kubernetes "Creates Deployments, Services, VirtualServices" "HTTPS/6443"
        storageInitializer -> modelServer "Loads model artifacts to shared volume" "Filesystem"
        agent -> modelServer "Wraps requests for logging and batching" "HTTP/8080"
        router -> modelServer "Routes to multiple models in InferenceGraph" "HTTP/8080 mTLS"
        explainer -> modelServer "Calls predictor for explanation generation" "HTTP/8080 mTLS"

        // KServe External Dependencies
        kserve -> istio "Uses for traffic routing, canary deployments, and mTLS" "VirtualService/Gateway CRDs"
        kserve -> knativeServing "Uses for serverless autoscaling and scale-to-zero" "Knative Service CRD"
        kserve -> kubernetes "Orchestrates containers and manages resources" "HTTPS/6443"
        kserve -> s3Storage "Downloads model artifacts during initialization" "HTTPS/443"
        kserve -> gcsStorage "Downloads model artifacts (optional)" "HTTPS/443"
        kserve -> azureStorage "Downloads model artifacts (optional)" "HTTPS/443"

        // KServe Internal ODH Dependencies
        kserve -> serviceMesh "Uses for mTLS encryption and traffic management"
        kserve -> openshiftOAuth "Uses for Bearer Token authentication"
        kserve -> modelRegistry "Fetches model metadata and versioning" "gRPC/9090"
        odhDashboard -> kserve "Creates and manages InferenceServices via API" "HTTPS/443"
        dataSciencePipelines -> kserve "Auto-deploys models after training" "InferenceService CR"

        // Monitoring
        prometheus -> kserve "Scrapes /metrics endpoints from model servers" "HTTP/8080"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout
            description "System context diagram for KServe showing external dependencies and internal ODH/RHOAI integrations"
        }

        container kserve "Containers" {
            include *
            autoLayout
            description "Container diagram showing KServe control plane and data plane components"
        }

        component controlPlane "ControlPlaneComponents" {
            include *
            autoLayout
            description "Components within KServe control plane (controller and webhook)"
        }

        component dataPlane "DataPlaneComponents" {
            include *
            autoLayout
            description "Components within KServe data plane (model servers, agent, router, explainer)"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
