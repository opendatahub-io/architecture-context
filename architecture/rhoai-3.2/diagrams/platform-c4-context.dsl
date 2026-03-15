workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using RHOAI platform"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and MLOps pipelines"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform installation and configuration"

        # Main System
        rhoai = softwareSystem "Red Hat OpenShift AI 3.2" "Enterprise AI/ML platform for the complete machine learning lifecycle" {
            # Control Plane
            rhodsOperator = container "RHODS Operator" "Platform control plane managing 15 component operators" "Go Operator v1.6.0" {
                tags "Control Plane"
            }

            # Application Services
            dashboard = container "ODH Dashboard" "Web console for platform management and user workflows" "Node.js 22 / React v1.21.0" {
                tags "Application Service"
            }

            # Model Serving
            kserve = container "KServe" "Serverless and raw deployment model serving with autoscaling" "Go Controller v0.15.0" {
                tags "Model Serving"
            }
            odhModelController = container "ODH Model Controller" "Extends KServe with OpenShift Routes and NIM integration" "Go Controller v1.27.0" {
                tags "Model Serving"
            }

            # ML Pipelines
            dspOperator = container "Data Science Pipelines Operator" "Manages Kubeflow Pipelines v2 with Argo Workflows" "Go Operator rhoai-3.2" {
                tags "ML Pipelines"
            }

            # Workbenches
            notebookController = container "Notebook Controller" "Manages Jupyter/RStudio/VSCode workbench instances" "Go Controller v1.27.0" {
                tags "Workbench"
            }

            # Distributed Training
            trainingOperator = container "Training Operator" "Distributed training for PyTorch/TensorFlow/XGBoost/MPI/JAX" "Go Operator v1.9.0" {
                tags "Distributed Training"
            }
            trainer = container "Trainer" "Kubernetes-native distributed training for LLMs" "Go Operator v2.1.0" {
                tags "Distributed Training"
            }

            # Distributed Computing
            kuberayOperator = container "KubeRay Operator" "Manages Ray clusters for distributed computing and ML" "Go Operator 72c07895" {
                tags "Distributed Computing"
            }

            # ML Operations
            modelRegistry = container "Model Registry Operator" "Model metadata, versioning, and registry services" "Go Operator b068597" {
                tags "ML Operations"
            }
            mlflowOperator = container "MLflow Operator" "Experiment tracking and model registry" "Go Operator cd9ad05" {
                tags "ML Operations"
            }
            feastOperator = container "Feast Operator" "Feature store for ML feature engineering" "Go Operator v0.58.0" {
                tags "ML Operations"
            }

            # AI Governance
            trustyaiOperator = container "TrustyAI Service Operator" "Model explainability, fairness monitoring, and LLM guardrails" "Go Operator a2e891d" {
                tags "AI Governance"
            }

            # GenAI
            llamaStackOperator = container "Llama Stack Operator" "Manages Llama Stack server deployments for LLM serving" "Go Operator v0.5.0" {
                tags "GenAI"
            }

            # Monitoring
            prometheus = container "Prometheus" "Metrics collection and alerting for all platform components" "Prometheus" {
                tags "Monitoring"
            }
        }

        # External Systems - Infrastructure
        openshift = softwareSystem "OpenShift Container Platform 4.14+" "Kubernetes platform providing compute, networking, and storage" "External Infrastructure"
        istio = softwareSystem "Istio Service Mesh" "Service-to-service communication, mTLS, and traffic management" "External Infrastructure"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for InferenceServices" "External Infrastructure"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Central authentication service for dashboard and services" "External Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate management and rotation" "External Infrastructure"

        # External Systems - Storage
        s3Storage = softwareSystem "S3-compatible Object Storage" "Model artifacts, training data, pipeline artifacts storage" "External Storage"
        postgresql = softwareSystem "PostgreSQL Database" "Metadata storage for Model Registry, MLflow, TrustyAI, Feast, Pipelines" "External Storage"
        mariadb = softwareSystem "MariaDB/MySQL Database" "Alternative metadata storage for pipelines and model registry" "External Storage"

        # External Systems - Container & Package Registries
        containerRegistry = softwareSystem "Container Registries" "Container image storage (quay.io, registry.redhat.io)" "External Registry"
        packageRepos = softwareSystem "Package Repositories" "PyPI, npm, CRAN, Maven Central for package installation" "External Registry"

        # External Systems - AI/ML Services
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained models and datasets repository" "External AI/ML Service"
        nvidiaGC = softwareSystem "NVIDIA NGC" "NVIDIA NIM account validation and model catalog" "External AI/ML Service"
        gitRepos = softwareSystem "Git Repositories" "Source code version control (GitHub, GitLab)" "External Source Control"

        # Relationships - Users to Platform
        dataScientist -> dashboard "Uses web console to create notebooks, deploy models, track experiments" "HTTPS/443, OAuth JWT"
        dataScientist -> notebookController "Creates Jupyter notebooks for development" "via Dashboard"
        dataScientist -> kserve "Deploys models as InferenceServices" "via Dashboard"
        dataScientist -> dspOperator "Runs ML pipelines for automated workflows" "via Dashboard"
        mlEngineer -> dashboard "Manages model serving infrastructure and monitors models" "HTTPS/443, OAuth JWT"
        mlEngineer -> trustyaiOperator "Monitors model fairness and explainability" "via Dashboard"
        platformAdmin -> rhodsOperator "Installs and configures RHOAI platform components" "Kubernetes API, ServiceAccount Token"

        # Relationships - Platform Control Plane
        rhodsOperator -> dashboard "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> kserve "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> dspOperator "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> notebookController "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> trainingOperator "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> trainer "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> kuberayOperator "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> modelRegistry "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> mlflowOperator "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> feastOperator "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> trustyaiOperator "Manages lifecycle and configuration" "Kubernetes API"
        rhodsOperator -> llamaStackOperator "Manages lifecycle and configuration" "Kubernetes API"

        # Relationships - Dashboard Integrations
        dashboard -> kserve "Creates and manages InferenceServices" "Kubernetes API, ServiceAccount Token"
        dashboard -> modelRegistry "Queries model metadata and versions" "REST API/8080, Bearer Token"
        dashboard -> mlflowOperator "Accesses experiment tracking data" "REST API/8080, Bearer Token"
        dashboard -> dspOperator "Submits and monitors pipelines" "KFP API/8443, Bearer Token"
        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API, ServiceAccount Token"
        dashboard -> trainingOperator "Creates training job CRs" "Kubernetes API, ServiceAccount Token"
        dashboard -> prometheus "Queries metrics for all components" "PromQL/9090, Bearer Token"

        # Relationships - Model Serving
        kserve -> istio "Uses for traffic routing and mTLS" "Istio API, VirtualServices"
        kserve -> knative "Uses for serverless autoscaling" "Knative API, Knative Services"
        kserve -> modelRegistry "Fetches model metadata" "REST API/8080, ServiceAccount Token"
        kserve -> s3Storage "Downloads model artifacts for serving" "HTTPS/443, AWS IAM/SigV4"
        odhModelController -> kserve "Creates Routes and monitors InferenceServices" "Kubernetes API"
        odhModelController -> nvidiaGC "Validates NIM accounts and fetches model lists" "HTTPS/443, API Key"
        trustyaiOperator -> kserve "Monitors InferenceService requests/responses" "CloudEvents, mTLS"

        # Relationships - ML Pipelines
        dspOperator -> kserve "Deploys models from pipelines" "Kubernetes API, ServiceAccount Token"
        dspOperator -> modelRegistry "Stores model metadata" "REST API/8080, ServiceAccount Token"
        dspOperator -> s3Storage "Stores pipeline artifacts" "HTTPS/443, AWS IAM/SigV4"
        dspOperator -> mariadb "Stores pipeline metadata in MLMD" "MySQL/3306, User/Pass"

        # Relationships - Workbenches
        notebookController -> containerRegistry "Pulls notebook images" "HTTPS/443, Pull Secrets"
        notebookController -> s3Storage "Accesses training data and model checkpoints" "HTTPS/443, AWS IAM"
        notebookController -> packageRepos "Installs Python/R/Node.js packages" "HTTPS/443"
        notebookController -> gitRepos "Clones source code repositories" "HTTPS/443, PAT/SSH"
        notebookController -> huggingface "Downloads pre-trained models and datasets" "HTTPS/443, API Token"

        # Relationships - Distributed Training
        trainingOperator -> containerRegistry "Pulls training job images" "HTTPS/443, Pull Secrets"
        trainingOperator -> s3Storage "Loads datasets and saves model checkpoints" "HTTPS/443, AWS IAM"
        trainer -> containerRegistry "Pulls training runtime images" "HTTPS/443, Pull Secrets"
        trainer -> s3Storage "Saves distributed training outputs" "HTTPS/443, AWS IAM"

        # Relationships - ML Operations
        modelRegistry -> postgresql "Stores model metadata and versions" "PostgreSQL/5432, TLS optional"
        mlflowOperator -> postgresql "Stores experiment tracking data" "PostgreSQL/5432, TLS optional"
        mlflowOperator -> s3Storage "Stores experiment artifacts" "HTTPS/443, AWS IAM"
        feastOperator -> postgresql "Stores feature metadata" "PostgreSQL/5432, TLS optional"
        trustyaiOperator -> postgresql "Stores fairness and explainability metrics" "PostgreSQL/5432, TLS optional"

        # Relationships - Infrastructure Dependencies
        rhoai -> openshift "Runs on OpenShift for compute, networking, and storage" "Kubernetes API"
        rhoai -> openshiftOAuth "Authenticates users via OAuth" "OAuth/443, JWT"
        kserve -> istio "Enforces mTLS and traffic policies" "Istio API"
        kserve -> knative "Enables serverless autoscaling" "Knative API"
        rhoai -> certManager "Manages TLS certificates for webhooks and services" "Kubernetes API"

        # Relationships - Monitoring
        prometheus -> rhoai "Scrapes metrics from all platform components" "HTTP/HTTPS, ServiceMonitors"
    }

    views {
        systemContext rhoai "RHOAIPlatformContext" {
            include *
            autoLayout lr
        }

        container rhoai "RHOAIContainers" {
            include *
            autoLayout lr
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
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f1c40f
                color #000000
            }
            element "External Registry" {
                background #e67e22
                color #ffffff
            }
            element "External AI/ML Service" {
                background #9b59b6
                color #ffffff
            }
            element "External Source Control" {
                background #3498db
                color #ffffff
            }
            element "Control Plane" {
                background #e74c3c
                color #ffffff
            }
            element "Application Service" {
                background #3498db
                color #ffffff
            }
            element "Model Serving" {
                background #2ecc71
                color #ffffff
            }
            element "ML Pipelines" {
                background #9b59b6
                color #ffffff
            }
            element "Workbench" {
                background #f39c12
                color #ffffff
            }
            element "Distributed Training" {
                background #1abc9c
                color #ffffff
            }
            element "Distributed Computing" {
                background #34495e
                color #ffffff
            }
            element "ML Operations" {
                background #e67e22
                color #ffffff
            }
            element "AI Governance" {
                background #d35400
                color #ffffff
            }
            element "GenAI" {
                background #c0392b
                color #ffffff
            }
            element "Monitoring" {
                background #95a5a6
                color #ffffff
            }
        }
    }
}
