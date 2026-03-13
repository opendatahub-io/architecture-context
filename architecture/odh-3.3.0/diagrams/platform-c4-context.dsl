workspace {
    model {
        dataScientist = person "Data Scientist" "Develops and deploys ML models using notebooks and pipelines"
        platformEngineer = person "Platform Engineer" "Manages ODH platform deployment and configuration"
        mlEngineer = person "ML Engineer" "Builds and maintains ML pipelines and model deployments"
        externalClient = person "External Client" "Consumes model inference APIs"

        odh = softwareSystem "Open Data Hub 3.3.0" "Cloud-native AI/ML platform for OpenShift providing end-to-end data science capabilities" {
            odhOperator = container "ODH Operator" "Central platform orchestrator" "Go Operator" "Manages component lifecycle via DataScienceCluster CRD"
            dashboard = container "ODH Dashboard" "Web UI for platform management" "React/Node.js" "Provides unified interface for notebooks, models, pipelines"
            
            kserve = container "KServe" "Model serving platform" "Go Operator" "Multi-framework inference with autoscaling and GPU support"
            modelController = container "ODH Model Controller" "OpenShift integrations for KServe" "Go Controller" "Routes, NIM, LLM services"
            
            notebookController = container "Notebook Controller" "Workbench management" "Go Operator (Kubeflow)" "Deploys Jupyter, VSCode, RStudio environments"
            notebookImages = container "Notebook Images" "Pre-configured workbench containers" "Container Images" "PyTorch, TensorFlow, JAX with CUDA support"
            
            modelRegistry = container "Model Registry" "Model versioning and lineage" "Go Operator + gRPC Service" "Tracks model versions and metadata"
            mlflow = container "MLflow" "Experiment tracking" "Python Application" "Logs experiments, metrics, parameters"
            
            trainingOperator = container "Training Operator" "Distributed training" "Go Operator (Kubeflow)" "PyTorch, TensorFlow, MPI, JAX, XGBoost jobs"
            trainer = container "Trainer v2" "LLM fine-tuning" "Go Operator" "DeepSpeed, Megatron with JobSet"
            
            pipelines = container "Data Science Pipelines" "ML workflow orchestration" "Kubeflow Pipelines" "Argo Workflows for training and deployment"
            feast = container "Feast" "Feature store" "Python/Go" "Feature management and serving"
            trustyai = container "TrustyAI" "AI governance" "Java Service" "Explainability, fairness, LLM evaluation"
            
            kuberay = container "KubeRay" "Ray distributed computing" "Go Operator" "Parallel processing and ML workloads"
            spark = container "Spark Operator" "Big data processing" "Go Operator" "Apache Spark on Kubernetes"
            llamaStack = container "Llama Stack" "LLM development platform" "Go Operator" "Llama model integration"
        }

        k8s = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and security" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"
        
        s3 = softwareSystem "S3-compatible Storage" "Object storage for models and data" "External"
        database = softwareSystem "PostgreSQL/MySQL" "Metadata databases" "External"
        huggingface = softwareSystem "HuggingFace Hub" "LLM model repository" "External"
        containerRegistry = softwareSystem "Container Registry" "Container image repository (quay.io, docker.io)" "External"
        pypi = softwareSystem "PyPI / pip index" "Python package repository" "External"

        # User interactions
        dataScientist -> dashboard "Accesses via browser (HTTPS)"
        dataScientist -> notebookImages "Develops models in"
        dataScientist -> kserve "Creates InferenceServices"
        mlEngineer -> pipelines "Creates ML workflows"
        platformEngineer -> odhOperator "Deploys via DataScienceCluster CR"
        externalClient -> kserve "Sends inference requests (HTTPS/gRPC)"

        # Core platform relationships
        odhOperator -> k8s "Manages components via"
        odhOperator -> dashboard "Deploys and manages"
        odhOperator -> kserve "Deploys and manages"
        odhOperator -> notebookController "Deploys and manages"
        odhOperator -> modelRegistry "Deploys and manages"
        odhOperator -> pipelines "Deploys and manages"
        odhOperator -> trainingOperator "Deploys and manages"

        # Dashboard integrations
        dashboard -> notebookController "Creates Notebook CRs via K8s API"
        dashboard -> kserve "Creates InferenceService CRs"
        dashboard -> modelRegistry "Creates ModelRegistry CRs"
        dashboard -> pipelines "Monitors pipeline status"
        dashboard -> trustyai "Monitors AI governance metrics"

        # Workbench workflows
        notebookController -> notebookImages "Deploys as StatefulSets"
        notebookImages -> mlflow "Logs experiments (REST API)"
        notebookImages -> modelRegistry "Registers models (gRPC/REST)"
        notebookImages -> feast "Reads features (Python SDK)"
        notebookImages -> kserve "Deploys models (K8s API)"
        notebookImages -> s3 "Loads data (HTTPS)"
        notebookImages -> pypi "Installs packages (HTTPS)"

        # Model serving flows
        kserve -> modelController "Extended by"
        kserve -> modelRegistry "Fetches model metadata (gRPC)"
        kserve -> trustyai "Monitored by (inference logging)"
        kserve -> istio "Uses for traffic routing and mTLS"
        kserve -> knative "Uses for autoscaling"
        kserve -> s3 "Downloads model artifacts (HTTPS)"
        kserve -> certManager "TLS certificates"

        # Training workflows
        trainingOperator -> mlflow "Logs training metrics (REST)"
        trainingOperator -> modelRegistry "Registers trained models (gRPC)"
        trainingOperator -> s3 "Loads data, saves checkpoints (HTTPS)"
        trainer -> mlflow "Logs LLM fine-tuning metrics"
        trainer -> modelRegistry "Registers fine-tuned models"
        trainer -> s3 "Loads data, saves checkpoints"
        trainer -> huggingface "Downloads LLM models (HTTPS)"

        # Pipeline orchestration
        pipelines -> trainingOperator "Orchestrates training jobs (K8s API)"
        pipelines -> trainer "Orchestrates LLM fine-tuning (K8s API)"
        pipelines -> kserve "Deploys models (K8s API)"
        pipelines -> modelRegistry "Tracks pipeline models (gRPC)"
        pipelines -> s3 "Stores pipeline artifacts (HTTPS)"
        pipelines -> database "Persists pipeline metadata (PostgreSQL/MySQL)"

        # Model and experiment management
        modelRegistry -> database "Persists metadata (PostgreSQL/MySQL)"
        modelRegistry -> certManager "TLS certificates"
        mlflow -> database "Persists experiments (PostgreSQL/MySQL)"
        mlflow -> s3 "Stores artifacts (HTTPS)"
        mlflow -> certManager "TLS certificates"

        # Distributed computing
        kuberay -> notebookImages "Used from notebooks (Ray SDK)"
        kuberay -> pipelines "Orchestrated by (K8s API)"
        spark -> pipelines "Orchestrated by (K8s API)"
        spark -> s3 "Reads/writes data (HTTPS)"

        # AI governance
        trustyai -> mlflow "Logs evaluation results (REST)"
        trustyai -> huggingface "Uses LLM evaluation models (HTTPS)"

        # Infrastructure dependencies
        dashboard -> k8s "K8s API (6443/TCP HTTPS)"
        kserve -> k8s "K8s API"
        notebookController -> k8s "K8s API"
        trainingOperator -> k8s "K8s API"
        pipelines -> k8s "K8s API"

        # Container image pulls
        notebookImages -> containerRegistry "Pulls base images (HTTPS)"
        kserve -> containerRegistry "Pulls runtime images (HTTPS)"
        trainingOperator -> containerRegistry "Pulls training images (HTTPS)"
    }

    views {
        systemContext odh "SystemContext" {
            include *
            autoLayout
        }

        container odh "Containers" {
            include *
            autoLayout
        }

        deployment odh "Production" "Deployment" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Go Operator" {
                background #7ed321
                color #000000
            }
            element "React/Node.js" {
                background #4a90e2
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
