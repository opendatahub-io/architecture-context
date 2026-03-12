workspace {
    name "Open Data Hub 3.3.0 Platform"
    description "End-to-end AI/ML platform for OpenShift"

    model {
        // People
        dataScientist = person "Data Scientist" "Develops ML models, runs experiments, deploys models"
        mlEngineer = person "ML Engineer" "Builds ML pipelines, manages model deployment, monitors production models"
        platformAdmin = person "Platform Admin" "Manages ODH platform, configures components, monitors infrastructure"

        // Open Data Hub Platform
        odh = softwareSystem "Open Data Hub 3.3.0" "Cloud-native AI/ML platform for OpenShift" {
            // Control Plane
            odhOperator = container "ODH Operator" "Platform orchestration" "Go Operator" "Manages all components via DataScienceCluster CRD"
            dashboard = container "ODH Dashboard" "Web UI" "React/Node.js" "Unified interface for platform management and user workflows"

            // Development
            notebookController = container "Notebook Controller" "Workbench manager" "Kubeflow Operator" "Manages Jupyter notebook lifecycle"
            notebooks = container "Notebook Workbenches" "Development environments" "Jupyter/VSCode/RStudio" "Pre-configured images with ML frameworks (PyTorch, TensorFlow)"

            // Model Serving
            kserve = container "KServe" "Model serving platform" "Go Operator + Predictors" "Multi-framework inference with autoscaling and GPU support"
            odhModelController = container "ODH Model Controller" "KServe extensions" "Go Controller" "OpenShift integrations: Routes, NIM, LLM services"

            // Model Management
            modelRegistry = container "Model Registry" "Model versioning" "Python/Go" "Model metadata, lineage, and versioning"
            mlflow = container "MLflow" "Experiment tracking" "Python" "Tracking server for experiments and model registry"

            // Training
            trainingOperator = container "Training Operator" "Distributed training" "Go Operator" "PyTorch, TensorFlow, MPI, JAX, XGBoost jobs"
            trainerV2 = container "Trainer v2" "LLM fine-tuning" "Go Operator" "Next-gen training for LLMs with JobSet"
            kuberay = container "KubeRay" "Ray clusters" "Go Operator" "Distributed computing for ML workloads"
            sparkOperator = container "Spark Operator" "Big data processing" "Go Operator" "Apache Spark on Kubernetes"

            // ML Workflows
            dspOperator = container "Data Science Pipelines" "ML workflow orchestration" "Go Operator + Argo" "Kubeflow Pipelines integration"

            // Data & Governance
            feast = container "Feast" "Feature store" "Go Operator + Python" "ML feature management and serving"
            trustyai = container "TrustyAI" "AI governance" "Java Service" "Explainability, fairness, LLM evaluation"

            // LLM Tools
            llamaStack = container "Llama Stack" "LLM development" "Go Operator" "Llama Stack integration for LLM workflows"

            // Relationships within ODH
            odhOperator -> dashboard "manages"
            odhOperator -> notebookController "manages"
            odhOperator -> kserve "manages"
            odhOperator -> modelRegistry "manages"
            odhOperator -> mlflow "manages"
            odhOperator -> trainingOperator "manages"
            odhOperator -> trainerV2 "manages"
            odhOperator -> kuberay "manages"
            odhOperator -> sparkOperator "manages"
            odhOperator -> dspOperator "manages"
            odhOperator -> feast "manages"
            odhOperator -> trustyai "manages"
            odhOperator -> llamaStack "manages"

            dashboard -> notebookController "creates Notebook CRs"
            dashboard -> kserve "creates InferenceService CRs"
            dashboard -> modelRegistry "reads model metadata"

            notebookController -> notebooks "deploys"
            notebooks -> dspOperator "executes pipelines" "REST API"
            notebooks -> modelRegistry "registers models" "REST API"
            notebooks -> mlflow "logs experiments" "REST API"
            notebooks -> kserve "deploys models" "kubectl"

            kserve -> odhModelController "extended by"
            kserve -> modelRegistry "fetches model metadata" "REST API"
            kserve -> trustyai "monitored by" "gRPC"

            dspOperator -> trainingOperator "orchestrates training jobs"
            dspOperator -> kserve "orchestrates model deployment"
            dspOperator -> modelRegistry "tracks pipeline models"

            trainingOperator -> mlflow "logs metrics" "REST API"
            trainerV2 -> mlflow "logs metrics" "REST API"

            feast -> trainingOperator "serves features to" "gRPC"
            feast -> kserve "serves features to" "gRPC"

            trustyai -> kserve "monitors inferences"
        }

        // External Systems
        istio = softwareSystem "Istio" "Service mesh" "External Dependency" {
            description "Traffic management, mTLS, AuthZ policies"
        }
        knative = softwareSystem "Knative Serving" "Serverless platform" "External Dependency" {
            description "Autoscaling (0-N) for KServe predictors"
        }
        certManager = softwareSystem "cert-manager" "Certificate management" "External Dependency" {
            description "TLS certificate provisioning and rotation"
        }
        openshift = softwareSystem "OpenShift" "Kubernetes platform" "External Dependency" {
            description "Container orchestration, networking, storage"
        }

        s3Storage = softwareSystem "S3 Storage" "Object storage" "External Service" {
            description "Model artifacts, datasets, pipeline artifacts"
        }
        postgresql = softwareSystem "PostgreSQL/MySQL" "Relational database" "External Service" {
            description "Metadata persistence for Model Registry, MLflow, Pipelines"
        }
        huggingface = softwareSystem "HuggingFace Hub" "Model repository" "External Service" {
            description "LLM models and datasets"
        }
        containerRegistry = softwareSystem "Container Registry" "Image registry" "External Service" {
            description "Container images (quay.io, gcr.io, docker.io)"
        }

        // User interactions
        dataScientist -> dashboard "accesses platform" "HTTPS/Browser"
        dataScientist -> notebooks "develops models" "HTTPS/Browser"
        mlEngineer -> dashboard "manages deployments" "HTTPS/Browser"
        mlEngineer -> dspOperator "creates pipelines" "kubectl/UI"
        platformAdmin -> odhOperator "configures platform" "kubectl"

        // External client interactions
        externalClient = person "External Client" "Sends inference requests to deployed models"
        externalClient -> kserve "inference requests" "HTTPS/REST"

        // ODH dependencies on external systems
        kserve -> istio "uses for traffic routing"
        kserve -> knative "uses for autoscaling"
        kserve -> certManager "uses for certificates"
        modelRegistry -> certManager "uses for certificates"
        mlflow -> certManager "uses for certificates"

        odh -> openshift "deployed on" "Kubernetes API"

        // External service dependencies
        kserve -> s3Storage "loads model artifacts" "HTTPS/AWS IAM"
        notebooks -> s3Storage "reads/writes data" "HTTPS/AWS IAM"
        trainingOperator -> s3Storage "reads training data" "HTTPS/AWS IAM"
        dspOperator -> s3Storage "stores pipeline artifacts" "HTTPS/AWS IAM"

        modelRegistry -> postgresql "stores metadata" "PostgreSQL/5432"
        mlflow -> postgresql "stores metadata" "PostgreSQL/5432"
        dspOperator -> postgresql "stores metadata" "PostgreSQL/5432"

        notebooks -> huggingface "downloads models" "HTTPS"
        trustyai -> huggingface "downloads models" "HTTPS"

        odh -> containerRegistry "pulls images" "HTTPS/Docker API"
    }

    views {
        systemContext odh "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Open Data Hub 3.3.0 platform"
        }

        container odh "Containers" {
            include *
            autoLayout
            description "Container diagram showing ODH platform components"
        }

        systemContext odh "DevelopmentWorkflow" {
            include dataScientist dashboard notebookController notebooks mlflow modelRegistry kserve s3Storage huggingface
            autoLayout lr
            description "Data scientist development workflow"
        }

        systemContext odh "ServingWorkflow" {
            include externalClient kserve odhModelController istio knative modelRegistry trustyai feast s3Storage
            autoLayout lr
            description "Model serving and inference workflow"
        }

        systemContext odh "TrainingWorkflow" {
            include mlEngineer dspOperator trainingOperator trainerV2 kuberay mlflow modelRegistry s3Storage
            autoLayout lr
            description "ML training and pipeline workflow"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
