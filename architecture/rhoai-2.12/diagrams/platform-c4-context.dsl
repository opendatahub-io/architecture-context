workspace {
    model {
        // Users
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks, pipelines, and serving"
        mlEngineer = person "ML Engineer" "Manages distributed training, model serving infrastructure, and MLOps workflows"
        platformAdmin = person "Platform Administrator" "Deploys and configures RHOAI platform components via RHODS Operator"

        // RHOAI Platform (Main System)
        rhoai = softwareSystem "Red Hat OpenShift AI Platform" "Comprehensive ML/AI platform for developing, training, serving, and monitoring ML models on Kubernetes" {
            // Core Orchestration
            rhodsOperator = container "RHODS Operator" "Deploys and manages all platform components via DataScienceCluster CRs" "Go Operator v1.6.0" "Operator"

            // User Interface
            dashboard = container "ODH Dashboard" "Web UI for managing projects, workbenches, pipelines, and model serving" "React Application v1.21.0" "Web UI"

            // Workbench Layer
            notebookController = container "ODH Notebook Controller" "Extends Kubeflow Notebooks with OAuth, Routes, and network policies" "Go Operator v1.27.0" "Operator"
            workbenches = container "Workbench Pods" "JupyterLab, RStudio, VS Code environments with ML frameworks" "Container Images" "Workload"

            // Model Serving
            kserve = container "KServe" "Serverless model serving with autoscaling and multi-framework support" "Go Operator 81bf82134" "Operator"
            modelMesh = container "ModelMesh Serving" "High-density multi-model serving with intelligent caching" "Go Operator v1.27.0" "Operator"
            modelController = container "ODH Model Controller" "Extends KServe with Routes, service mesh, and monitoring" "Go Operator v1.27.0" "Operator"

            // ML Pipelines
            dspOperator = container "Data Science Pipelines Operator" "ML workflow orchestration based on Kubeflow Pipelines v2" "Go Operator 6bcc644" "Operator"
            argoWorkflows = container "Argo Workflows" "Pipeline execution engine (Kubeflow Pipelines v2 backend)" "Argo v3.4+" "Workflow Engine"
            mlmd = container "ML Metadata Service" "Stores artifact lineage and metadata" "gRPC Service" "Metadata Store"

            // Distributed Training
            trainingOperator = container "Training Operator" "Manages PyTorch, TensorFlow, MPI, XGBoost distributed training jobs" "Go Operator c7d4e1b4" "Operator"

            // Distributed Computing
            codeflareOperator = container "CodeFlare Operator" "Orchestrates distributed ML workloads with Ray cluster management" "Go Operator 4e58587" "Operator"
            kuberayOperator = container "KubeRay Operator" "Manages Ray clusters for distributed computing" "Go Operator b0225b36" "Operator"

            // Resource Management
            kueue = container "Kueue" "Job queueing and resource quota management for batch workloads" "Go Operator v0.7.0" "Operator"

            // Explainability
            trustyaiOperator = container "TrustyAI Service Operator" "Provides ML explainability, fairness metrics, and bias detection" "Go Operator 1.17.0" "Operator"
        }

        // External Systems
        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes platform with built-in security, networking, and monitoring" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and observability" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe serverless mode" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts, pipeline artifacts, and training checkpoints" "External"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for model artifacts" "External"
        azure = softwareSystem "Azure Blob Storage" "Cloud object storage for model artifacts" "External"
        prometheus = softwareSystem "Prometheus Stack" "Platform monitoring and alerting" "Internal ODH"
        authorino = softwareSystem "Authorino" "External authorization service for API authentication" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate management" "External"
        containerRegistries = softwareSystem "Container Registries" "registry.redhat.io, quay.io - Container image storage" "External"
        pypi = softwareSystem "PyPI" "Python package index for runtime package installation" "External"
        git = softwareSystem "Git Services" "GitHub, GitLab - Source code version control and manifest repositories" "External"
        externalDB = softwareSystem "External Databases" "MariaDB, PostgreSQL for pipeline metadata and inference data" "External"

        // Relationships - Users to Platform
        dataScientist -> dashboard "Manages workbenches, pipelines, models via web UI" "HTTPS/443 OAuth2"
        dataScientist -> workbenches "Develops and trains models" "HTTPS/443 OAuth2"
        mlEngineer -> dashboard "Deploys InferenceServices, monitors performance" "HTTPS/443 OAuth2"
        mlEngineer -> kserve "Configures model serving runtimes" "kubectl/HTTPS"
        platformAdmin -> rhodsOperator "Deploys platform via DataScienceCluster CRs" "kubectl/HTTPS"

        // Core Orchestration Relationships
        rhodsOperator -> dashboard "Deploys and manages"
        rhodsOperator -> kserve "Deploys and manages"
        rhodsOperator -> modelMesh "Deploys and manages"
        rhodsOperator -> modelController "Deploys and manages"
        rhodsOperator -> dspOperator "Deploys and manages"
        rhodsOperator -> notebookController "Deploys and manages"
        rhodsOperator -> codeflareOperator "Deploys and manages"
        rhodsOperator -> kuberayOperator "Deploys and manages"
        rhodsOperator -> kueue "Deploys and manages"
        rhodsOperator -> trainingOperator "Deploys and manages"
        rhodsOperator -> trustyaiOperator "Deploys and manages"

        // Dashboard Integrations
        dashboard -> dspOperator "Proxies pipeline API requests" "HTTPS/8888"
        dashboard -> trustyaiOperator "Proxies TrustyAI API requests" "HTTP/8080"
        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API"
        dashboard -> kserve "Creates InferenceService CRs" "Kubernetes API"

        // Workbench Layer
        notebookController -> workbenches "Deploys and injects OAuth proxy" "Kubernetes API"
        workbenches -> s3 "Stores/loads datasets and models" "HTTPS/443 AWS SDK"
        workbenches -> pypi "Installs Python packages at runtime" "HTTPS/443"
        workbenches -> git "Clones repositories, version control" "HTTPS/443 or SSH"

        // Model Serving
        kserve -> knative "Uses for serverless autoscaling" "Kubernetes API"
        kserve -> istio "Uses for traffic management and mTLS" "VirtualServices, Gateways"
        kserve -> s3 "Downloads model artifacts via storage initializer" "HTTPS/443"
        kserve -> gcs "Downloads model artifacts (GCS support)" "HTTPS/443"
        kserve -> azure "Downloads model artifacts (Azure support)" "HTTPS/443"
        modelController -> kserve "Watches InferenceService CRs, creates Routes" "Kubernetes API"
        modelController -> istio "Creates VirtualServices for traffic splitting" "Kubernetes API"
        modelController -> authorino "Creates AuthConfigs for authentication" "Kubernetes API"
        modelController -> prometheus "Creates ServiceMonitors for metrics" "Kubernetes API"
        modelMesh -> s3 "Downloads model artifacts" "HTTPS/443"
        modelMesh -> prometheus "Exports metrics" "HTTP/8080"

        // ML Pipelines
        dspOperator -> argoWorkflows "Deploys and manages Argo Workflows" "Kubernetes API"
        dspOperator -> mlmd "Deploys ML Metadata gRPC service" "Kubernetes API"
        argoWorkflows -> s3 "Stores pipeline artifacts" "HTTPS/443 S3 API"
        argoWorkflows -> externalDB "Stores pipeline metadata (if external)" "TCP/3306 or 5432"
        mlmd -> externalDB "Stores artifact lineage metadata" "MySQL/PostgreSQL"

        // Distributed Training
        trainingOperator -> kueue "Integrates for workload queueing" "Kubernetes API"
        trainingOperator -> s3 "Saves training checkpoints and results" "HTTPS/443"

        // Distributed Computing (Ray)
        kuberayOperator -> codeflareOperator "Watched by CodeFlare for mutation" "Kubernetes API"
        codeflareOperator -> kueue "Integrates via AppWrapper CRs" "Kubernetes API"

        // Resource Management
        kueue -> trainingOperator "Manages PyTorchJob, TFJob queue admission" "Kubernetes API"
        kueue -> kuberayOperator "Manages RayJob queue admission" "Kubernetes API"

        // Explainability
        trustyaiOperator -> kserve "Patches InferenceServices for payload logging" "Kubernetes API"
        trustyaiOperator -> prometheus "Exports fairness and bias metrics" "HTTP/8080 /metrics"
        trustyaiOperator -> externalDB "Stores inference data (optional)" "PostgreSQL/MySQL"

        // Platform Infrastructure Dependencies
        rhodsOperator -> openshift "Manages resources via Kubernetes API" "HTTPS/6443"
        rhodsOperator -> git "Fetches component manifests from GitHub" "HTTPS/443"
        rhodsOperator -> istio "Configures service mesh integration" "Kubernetes API"
        dashboard -> openshift "Authenticates users via OpenShift OAuth" "HTTPS/443 OAuth2"
        notebookController -> openshift "Creates OpenShift Routes for workbenches" "Kubernetes API"
        kserve -> certManager "Uses for webhook TLS certificates" "Kubernetes API"
        workbenches -> containerRegistries "Pulls container images" "HTTPS/443"
        kserve -> containerRegistries "Pulls runtime and model server images" "HTTPS/443"

        // Monitoring
        prometheus -> kserve "Scrapes InferenceService metrics" "HTTP/8080 ServiceMonitor"
        prometheus -> modelMesh "Scrapes serving metrics" "HTTP/8080 ServiceMonitor"
        prometheus -> trustyaiOperator "Scrapes fairness metrics" "HTTP/8080 ServiceMonitor"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autolayout lr
            description "Red Hat OpenShift AI 2.12 Platform - System Context showing all components and external dependencies"
        }

        container rhoai "Containers" {
            include *
            autolayout lr
            description "Red Hat OpenShift AI 2.12 Platform - Container view showing internal components and their relationships"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Web UI" {
                background #f5a623
                color #ffffff
            }
            element "Workload" {
                background #bd10e0
                color #ffffff
            }
            element "Workflow Engine" {
                background #50e3c2
                color #000000
            }
            element "Metadata Store" {
                background #b8e986
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
