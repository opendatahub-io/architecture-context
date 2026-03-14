workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using the platform"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and monitoring"
        platformAdmin = person "Platform Administrator" "Configures and maintains RHOAI platform components"

        // RHOAI Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 3.3.0" "Enterprise AI/ML platform for end-to-end ML lifecycle management on OpenShift" {
            // Control Plane
            rhods = container "RHODS Operator" "Central platform orchestrator managing component lifecycle" "Go Operator v1.6.0" "Control Plane"

            // Application Layer
            dashboard = container "ODH Dashboard" "Unified web UI for managing projects, workbenches, models, and pipelines" "React 18 + PatternFly 6 v1.21.0" "Application"
            notebookController = container "Notebook Controller" "Manages Jupyter/RStudio/VS Code workbench lifecycle" "Go Operator v1.27.0" "Application"
            modelController = container "Model Controller" "Extends KServe with OpenShift Routes, KEDA, and NIM" "Go Operator v1.27.0" "Application"

            // Core Services
            kserve = container "KServe" "Kubernetes-native model serving with autoscaling" "Go v0.15" "Core Service"
            dspOperator = container "Data Science Pipelines Operator" "ML workflow orchestration based on Kubeflow Pipelines v2" "Go v0.0.1" "Core Service"
            modelRegistry = container "Model Registry" "Model metadata storage and versioning" "Go Operator 4fdd8de" "Core Service"
            mlflow = container "MLflow" "Experiment tracking and model management" "Python Operator 49b5d8d" "Core Service"
            feast = container "Feast" "Feature store for online/offline feature access" "Go Operator 98a224e" "Core Service"

            // Training Infrastructure
            trainingOperator = container "Training Operator" "Distributed training for PyTorch, TensorFlow, XGBoost, MPI, JAX" "Go v1.9.0" "Training"
            trainer = container "Trainer (Kubeflow)" "LLM fine-tuning with progression tracking" "Go v2.1.0" "Training"

            // Supporting Services
            kuberay = container "KubeRay Operator" "Manages Ray clusters for distributed computing" "Go v1.4.2" "Support"
            trustyai = container "TrustyAI Service Operator" "Model explainability, fairness, and LLM guardrails" "Python v1.39.0" "Support"
            llamaStack = container "Llama Stack Operator" "Deploys Llama Stack servers with Ollama/vLLM" "Go v0.6.0" "Support"
        }

        // OpenShift Platform
        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes platform providing infrastructure, networking, and security" "External Platform"

        // Service Mesh & Serverless
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and observability" "External Infrastructure"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling and revision management" "External Infrastructure"

        // Security & Certificates
        oauth = softwareSystem "OpenShift OAuth" "User authentication and authorization" "External Security"
        certManager = softwareSystem "cert-manager" "TLS certificate management and auto-rotation" "External Security"

        // Storage Systems
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts, datasets, and pipeline outputs (AWS S3, MinIO, etc.)" "External Storage"
        databases = softwareSystem "Databases" "PostgreSQL, MySQL, MariaDB, Redis for metadata and feature storage" "External Storage"

        // External Services
        containerRegistry = softwareSystem "Container Registries" "Container image storage (quay.io, registry.redhat.io)" "External Service"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External Service"
        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA GPU Cloud for NIM models and configs" "External Service"

        // Observability
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Observability"
        grafana = softwareSystem "Grafana" "Metrics visualization and dashboards" "External Observability"

        // User Relationships
        dataScientist -> dashboard "Uses web UI to manage notebooks, models, and pipelines" "HTTPS (OAuth)"
        dataScientist -> notebookController "Creates and manages Jupyter/RStudio workbenches via" "Kubernetes API"
        dataScientist -> kserve "Deploys models via InferenceService CRs" "Kubernetes API"
        dataScientist -> dspOperator "Submits ML pipelines" "HTTPS API"

        mlEngineer -> dashboard "Monitors model serving and pipeline status" "HTTPS (OAuth)"
        mlEngineer -> kserve "Manages serving runtimes and inference graphs" "Kubernetes API"
        mlEngineer -> trustyai "Configures model monitoring and fairness checks" "Kubernetes API"

        platformAdmin -> rhods "Deploys and configures platform components via DataScienceCluster CR" "Kubernetes API"
        platformAdmin -> dashboard "Manages platform settings and user access" "HTTPS (OAuth)"

        // RHOAI Internal Relationships
        rhods -> dashboard "Manages lifecycle"
        rhods -> notebookController "Manages lifecycle"
        rhods -> modelController "Manages lifecycle"
        rhods -> kserve "Manages lifecycle"
        rhods -> dspOperator "Manages lifecycle"
        rhods -> modelRegistry "Manages lifecycle"
        rhods -> mlflow "Manages lifecycle"
        rhods -> feast "Manages lifecycle"
        rhods -> trainingOperator "Manages lifecycle"
        rhods -> trainer "Manages lifecycle"
        rhods -> kuberay "Manages lifecycle"
        rhods -> trustyai "Manages lifecycle"
        rhods -> llamaStack "Manages lifecycle"

        dashboard -> kserve "Creates InferenceServices" "REST API"
        dashboard -> modelRegistry "Queries model metadata" "REST API"
        dashboard -> dspOperator "Manages pipeline runs" "REST API"
        dashboard -> feast "Manages feature stores" "REST API"

        notebookController -> mlflow "Notebooks log experiments to" "HTTPS"
        notebookController -> modelRegistry "Notebooks register models in" "HTTPS"
        notebookController -> trainingOperator "Notebooks launch training jobs via" "Kubernetes API"

        modelController -> kserve "Extends with Routes, NetworkPolicies, KEDA" "Kubernetes API"
        modelController -> nvidiaNGC "Validates NIM accounts" "HTTPS API"

        kserve -> modelRegistry "Fetches model metadata" "gRPC"
        kserve -> feast "Retrieves online features" "gRPC/HTTP"
        kserve -> trustyai "Sends inference payloads to" "HTTP (mTLS)"

        dspOperator -> kserve "Creates InferenceServices from pipelines" "Kubernetes API"
        dspOperator -> trainingOperator "Launches distributed training jobs" "Kubernetes API"
        dspOperator -> modelRegistry "Reads model metadata" "gRPC"

        trustyai -> kserve "Monitors InferenceServices" "HTTP (mTLS)"

        // RHOAI to OpenShift Platform
        rhoai -> openshift "Runs on, uses Kubernetes API, RBAC, networking" "Kubernetes API"
        rhoai -> oauth "Authenticates users via" "OAuth 2.0"
        rhoai -> certManager "Obtains TLS certificates from" "Kubernetes API"

        // RHOAI to Service Mesh & Serverless
        kserve -> istio "Uses for traffic routing, mTLS, and VirtualServices" "Istio API"
        kserve -> knative "Uses for autoscaling and revision management" "Kubernetes API"
        trustyai -> istio "Uses for service-to-service mTLS" "Istio API"
        dspOperator -> istio "Uses for pipeline component communication" "Istio API"

        // RHOAI to Storage
        kserve -> s3Storage "Loads model artifacts from" "HTTPS (AWS S3 API)"
        trainingOperator -> s3Storage "Stores trained models in" "HTTPS (AWS S3 API)"
        trainer -> s3Storage "Stores fine-tuned LLMs in" "HTTPS (AWS S3 API)"
        dspOperator -> s3Storage "Stores pipeline artifacts in" "HTTPS (AWS S3 API)"
        mlflow -> s3Storage "Stores experiment artifacts in" "HTTPS (AWS S3 API)"

        modelRegistry -> databases "Stores model metadata in PostgreSQL/MySQL" "PostgreSQL/MySQL Protocol"
        mlflow -> databases "Stores experiment metadata in PostgreSQL" "PostgreSQL Protocol"
        feast -> databases "Stores features in PostgreSQL/Redis" "PostgreSQL/Redis Protocol"
        dspOperator -> databases "Stores pipeline metadata in MariaDB" "MySQL Protocol"
        trustyai -> databases "Stores inference logs in PostgreSQL" "PostgreSQL Protocol"

        // RHOAI to External Services
        notebookController -> containerRegistry "Pulls notebook images from" "HTTPS (Docker Registry API)"
        trainingOperator -> huggingFace "Downloads models and datasets from" "HTTPS"
        trainer -> huggingFace "Downloads LLMs for fine-tuning from" "HTTPS"
        llamaStack -> huggingFace "Downloads Llama models from" "HTTPS"

        // RHOAI to Observability
        rhoai -> prometheus "Exports metrics to" "HTTP (ServiceMonitor)"
        prometheus -> grafana "Sends metrics to" "HTTP"
        mlEngineer -> grafana "Views dashboards in" "HTTPS"
        dataScientist -> grafana "Views experiment metrics in" "HTTPS"
    }

    views {
        systemContext rhoai "RHOAISystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Red Hat OpenShift AI 3.3.0 showing external dependencies and actors"
        }

        container rhoai "RHOAIContainers" {
            include *
            autoLayout tb
            description "Container diagram showing major components of Red Hat OpenShift AI 3.3.0"
        }

        dynamic rhoai "ModelTrainingToDeployment" "Model Training to Deployment Workflow" {
            dataScientist -> dashboard "1. Create notebook"
            dashboard -> notebookController "2. Deploy workbench"
            notebookController -> trainingOperator "3. Launch training job"
            trainingOperator -> s3Storage "4. Store trained model"
            notebookController -> mlflow "5. Log experiment"
            notebookController -> modelRegistry "6. Register model"
            dashboard -> kserve "7. Create InferenceService"
            kserve -> s3Storage "8. Load model"
            kserve -> modelRegistry "9. Fetch metadata"
            modelController -> kserve "10. Add Route"
            autoLayout
            description "Typical workflow from model development to production deployment"
        }

        styles {
            element "Control Plane" {
                background #e74c3c
                color #ffffff
            }
            element "Application" {
                background #3498db
                color #ffffff
            }
            element "Core Service" {
                background #2ecc71
                color #ffffff
            }
            element "Training" {
                background #9b59b6
                color #ffffff
            }
            element "Support" {
                background #1abc9c
                color #ffffff
            }
            element "External Platform" {
                background #95a5a6
                color #ffffff
            }
            element "External Infrastructure" {
                background #7f8c8d
                color #ffffff
            }
            element "External Security" {
                background #f39c12
                color #ffffff
            }
            element "External Storage" {
                background #e67e22
                color #ffffff
            }
            element "External Service" {
                background #bdc3c7
                color #000000
            }
            element "External Observability" {
                background #16a085
                color #ffffff
            }
        }
    }
}
