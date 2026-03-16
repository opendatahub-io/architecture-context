workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys machine learning models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and runtimes"
        endUser = person "End User / Application" "Consumes ML inference predictions via API"

        # KServe System
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs; orchestrates model deployments" "Go Operator" {
                reconciler = component "CR Reconciler" "Watches and reconciles KServe custom resources"
                resourceManager = component "Resource Manager" "Creates/updates Knative Services, Deployments, VirtualServices"
                leaderElection = component "Leader Election" "Ensures single active controller instance"
            }

            webhook = container "Webhook Server" "Validates and mutates InferenceService CRs; injects sidecars and init containers" "Go Service" {
                validator = component "Validation Handler" "Validates InferenceService, ServingRuntime, TrainedModel specs"
                mutator = component "Mutation Handler" "Defaults fields, injects storage-initializer and agent"
            }

            agent = container "KServe Agent" "Sidecar for request logging, batching, and model pulling" "Go Sidecar"

            router = container "KServe Router" "Routes inference requests in multi-model InferenceGraph pipelines" "Go Service"

            storageInit = container "Storage Initializer" "Downloads models from S3/GCS/Azure/HTTP to local volumes" "Python Init Container"

            runtimes = container "Serving Runtimes" "Framework-specific inference servers (sklearn, xgboost, tensorflow, pytorch, mlserver)" "Python/C++"
        }

        # External Dependencies
        knative = softwareSystem "Knative Serving" "Serverless platform providing scale-to-zero autoscaling and request-based scaling" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic routing, mTLS encryption, and VirtualService management" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning and rotation" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"

        # Internal ODH Dependencies
        modelMesh = softwareSystem "ModelMesh Serving" "Alternative high-density multi-model serving solution" "Internal ODH"
        odhModelController = softwareSystem "ODH Model Controller" "Model registry integration and deployment orchestration" "Internal ODH"
        authorino = softwareSystem "Authorino" "OAuth2/OIDC token validation and authorization" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science components" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"

        # External Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts (AWS S3, MinIO, Ceph)" "External Storage"
        gcsStorage = softwareSystem "Google Cloud Storage" "Google Cloud object storage for model artifacts" "External Storage"
        azureStorage = softwareSystem "Azure Blob Storage" "Microsoft Azure object storage for model artifacts" "External Storage"
        modelRegistry = softwareSystem "External Model Registry" "MLflow, Seldon, or custom model metadata repositories" "External"

        # Relationships - User interactions
        dataScientist -> kserve "Creates InferenceService CRs via kubectl/UI"
        mlEngineer -> kserve "Configures ServingRuntimes and ClusterServingRuntimes"
        endUser -> kserve "Sends inference requests via HTTPS"

        # Relationships - KServe internal
        controller -> webhook "Registers mutating/validating webhooks"
        webhook -> kubernetes "Called by API Server during CR admission"
        controller -> kubernetes "Creates/manages Knative Services, Deployments, VirtualServices"
        storageInit -> runtimes "Provisions model files in shared volume"
        agent -> runtimes "Proxies inference requests, logs responses"
        router -> runtimes "Routes InferenceGraph requests to multiple models"

        # Relationships - External dependencies
        kserve -> knative "Uses for serverless autoscaling and scale-to-zero" "HTTPS/6443 (CRD reconciliation)"
        kserve -> istio "Uses for traffic routing, canary deployments, and mTLS" "HTTPS/6443 (VirtualService CRD)"
        kserve -> certManager "Obtains TLS certificates for webhook server" "HTTPS/6443 (Certificate CRD)"
        kserve -> kubernetes "Runs on Kubernetes, watches CRDs via API Server" "HTTPS/6443"
        kserve -> prometheus "Exposes metrics for controller and runtimes" "HTTP/8080 (scrape)"

        # Relationships - Internal ODH integrations
        kserve -> modelMesh "CRD sharing for alternative serving strategy" "API coordination"
        kserve -> odhModelController "Integrates for model registry metadata" "Service coordination"
        kserve -> authorino "Optional OAuth2/OIDC validation for inference endpoints" "Istio AuthorizationPolicy"
        odhDashboard -> kserve "Provides UI for managing InferenceServices" "Kubernetes API"
        dsPipelines -> kserve "Auto-deploys models from pipeline outputs" "Kubernetes API"

        # Relationships - External services
        storageInit -> s3Storage "Downloads model artifacts during pod initialization" "HTTPS/443 (AWS SigV4)"
        storageInit -> gcsStorage "Downloads model artifacts during pod initialization" "HTTPS/443 (GCP SA)"
        storageInit -> azureStorage "Downloads model artifacts during pod initialization" "HTTPS/443 (Azure creds)"
        kserve -> modelRegistry "Fetches model metadata and download URIs" "HTTP/HTTPS (REST/gRPC)"

        # Observability
        agent -> prometheus "Sends CloudEvents for logging" "HTTP/80 (mTLS)"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout tb
        }

        container kserve "KServeContainers" {
            include *
            autoLayout tb
        }

        component controller "KServeControllerComponents" {
            include *
            autoLayout tb
        }

        component webhook "KServeWebhookComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }

            element "Software System" {
                background #1168bd
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
                background #f39c12
                color #000000
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

        themes default
    }

    configuration {
        scope softwaresystem
    }
}
