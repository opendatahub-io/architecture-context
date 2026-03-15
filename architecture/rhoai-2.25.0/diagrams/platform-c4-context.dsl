workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks, pipelines, and model serving"
        mlEngineer = person "ML Engineer" "Manages ML infrastructure, pipelines, and model deployments at scale"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform, configures quotas, monitors resource usage"

        # Main System
        rhoai = softwareSystem "Red Hat OpenShift AI" "Enterprise AI/ML platform for model development, training, serving, and governance" {
            # User Interface
            dashboard = container "ODH Dashboard" "Web UI for platform management and resource creation" "React + TypeScript" "WebUI"

            # Development Environment
            notebookController = container "Kubeflow Notebook Controller" "Manages Jupyter, VS Code, RStudio instances" "Go Operator"
            notebooks = container "Notebook Workbenches" "Interactive development environments" "JupyterLab, VS Code, RStudio" "DevEnv"

            # Model Serving
            kserve = container "KServe Operator" "Serverless model inference with autoscaling" "Go Operator + Python Runtime"
            modelMesh = container "ModelMesh Serving" "Multi-model serving with high-density placement" "Go Operator + Java Runtime"
            odhModelController = container "ODH Model Controller" "Manages Routes, AuthConfig, monitoring for inference" "Go Operator"
            llamaStack = container "Llama Stack Operator" "LLM inference server deployment" "Go Operator"

            # Training & Compute
            trainingOperator = container "Training Operator" "Distributed training for PyTorch, TensorFlow, XGBoost, MPI" "Go Operator"
            kuberay = container "KubeRay Operator" "Ray distributed computing cluster management" "Go Operator"
            codeflare = container "CodeFlare Operator" "Distributed AI/ML workload orchestration" "Go Operator"

            # Pipeline Orchestration
            dspa = container "Data Science Pipelines Operator" "ML workflow orchestration with Argo Workflows" "Go Operator"

            # Resource Management
            kueue = container "Kueue" "Job queueing and resource quota management" "Go Operator"

            # Model Lifecycle
            modelRegistry = container "Model Registry Operator" "Model metadata storage and versioning" "Go Operator + Python Service"
            feast = container "Feast Operator" "Feature store for ML feature management" "Go Operator + Python Service"

            # AI Governance
            trustyai = container "TrustyAI Service Operator" "AI explainability, bias detection, and guardrails" "Go Operator + Java Service"
        }

        # External Systems - Platform Infrastructure
        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes platform with OAuth, Routes, Monitoring" "External Platform"
        istio = softwareSystem "Istio/Maistra Service Mesh" "Service mesh for traffic routing, mTLS, telemetry" "External Platform"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"

        # External Systems - Storage & Data
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts and pipeline data" "External Storage" "AWS S3, Google Cloud Storage, Azure Blob, Minio"
        postgresql = softwareSystem "PostgreSQL" "Relational database for metadata storage" "External Database"
        mysql = softwareSystem "MySQL" "Relational database for metadata storage" "External Database"
        redis = softwareSystem "Redis" "In-memory data store for feature serving" "External Cache"

        # External Systems - Registries & Repositories
        containerRegistry = softwareSystem "Container Registries" "Container image repositories" "External Service" "quay.io, registry.redhat.io, nvcr.io"
        pypi = softwareSystem "Python Package Index" "Python package repository" "External Service"
        huggingface = softwareSystem "Hugging Face Hub" "Pretrained models and datasets" "External Service"
        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA NIM images and enterprise LLM models" "External Service"

        # External Systems - Cloud Data
        cloudDataWarehouses = softwareSystem "Cloud Data Warehouses" "Cloud-based data platforms for feature engineering" "External Data" "Snowflake, Redshift, BigQuery"

        # Relationships - Users to Platform
        dataScientist -> dashboard "Creates notebooks, inference services, pipelines via web UI" "HTTPS"
        dataScientist -> notebooks "Develops and trains models" "HTTPS (OAuth)"
        mlEngineer -> dashboard "Manages pipelines, model deployments, resource quotas" "HTTPS"
        mlEngineer -> dspa "Orchestrates ML workflows" "HTTPS (OAuth)"
        platformAdmin -> dashboard "Configures platform settings, monitors usage" "HTTPS"
        platformAdmin -> openshift "Manages cluster resources, RBAC, quotas" "CLI/Web Console"

        # Relationships - Dashboard to Components
        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API"
        dashboard -> kserve "Creates InferenceService CRs" "Kubernetes API"
        dashboard -> modelRegistry "Creates ModelRegistry CRs" "Kubernetes API"
        dashboard -> dspa "Creates DataSciencePipelinesApplication CRs" "Kubernetes API"
        dashboard -> trainingOperator "Creates PyTorchJob/TFJob CRs" "Kubernetes API"

        # Relationships - Model Serving
        kserve -> knative "Uses for autoscaling and serverless mode" "Kubernetes API"
        kserve -> istio "Uses for traffic routing and mTLS" "Kubernetes API"
        kserve -> odhModelController "Triggers for Route/AuthConfig creation" "CR Watch"
        kserve -> modelRegistry "Fetches model metadata" "gRPC/9090"
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443 (AWS IAM)"

        modelMesh -> s3Storage "Loads model artifacts" "HTTPS/443 (AWS IAM)"
        modelMesh -> postgresql "Stores model metadata" "PostgreSQL/5432"

        odhModelController -> istio "Creates VirtualServices, Gateways" "Kubernetes API"
        odhModelController -> openshift "Creates Routes for external access" "Kubernetes API"
        odhModelController -> prometheus "Creates ServiceMonitors" "Kubernetes API"

        llamaStack -> nvidiaNGC "Pulls NVIDIA NIM images" "HTTPS/443"
        llamaStack -> openshift "Creates Routes for LLM endpoints" "Kubernetes API"

        # Relationships - Pipeline Orchestration
        dspa -> kserve "Deploys models from pipelines" "Kubernetes API"
        dspa -> modelRegistry "Registers model artifacts and metadata" "REST API"
        dspa -> s3Storage "Stores pipeline artifacts" "HTTPS/443 (AWS IAM)"
        dspa -> postgresql "Stores pipeline metadata and runs" "PostgreSQL/5432"

        # Relationships - Training & Distributed Compute
        trainingOperator -> kueue "Submits jobs for quota-based scheduling" "Kubernetes API"
        trainingOperator -> s3Storage "Stores trained models" "HTTPS/443 (AWS IAM)"
        trainingOperator -> modelRegistry "Registers trained models" "REST API"

        kuberay -> kueue "Gang scheduling for Ray clusters" "Kubernetes API"
        kuberay -> pypi "Installs Python packages" "HTTPS/443"

        codeflare -> kuberay "Manages RayCluster CRs" "Kubernetes API"
        codeflare -> kueue "Submits AppWrapper for batch scheduling" "Kubernetes API"
        codeflare -> openshift "Uses OAuth for Ray dashboard access" "OAuth Proxy"

        # Relationships - Resource Management
        kueue -> trainingOperator "Admits training jobs based on quotas" "Kubernetes API"
        kueue -> kuberay "Admits RayCluster/RayJob" "Kubernetes API"
        kueue -> codeflare "Admits AppWrapper workloads" "Kubernetes API"
        kueue -> dspa "Schedules pipeline workflows" "Kubernetes API"

        # Relationships - Model Lifecycle
        modelRegistry -> postgresql "Stores ML Metadata" "PostgreSQL/5432"
        modelRegistry -> openshift "Uses OAuth for authentication" "OAuth"

        feast -> postgresql "Online and registry storage" "PostgreSQL/5432"
        feast -> redis "Online feature store" "Redis/6379"
        feast -> s3Storage "Offline feature store" "HTTPS/443"
        feast -> cloudDataWarehouses "Data source for feature materialization" "HTTPS/443"

        kserve -> feast "Fetches online features for inference" "gRPC"

        # Relationships - AI Governance
        trustyai -> kserve "Monitors InferenceService predictions" "HTTP (payload logging)"
        trustyai -> modelMesh "Monitors ModelMesh predictions" "HTTP (payload processor)"
        trustyai -> kueue "Submits LM evaluation jobs" "Kubernetes API"

        # Relationships - Development Environment
        notebookController -> notebooks "Deploys StatefulSets with workbench images" "Kubernetes API"
        notebooks -> s3Storage "Saves trained models" "HTTPS/443 (AWS IAM)"
        notebooks -> modelRegistry "Registers model metadata" "REST API"
        notebooks -> pypi "Installs Python packages" "HTTPS/443"
        notebooks -> huggingface "Downloads pretrained models and datasets" "HTTPS/443"
        notebooks -> containerRegistry "Pulls custom container images" "HTTPS/443"

        # Relationships - Platform Infrastructure
        kserve -> openshift "Uses for RBAC, Routes, ServiceAccounts" "Kubernetes API"
        kserve -> certManager "Requests TLS certificates for webhooks" "Kubernetes API"

        dspa -> openshift "Uses for OAuth, Routes, monitoring" "Kubernetes API"

        trainingOperator -> openshift "Uses for RBAC, resource quotas" "Kubernetes API"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
        }

        container rhoai "ContainerDiagram" {
            include *
            autoLayout tb
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }

            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }

            element "External Platform" {
                background #999999
                color #ffffff
            }

            element "External Storage" {
                background #f5a623
                color #ffffff
            }

            element "External Database" {
                background #7ed321
                color #ffffff
            }

            element "External Cache" {
                background #50e3c2
                color #ffffff
            }

            element "External Service" {
                background #bd10e0
                color #ffffff
            }

            element "External Data" {
                background #ff6b6b
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
                shape RoundedBox
            }

            element "WebUI" {
                shape WebBrowser
                background #4a90e2
                color #ffffff
            }

            element "DevEnv" {
                shape Component
                background #7ed321
                color #ffffff
            }
        }
    }
}
