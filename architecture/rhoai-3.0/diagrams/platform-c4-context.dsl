workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and monitors production models"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform installation and configuration"

        # RHOAI Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 3.0" "Enterprise AI/ML platform for complete ML lifecycle management" {
            # Control Plane
            rhods = container "RHODS Operator" "Platform orchestrator managing all data science components" "Go Operator" "Operator"
            dashboard = container "ODH Dashboard" "Web UI for platform management and workbench access" "TypeScript/React" "WebApp"

            # Data Science Workbenches
            notebooks = container "Workbenches" "JupyterLab, RStudio, CodeServer environments" "Container Images" "Workload"

            # ML Pipelines
            dspOperator = container "DSP Operator" "Manages Kubeflow Pipelines 2.5.0 instances" "Go Operator" "Operator"
            dspInstance = container "DSP Instance" "Argo Workflows + API server for ML pipeline execution" "Python/Go" "Workload"

            # Model Serving
            kserve = container "KServe Controller" "Model serving platform with serverless and raw deployment modes" "Go Operator" "Operator"
            modelController = container "ODH Model Controller" "Extends KServe with OpenShift-native features (Routes, monitoring)" "Go Controller" "Operator"
            inferenceServices = container "InferenceServices" "Running model servers serving inference requests" "Python/C++" "Workload"

            # Model Registry
            modelRegistryOp = container "Model Registry Operator" "Deploys and manages ML model metadata repositories" "Go Operator" "Operator"
            modelRegistry = container "Model Registry" "REST/gRPC API for model metadata and versioning" "Python" "Workload"

            # Training
            trainingOp = container "Training Operator" "Manages distributed training jobs (PyTorch, TensorFlow, JAX, MPI, XGBoost)" "Go Operator" "Operator"
            trainingJobs = container "Training Jobs" "Distributed training workloads (master + workers)" "Python" "Workload"

            # Distributed Compute
            rayOp = container "KubeRay Operator" "Manages Ray clusters for distributed computing" "Go Operator" "Operator"
            rayClusters = container "Ray Clusters" "Ray head + worker pods for distributed compute" "Python" "Workload"

            # Feature Store
            feastOp = container "Feast Operator" "Deploys Feast feature stores for ML feature management" "Go Operator" "Operator"
            feastStore = container "Feast Feature Store" "Online/offline/registry servers for feature serving" "Python" "Workload"

            # LLM Inference
            llamaOp = container "Llama Stack Operator" "Manages Llama Stack AI inference servers" "Go Operator" "Operator"
            llamaStack = container "Llama Stack Servers" "LLM inference servers (vLLM, TGI, Ollama backends)" "Python" "Workload"

            # AI Governance
            trustyOp = container "TrustyAI Operator" "Provides model explainability, evaluation, and guardrails" "Go Operator" "Operator"
            trustyService = container "TrustyAI Service" "Guardrails orchestration, explainability, bias detection" "Java" "Workload"

            # Monitoring
            prometheus = container "Prometheus" "Platform and model metrics collection" "Prometheus" "Monitoring"
            alertManager = container "AlertManager" "Alert aggregation and routing" "AlertManager" "Monitoring"
        }

        # External Systems - OpenShift Platform
        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes platform providing compute, networking, storage" "External"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Service mesh for traffic management, mTLS, and observability" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless platform for autoscaling InferenceServices" "External"
        certManager = softwareSystem "cert-manager" "Automated certificate management and rotation" "External"
        oauth = softwareSystem "OpenShift OAuth" "Authentication and authorization provider" "External"

        # External Systems - Storage
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for models, datasets, and artifacts (AWS S3, Minio, GCS, Azure Blob)" "External"
        databases = softwareSystem "PostgreSQL/MySQL Databases" "Relational databases for metadata storage" "External"

        # External Systems - ML/Data
        containerRegistry = softwareSystem "Container Registries" "Container image storage (quay.io, registry.redhat.io)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External"
        pypi = softwareSystem "PyPI/CRAN" "Python and R package repositories" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code version control (GitHub, GitLab)" "External"

        # Relationships - User to RHOAI
        dataScientist -> dashboard "Manages notebooks and pipelines via web UI" "HTTPS/443"
        dataScientist -> notebooks "Develops models in JupyterLab/RStudio" "HTTPS/443"
        dataScientist -> dspInstance "Submits ML pipelines via SDK" "HTTPS/443"
        mlEngineer -> dashboard "Monitors model serving and performance" "HTTPS/443"
        mlEngineer -> inferenceServices "Sends inference requests" "HTTPS/443"
        platformAdmin -> rhods "Installs and configures platform via DataScienceCluster CR" "kubectl"

        # RHODS Operator manages components
        rhods -> dspOperator "Manages lifecycle" "Kustomize"
        rhods -> kserve "Manages lifecycle" "Kustomize"
        rhods -> modelRegistryOp "Manages lifecycle" "Kustomize"
        rhods -> trainingOp "Manages lifecycle" "Kustomize"
        rhods -> rayOp "Manages lifecycle" "Kustomize"
        rhods -> feastOp "Manages lifecycle" "Kustomize"
        rhods -> llamaOp "Manages lifecycle" "Kustomize"
        rhods -> trustyOp "Manages lifecycle" "Kustomize"

        # Operator creates workloads
        dspOperator -> dspInstance "Creates and manages" "Kubernetes API"
        kserve -> inferenceServices "Creates and manages" "Kubernetes API"
        modelRegistryOp -> modelRegistry "Creates and manages" "Kubernetes API"
        trainingOp -> trainingJobs "Creates and manages" "Kubernetes API"
        rayOp -> rayClusters "Creates and manages" "Kubernetes API"
        feastOp -> feastStore "Creates and manages" "Kubernetes API"
        llamaOp -> llamaStack "Creates and manages" "Kubernetes API"
        trustyOp -> trustyService "Creates and manages" "Kubernetes API"

        # Dashboard integrations
        dashboard -> modelRegistry "Fetches model metadata" "REST API/8443"
        dashboard -> dspInstance "Proxies pipeline API requests" "HTTP/8888"

        # Data science workflows
        notebooks -> dspInstance "Submits pipeline runs" "REST API/8888"
        notebooks -> modelRegistry "Registers trained models" "REST API/8443"
        notebooks -> kserve "Deploys models via kubectl" "Kubernetes API"
        dspInstance -> kserve "Deploys models from pipelines" "Kubernetes API"
        dspInstance -> modelRegistry "Registers pipeline-trained models" "REST API/8443"

        # Model serving
        kserve -> inferenceServices "Manages InferenceService lifecycle"
        modelController -> inferenceServices "Provisions Routes and monitoring" "Kubernetes API"
        inferenceServices -> feastStore "Retrieves online features for inference" "HTTP/6566"
        trustyService -> inferenceServices "Injects guardrails orchestrator" "Kubernetes API"

        # Training workflows
        trainingJobs -> feastStore "Fetches historical features for training" "HTTP/8815"

        # Monitoring
        prometheus -> dashboard "Scrapes metrics" "HTTP/8080"
        prometheus -> kserve "Scrapes metrics" "HTTP/8080"
        prometheus -> inferenceServices "Scrapes metrics" "HTTP/8080"
        prometheus -> trustyService "Scrapes metrics" "HTTP/8080"
        trustyService -> prometheus "Exports bias/toxicity metrics" "HTTP/9090"
        prometheus -> alertManager "Sends alerts" "HTTP/9093"

        # RHOAI to OpenShift Platform
        rhoai -> openshift "Runs on Kubernetes" "Kubernetes API"
        rhoai -> oauth "Authenticates users" "OAuth2"
        kserve -> serviceMesh "Uses for traffic routing and mTLS" "Istio API"
        kserve -> knativeServing "Uses for autoscaling in serverless mode" "Knative API"
        rhoai -> certManager "Manages TLS certificates" "cert-manager API"

        # RHOAI to Storage
        inferenceServices -> s3Storage "Downloads model artifacts at startup" "HTTPS/443"
        dspInstance -> s3Storage "Stores pipeline artifacts and metadata" "HTTPS/443"
        notebooks -> s3Storage "Reads training data and writes models" "HTTPS/443"
        trainingJobs -> s3Storage "Reads datasets, writes checkpoints" "HTTPS/443"
        feastStore -> s3Storage "Stores offline feature data (Parquet)" "HTTPS/443"
        llamaStack -> s3Storage "Caches downloaded models" "HTTPS/443"

        modelRegistry -> databases "Stores model metadata" "PostgreSQL/5432"
        dspInstance -> databases "Stores pipeline metadata (optional external DB)" "MySQL/3306"
        feastStore -> databases "Online store and feature registry" "PostgreSQL/5432"
        trustyService -> databases "Stores inference logs and metrics" "PostgreSQL/5432"

        # RHOAI to ML/Data Services
        rhoai -> containerRegistry "Pulls container images" "HTTPS/443"
        notebooks -> pypi "Installs Python/R packages" "HTTPS/443"
        notebooks -> gitRepos "Clones repositories" "HTTPS/443, SSH/22"
        inferenceServices -> huggingface "Downloads HuggingFace models" "HTTPS/443"
        llamaStack -> huggingface "Downloads LLM models" "HTTPS/443"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for RHOAI 3.0 showing users, the platform, and external dependencies"
        }

        container rhoai "Containers" {
            include *
            autoLayout tb
            description "Container diagram showing RHOAI 3.0 internal components and their relationships"
        }

        container rhoai "OperatorsView" {
            include rhods dspOperator kserve modelRegistryOp trainingOp rayOp feastOp llamaOp trustyOp modelController
            autoLayout tb
            description "Operator-focused view showing platform control plane"
        }

        container rhoai "WorkloadsView" {
            include notebooks dspInstance inferenceServices modelRegistry trainingJobs rayClusters feastStore llamaStack trustyService
            autoLayout tb
            description "Workload-focused view showing runtime data science components"
        }

        container rhoai "DataFlowView" {
            include notebooks dspInstance kserve inferenceServices modelRegistry feastStore s3Storage databases
            autoLayout lr
            description "Data flow view showing ML pipeline from development to serving"
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
            element "Operator" {
                background #4a90e2
                color #ffffff
                shape hexagon
            }
            element "WebApp" {
                background #7ed321
                color #ffffff
                shape WebBrowser
            }
            element "Workload" {
                background #f5a623
                color #000000
            }
            element "Monitoring" {
                background #bd10e0
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
