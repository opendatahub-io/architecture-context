workspace {
    model {
        # External Systems
        user = person "Data Scientist / ML Engineer" "Deploys and uses ML models for inference"
        client = softwareSystem "Client Application" "Applications consuming model predictions"

        # KServe System
        kserve = softwareSystem "KServe" "Standardized platform for generative and predictive AI model inference on Kubernetes" {
            controller = container "KServe Controller Manager" "Go" "Reconciles InferenceService CRDs and manages model serving lifecycle"
            llmController = container "LLM Inference Service Controller" "Go" "Manages LLM-specific inference services with vLLM backends"
            localModelController = container "Local Model Controller" "Go" "Manages local model caching and distribution"

            router = container "KServe Router" "Go" "Intelligent request routing between predictor, transformer, and explainer"
            agent = container "KServe Agent" "Go" "Manages model storage, logging, and batching (sidecar)"

            predictor = container "Predictor" "Python/Go" "Model serving runtime (TensorFlow, PyTorch, Triton, vLLM)"
            transformer = container "Transformer" "Python" "Pre/post-processing for model inputs/outputs"
            explainer = container "Explainer" "Python" "Model explanation and interpretability"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.24+)" "External"
        knative = softwareSystem "Knative Serving" "Serverless deployment, autoscaling, traffic management (1.10+)" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS, traffic routing, observability (1.17+)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks (1.12+)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring (2.40+)" "External"

        s3 = softwareSystem "S3/Minio" "Object storage for model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for model artifacts" "External"
        azure = softwareSystem "Azure Blob Storage" "Object storage for model artifacts" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Model repository and download" "External"

        # Internal ODH Dependencies
        dashboard = softwareSystem "ODH Dashboard" "Model serving UI and monitoring" "ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and lineage tracking" "ODH"
        odhOperator = softwareSystem "ODH Operator" "Manages KServe via DataScienceCluster" "ODH"
        osServerless = softwareSystem "OpenShift Serverless" "Knative for serverless inference" "ODH"
        osServiceMesh = softwareSystem "OpenShift Service Mesh" "Istio for mTLS and AuthZ" "ODH"

        # Relationships - User Interactions
        user -> kserve "Deploys models via InferenceService CRD"
        client -> kserve "Sends inference requests (HTTP/gRPC)"

        # Relationships - External Dependencies
        kserve -> kubernetes "Orchestrates containers and manages resources"
        kserve -> knative "Uses for autoscaling and serverless deployment"
        kserve -> istio "Uses for mTLS, traffic routing, and observability"
        kserve -> certManager "Gets TLS certificates for webhooks"
        kserve -> prometheus "Exposes metrics for monitoring"

        # Relationships - Storage
        agent -> s3 "Downloads model artifacts (AWS SigV4)"
        agent -> gcs "Downloads model artifacts (OAuth2)"
        agent -> azure "Downloads model artifacts (Azure AD)"
        agent -> huggingface "Downloads models (API token)"

        # Relationships - Internal ODH
        dashboard -> kserve "Integrates UI for model serving"
        modelRegistry -> controller "Provides model versioning via API"
        odhOperator -> controller "Manages via DataScienceCluster CRD"
        kserve -> osServerless "Uses Knative for autoscaling"
        kserve -> osServiceMesh "Uses Istio for mTLS and AuthZ"

        # Internal KServe Relationships
        controller -> kubernetes "Creates Deployments and Services"
        llmController -> kubernetes "Creates LLM inference services"
        localModelController -> kubernetes "Manages model cache nodes"

        router -> predictor "Routes inference requests"
        router -> transformer "Routes to pre-processing"
        router -> explainer "Routes to explainer"
        transformer -> predictor "Forwards transformed requests"
        predictor -> explainer "Requests explanations"

        agent -> predictor "Manages model lifecycle"
    }

    views {
        systemContext kserve "KServeContext" {
            include *
            autoLayout lr
        }

        container kserve "KServeContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH" {
                background #0066cc
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
