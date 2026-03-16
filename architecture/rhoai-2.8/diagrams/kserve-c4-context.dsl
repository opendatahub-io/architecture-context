workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"
        client = person "API Client" "Consumes inference predictions from deployed models"

        kserve = softwareSystem "KServe" "Serverless ML inference platform providing standardized model serving on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and InferenceGraph CRDs; manages Knative Services and Istio VirtualServices" "Go Operator" {
                reconciler = component "Reconciler" "Watches and reconciles KServe custom resources"
                resourceManager = component "Resource Manager" "Creates and manages Knative Services, Deployments, VirtualServices"
            }

            webhook = container "Webhook Server" "Validates and mutates InferenceService, TrainedModel, and InferenceGraph resources; injects model puller containers" "Go Admission Controller" {
                validator = component "Validator" "Validates CR specifications"
                mutator = component "Mutator" "Injects init containers and sidecars"
            }

            agent = container "Agent" "Downloads models from storage to local filesystem for serving containers" "Go Sidecar"
            storageInit = container "Storage Initializer" "Pre-loads models into shared volume before serving container starts" "Go Init Container"
            router = container "Router" "Routes requests through InferenceGraph pipelines enabling transformers and ensembles" "Go Service"

            modelServers = container "Model Servers" "Framework-specific serving containers for TensorFlow, PyTorch, XGBoost, ONNX, etc." "Python/C++" {
                predictor = component "Predictor" "Performs model inference"
                transformer = component "Transformer" "Pre/post-processes inference data"
                explainer = component "Explainer" "Provides model explanations"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        knative = softwareSystem "Knative Serving" "Serverless deployment platform with autoscaling and revision management" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic routing, VirtualServices, and mTLS" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Internal ODH Dependencies
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration and automation" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "User interface for RHOAI platform" "Internal ODH"
        authorino = softwareSystem "Authorino" "Token-based authentication service" "Internal ODH"

        # External Services
        s3 = softwareSystem "S3 Storage" "AWS S3 for model artifact storage" "External"
        gcs = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" "External"
        registry = softwareSystem "Container Registry" "Container image registry for model server images" "External"

        # Relationships - Users
        user -> kserve "Creates InferenceService via kubectl/API"
        client -> kserve "Sends inference requests" "HTTPS/443"

        # Relationships - KServe Internal
        controller -> webhook "Coordinates with"
        controller -> knative "Creates Knative Services"
        controller -> istio "Creates VirtualServices for traffic routing"
        controller -> kubernetes "Manages Deployments, Services, ConfigMaps, Secrets"

        webhook -> kubernetes "Validates and mutates resources via admission webhooks"

        agent -> s3 "Downloads model artifacts" "HTTPS/443"
        agent -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInit -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInit -> gcs "Downloads model artifacts" "HTTPS/443"

        router -> modelServers "Routes inference requests through pipeline"

        # Relationships - External Dependencies
        kserve -> certManager "Requests TLS certificates for webhooks"
        kserve -> prometheus "Exposes metrics" "HTTP/8080"
        kserve -> kubernetes "Runs on"
        kserve -> knative "Uses for serverless autoscaling"
        kserve -> istio "Uses for traffic management and mTLS"

        # Relationships - Internal ODH
        kserve -> modelRegistry "Fetches model metadata" "HTTP/gRPC"
        kserve -> authorino "Integrates for authentication" "AuthorizationPolicy"
        dsPipelines -> kserve "Triggers automated model deployment" "K8s API"
        dashboard -> kserve "Provides UI for InferenceService management" "K8s API"

        # Relationships - External Services
        modelServers -> s3 "Loads model artifacts" "HTTPS/443"
        modelServers -> gcs "Loads model artifacts" "HTTPS/443"
        kubernetes -> registry "Pulls model server images" "HTTPS/443"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout
        }

        component modelServers "ModelServerComponents" {
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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

        theme default
    }
}
