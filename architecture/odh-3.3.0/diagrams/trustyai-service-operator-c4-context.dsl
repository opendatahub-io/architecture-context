workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Monitors model fairness, drift, and evaluates LLMs"
        admin = person "Platform Administrator" "Deploys and manages TrustyAI services"

        trustyai = softwareSystem "TrustyAI Service Operator" "Kubernetes operator for AI governance and monitoring" {
            operator = container "TrustyAI Operator" "Manages TrustyAI-related CRDs and service deployments" "Go Controller"
            trustyaiService = container "TrustyAI Service" "Model explainability, fairness monitoring, data drift detection" "Quarkus Service"
            evalHub = container "EvalHub Service" "LLM evaluation hub with provider integration" "Python Service"
            guardrails = container "Guardrails Service" "FMS Guardrails orchestrator for LLM safety" "Python Service"
            nemoGuardrails = container "NeMo Guardrails Service" "NVIDIA NeMo Guardrails for LLM safety" "Python Service"
        }

        kserve = softwareSystem "KServe" "Model serving platform for ML inference" "External ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "MLOps workflow orchestration" "Internal ODH"

        postgresql = softwareSystem "PostgreSQL" "Relational database for persistence" "External"
        mlflow = softwareSystem "MLFlow" "Experiment tracking and model registry" "External"
        huggingface = softwareSystem "HuggingFace Hub" "LLM model repository" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for datasets and results" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        user -> trustyai "Calculates fairness metrics, generates explanations, submits LLM evaluation jobs"
        admin -> trustyai "Creates TrustyAIService, EvalHub, GuardrailsOrchestrator CRs via kubectl"
        user -> dashboard "Views TrustyAI metrics and manages services via UI"

        # TrustyAI internal relationships
        operator -> trustyaiService "Deploys and manages"
        operator -> evalHub "Deploys and manages"
        operator -> guardrails "Deploys and manages"
        operator -> nemoGuardrails "Deploys and manages"
        operator -> k8sAPI "Creates Jobs, Deployments, ConfigMaps, Secrets" "HTTPS/6443"

        # TrustyAI Service relationships
        trustyaiService -> kserve "Monitors model inferences via sidecar integration" "HTTP/8080"
        trustyaiService -> postgresql "Persists inference data, fairness metrics" "PostgreSQL/5432"
        trustyaiService -> modelRegistry "Retrieves model metadata" "gRPC/9090"
        trustyaiService -> prometheus "Exposes metrics" "HTTP/8080"

        # EvalHub relationships
        evalHub -> postgresql "Persists evaluation state and job results" "PostgreSQL/5432"
        evalHub -> mlflow "Tracks LLM evaluation experiments" "HTTP/5000"
        evalHub -> huggingface "Downloads LLM models for evaluation" "HTTPS/443"
        evalHub -> s3 "Stores evaluation datasets and results" "HTTPS/443"
        evalHub -> prometheus "Exposes metrics" "HTTP/8000"

        # Integration points
        dashboard -> trustyaiService "UI integration for service management" "HTTP/8080"
        dashboard -> evalHub "UI integration for evaluation management" "HTTP/8000"
        dsPipelines -> evalHub "Executes LM evaluation jobs as pipeline steps" "HTTP/8000"
        guardrails -> kserve "Provides guardrails for model deployments" "HTTP/8080"
    }

    views {
        systemContext trustyai "SystemContext" {
            include *
            autoLayout
        }

        container trustyai "Containers" {
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
            element "External ODH" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
