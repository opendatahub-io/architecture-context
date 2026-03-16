workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Develops and trains ML models, creates notebooks and experiments"
        mlEngineer = person "ML Engineer" "Deploys and manages model serving infrastructure, MLOps pipelines"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures components, monitors health"

        # RHOAI Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 3.0" "Enterprise AI/ML platform for end-to-end model lifecycle on OpenShift" {
            # Platform Core
            rhodsOperator = container "RHODS Operator" "Platform orchestrator managing component lifecycles and Gateway API infrastructure" "Go Operator" "Platform Core"
            gateway = container "Gateway Infrastructure" "Centralized ingress with Gateway API v1, kube-auth-proxy OAuth2/OIDC authentication" "Envoy + Go" "Platform Core"

            # User-Facing Applications
            dashboard = container "ODH Dashboard" "Centralized web console for managing projects, notebooks, pipelines, model serving" "React + Node.js" "Application"
            notebooks = container "Workbenches" "JupyterLab, RStudio, CodeServer environments for data science development" "Container Images" "Application"

            # ML Workflow Components
            dspOperator = container "Data Science Pipelines Operator" "Deploys Kubeflow Pipelines 2.5.0 for ML workflow orchestration" "Go Operator + Argo Workflows" "ML Workflow"
            kserve = container "KServe" "Model serving platform with serverless autoscaling and multi-framework support" "Go Operator" "ML Workflow"
            modelController = container "ODH Model Controller" "Extends KServe with OpenShift Routes, RBAC, monitoring, NIM integration" "Go Operator" "ML Workflow"
            trainingOperator = container "Training Operator" "Kubeflow Training Operator for distributed ML training (PyTorch, TF, MPI, etc.)" "Go Operator" "ML Workflow"

            # Data & Model Management
            modelRegistry = container "Model Registry Operator" "Manages ML model metadata storage with REST/gRPC APIs" "Go Operator + PostgreSQL/MySQL" "Data Management"
            feast = container "Feast Operator" "Manages feature store deployments for online/offline feature serving" "Go Operator" "Data Management"

            # AI Governance & Safety
            trustyai = container "TrustyAI Service Operator" "Deploys explainability services, LM evaluation, AI guardrails orchestration" "Go Operator" "AI Governance"

            # Advanced Compute
            kuberay = container "KubeRay Operator" "Manages Ray clusters for distributed computing and reinforcement learning" "Go Operator" "Advanced Compute"
            llamaStack = container "Llama Stack Operator" "Deploys LlamaStack distributions for LLM inference across backends" "Go Operator" "Advanced Compute"

            # Monitoring
            monitoring = container "Platform Monitoring" "Prometheus, Alertmanager, ServiceMonitors for component observability" "Prometheus Stack" "Monitoring"
        }

        # External Systems - Infrastructure
        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes platform providing compute, networking, storage, and API server" "External Infrastructure"
        oauth = softwareSystem "OpenShift OAuth / External OIDC" "Authentication provider for OAuth2/OIDC flows (OpenShift or external IdP for ROSA)" "External Infrastructure"
        servicesMesh = softwareSystem "OpenShift Service Mesh" "Istio-based service mesh for mTLS, traffic management (optional)" "External Infrastructure"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning and rotation" "External Infrastructure"

        # External Systems - Storage & Data
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts, datasets, pipeline outputs (AWS S3, Minio, Ceph, GCS, Azure Blob)" "External Storage"
        externalDB = softwareSystem "External Databases" "PostgreSQL/MySQL databases for Model Registry, DSP, TrustyAI metadata persistence" "External Storage"

        # External Systems - ML Ecosystem
        huggingface = softwareSystem "HuggingFace Hub" "Repository of pre-trained models for download and inference" "External ML"
        nvidiaNGC = softwareSystem "NVIDIA NGC" "NVIDIA NIM model catalog and account validation API" "External ML"

        # External Systems - Container Images
        containerRegistry = softwareSystem "Container Registries" "Component container image storage (quay.io, registry.redhat.io)" "External Infrastructure"

        # Relationships - Users to RHOAI
        dataScientist -> dashboard "Creates projects, launches workbenches, submits pipelines via"
        dataScientist -> notebooks "Develops ML code, trains models using"
        mlEngineer -> dashboard "Deploys models, manages serving infrastructure via"
        mlEngineer -> dspOperator "Orchestrates MLOps pipelines using"
        platformAdmin -> rhodsOperator "Configures platform components via DataScienceCluster CR using"
        platformAdmin -> monitoring "Monitors platform health using"

        # Relationships - RHOAI Components (Orchestration)
        rhodsOperator -> gateway "Deploys and configures"
        rhodsOperator -> dashboard "Deploys and manages"
        rhodsOperator -> dspOperator "Deploys and manages"
        rhodsOperator -> kserve "Deploys and manages"
        rhodsOperator -> modelController "Deploys and manages"
        rhodsOperator -> modelRegistry "Deploys and manages"
        rhodsOperator -> trainingOperator "Deploys and manages"
        rhodsOperator -> kuberay "Deploys and manages"
        rhodsOperator -> trustyai "Deploys and manages"
        rhodsOperator -> feast "Deploys and manages"
        rhodsOperator -> llamaStack "Deploys and manages"
        rhodsOperator -> monitoring "Configures"

        # Relationships - Gateway & Authentication
        gateway -> oauth "Authenticates users via OAuth2/OIDC using"
        gateway -> dashboard "Routes authenticated traffic to"
        gateway -> notebooks "Routes authenticated traffic to"
        gateway -> kserve "Routes authenticated traffic to"
        gateway -> dspOperator "Routes authenticated traffic to"

        # Relationships - Dashboard Integrations
        dashboard -> notebooks "Manages lifecycle of"
        dashboard -> dspOperator "Manages pipeline instances via"
        dashboard -> kserve "Manages model serving via"
        dashboard -> modelRegistry "Manages model metadata via"
        dashboard -> feast "Manages feature stores via"
        dashboard -> llamaStack "Manages LLM deployments via"

        # Relationships - ML Workflow
        dspOperator -> kserve "Deploys models to" "Kubernetes API (InferenceService CR)"
        dspOperator -> modelRegistry "Registers models to" "REST API"
        dspOperator -> s3Storage "Stores pipeline artifacts to" "HTTPS/443 (S3 API)"
        trainingOperator -> modelRegistry "Registers trained models to" "REST API"
        trainingOperator -> s3Storage "Stores training datasets and checkpoints to" "HTTPS/443 (S3 API)"
        kserve -> s3Storage "Downloads model artifacts from" "HTTPS/443 (S3 API)"
        kserve -> modelRegistry "Queries model metadata from" "REST/gRPC API (optional)"
        kserve -> feast "Queries features from" "HTTP (get-online-features)"
        modelController -> kserve "Extends with Routes, ServiceMonitors, NetworkPolicies"
        modelController -> nvidiaNG "Queries for NIM models and account validation" "HTTPS/443 (NGC API)"

        # Relationships - AI Governance
        trustyai -> kserve "Monitors predictions, injects guardrails into"
        trustyai -> s3Storage "Stores monitoring data to" "HTTPS/443 (S3 API)"

        # Relationships - Feature Engineering
        feast -> s3Storage "Stores feature data to" "HTTPS/443 (S3 API)"
        feast -> externalDB "Stores feature registry metadata to" "PostgreSQL/MySQL"
        notebooks -> feast "Registers and materializes features using"

        # Relationships - Advanced Compute
        kuberay -> s3Storage "Loads datasets from" "HTTPS/443 (S3 API)"
        notebooks -> kuberay "Submits Ray jobs to"
        llamaStack -> huggingface "Downloads LLM models from" "HTTPS/443"

        # Relationships - RHOAI to Infrastructure
        rhoai -> openshift "Runs on, uses Kubernetes API" "HTTPS/6443"
        rhoai -> servicesMesh "Uses for mTLS and traffic management (optional)" "Istio"
        rhoai -> certManager "Uses for TLS certificate management" "cert-manager API"
        rhoai -> containerRegistry "Pulls component images from" "HTTPS/443"

        # Relationships - Storage & Databases
        modelRegistry -> externalDB "Stores model metadata in" "PostgreSQL/MySQL (5432/3306)"
        dspOperator -> externalDB "Stores pipeline metadata in" "MariaDB/PostgreSQL (3306/5432)"
        trustyai -> externalDB "Stores AI governance data in" "PostgreSQL (5432)"

        # Relationships - Model Downloads
        kserve -> huggingface "Downloads pre-trained models from" "HTTPS/443"
        notebooks -> huggingface "Downloads models and datasets from" "HTTPS/443"

        # Relationships - Monitoring
        monitoring -> rhoai "Monitors all platform components" "Prometheus scraping"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autolayout lr
            description "System context diagram for Red Hat OpenShift AI 3.0 platform showing users, platform components, and external dependencies"
        }

        container rhoai "Containers" {
            include *
            autolayout lr
            description "Container diagram showing internal RHOAI components and their relationships"
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
                background #f5a623
                color #ffffff
            }
            element "External ML" {
                background #7ed321
                color #ffffff
            }
            element "Platform Core" {
                background #4a90e2
                color #ffffff
            }
            element "Application" {
                background #9b59b6
                color #ffffff
            }
            element "ML Workflow" {
                background #e74c3c
                color #ffffff
            }
            element "Data Management" {
                background #3498db
                color #ffffff
            }
            element "AI Governance" {
                background #e67e22
                color #ffffff
            }
            element "Advanced Compute" {
                background #1abc9c
                color #ffffff
            }
            element "Monitoring" {
                background #34495e
                color #ffffff
            }
        }
    }
}
