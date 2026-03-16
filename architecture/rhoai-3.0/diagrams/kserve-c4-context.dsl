workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Creates and deploys machine learning models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving runtimes and infrastructure"
        endUser = person "End User / Application" "Consumes ML inference APIs for predictions"

        # KServe System
        kserve = softwareSystem "KServe" "Cloud-native model inference platform providing standardized serving for predictive and generative AI models on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, and related CRDs to create model serving deployments" "Go Operator" {
                tags "Control Plane"
            }

            webhook = container "Webhook Server" "Validates and mutates InferenceService CRs, injects storage-initializer into pods" "Go Service" {
                tags "Control Plane"
            }

            storageInitializer = container "Storage Initializer" "Downloads model artifacts from S3, GCS, Azure Blob, or HTTP sources" "Python Init Container" {
                tags "Data Plane"
            }

            agent = container "KServe Agent" "Model lifecycle manager injected as sidecar into inference pods" "Go Sidecar" {
                tags "Data Plane"
            }

            router = container "InferenceGraph Router" "Routes inference requests through multi-model pipelines (transformer → predictor → explainer)" "Go Service" {
                tags "Data Plane"
            }

            modelServers = container "Model Servers" "Runtime engines for serving ML models (HuggingFace, Sklearn, XGBoost, TorchServe, Triton)" "Python/Java Services" {
                tags "Data Plane"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and routing" "External" {
            tags "External"
        }

        knative = softwareSystem "Knative Serving" "Serverless platform for request-based autoscaling and scale-to-zero" "External" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "Kubernetes add-on for TLS certificate management" "External" {
            tags "External"
        }

        # Internal ODH/RHOAI Components
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and lineage" "Internal ODH" {
            tags "Internal ODH"
        }

        authorino = softwareSystem "Authorino" "Token-based authorization service for inference endpoints" "Internal ODH" {
            tags "Internal ODH"
        }

        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration for training and deployment automation" "Internal ODH" {
            tags "Internal ODH"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science components and deployments" "Internal ODH" {
            tags "Internal ODH"
        }

        # External Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts (AWS S3, MinIO, etc.)" "External Service" {
            tags "External Service"
        }

        gcsStorage = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" "External Service" {
            tags "External Service"
        }

        azureBlob = softwareSystem "Azure Blob Storage" "Microsoft Azure storage for model artifacts" "External Service" {
            tags "External Service"
        }

        huggingFaceHub = softwareSystem "HuggingFace Hub" "Repository for pre-trained LLM and transformer models" "External Service" {
            tags "External Service"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "Monitoring" {
            tags "Monitoring"
        }

        # Relationships - User Interactions
        dataScientist -> kserve "Creates InferenceService CRs to deploy models via kubectl/oc"
        mlEngineer -> kserve "Configures ServingRuntimes and ClusterServingRuntimes"
        endUser -> kserve "Sends inference requests via HTTPS REST API" "HTTPS/443"

        # Relationships - KServe Internal
        controller -> webhook "Triggers validation/mutation for CRD operations"
        controller -> modelServers "Creates and manages model server deployments"
        controller -> router "Deploys InferenceGraph routers for multi-model pipelines"
        storageInitializer -> modelServers "Provides downloaded model artifacts via shared volume"
        agent -> modelServers "Manages model lifecycle (load, unload, health)"
        router -> modelServers "Routes requests to predictor/transformer/explainer services"

        # Relationships - External Dependencies
        kserve -> kubernetes "Manages pods, deployments, services, and CRDs via Kubernetes API" "HTTPS/6443"
        kserve -> istio "Creates VirtualServices and DestinationRules for traffic routing and mTLS" "HTTPS/6443"
        kserve -> knative "Creates Knative Services for serverless autoscaling" "HTTPS/6443"
        kserve -> certManager "Requests TLS certificates for webhook server" "HTTPS/6443"

        # Relationships - Internal ODH/RHOAI
        kserve -> modelRegistry "Fetches model metadata and versioning information" "HTTP/8080"
        kserve -> authorino "Enforces token-based authorization for inference endpoints" "AuthorizationPolicy"
        dsPipelines -> kserve "Auto-deploys trained models as InferenceServices"
        odhDashboard -> kserve "Provides UI for managing InferenceService deployments"

        # Relationships - External Services
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443 (AWS SigV4)"
        storageInitializer -> gcsStorage "Downloads model artifacts" "HTTPS/443 (GCP Service Account)"
        storageInitializer -> azureBlob "Downloads model artifacts" "HTTPS/443 (Azure Storage Key)"
        storageInitializer -> huggingFaceHub "Downloads LLM and transformer models" "HTTPS/443 (HF Token)"

        # Relationships - Monitoring
        kserve -> prometheus "Exposes controller and model server metrics" "HTTP/8080, HTTPS/8443"
        prometheus -> kserve "Scrapes metrics from ServiceMonitors"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout lr
            title "KServe System Context Diagram"
            description "High-level view of KServe and its interactions with users, external dependencies, and internal ODH/RHOAI components"
        }

        container kserve "Containers" {
            include *
            autoLayout lr
            title "KServe Container Diagram"
            description "Internal components of KServe platform: control plane (controller, webhook) and data plane (storage-initializer, agent, router, model servers)"
        }

        dynamic kserve "InferenceServiceDeployment" "Sequence of creating and serving an InferenceService" {
            dataScientist -> controller "Creates InferenceService CR"
            controller -> webhook "Validates and mutates CR"
            controller -> kubernetes "Creates Deployment/KnativeService"
            controller -> istio "Creates VirtualService for routing"
            kubernetes -> storageInitializer "Starts init container"
            storageInitializer -> s3Storage "Downloads model artifacts"
            storageInitializer -> modelServers "Provides model via shared volume"
            endUser -> istio "Sends inference request"
            istio -> modelServers "Routes request with mTLS"
            modelServers -> endUser "Returns prediction result"
            autoLayout lr
            title "InferenceService Deployment and Inference Flow"
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

            element "Control Plane" {
                background #4a90e2
                color #ffffff
            }

            element "Data Plane" {
                background #50c878
                color #ffffff
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }

            element "External Service" {
                background #f5a623
                color #ffffff
            }

            element "Monitoring" {
                background #e6522c
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
