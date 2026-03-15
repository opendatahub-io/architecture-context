workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using RHOAI platform"
        mlEngineer = person "ML Engineer" "Manages model serving, pipelines, and production ML infrastructure"
        platformAdmin = person "Platform Administrator" "Manages RHOAI installation, monitoring, and platform configuration"

        # RHOAI Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 2.25" "Enterprise AI/ML platform for the complete ML lifecycle" {
            # Core Platform
            operator = container "RHOAI Operator" "Platform orchestrator managing 16 components via DataScienceCluster CR" "Go Operator" "Platform Core"
            dashboard = container "ODH Dashboard" "Web UI for platform management, project creation, and monitoring" "React 18 + PatternFly 6" "Platform Core"

            # Model Serving
            kserve = container "KServe" "Serverless model inference with autoscaling" "Go Controller + Python Runtimes" "Model Serving"
            modelmesh = container "ModelMesh Serving" "Multi-model serving for high-throughput inference" "Java + Python Runtimes" "Model Serving"
            modelController = container "ODH Model Controller" "Extends KServe with OpenShift Routes, OAuth, service mesh" "Go Controller" "Model Serving"
            modelRegistry = container "Model Registry" "Model versioning, metadata, and artifact tracking" "Go API + PostgreSQL" "Model Serving"

            # Development & Training
            notebooks = container "Notebook Controller" "Manages Jupyter, VS Code, RStudio workbench instances" "Go Controller" "Development"
            training = container "Training Operator" "Distributed training for PyTorch, TensorFlow, XGBoost, MPI, JAX" "Go Controller" "Development"
            pipelines = container "Data Science Pipelines" "ML workflow orchestration with Argo Workflows" "Go API + Argo" "Development"

            # Distributed Computing
            codeflare = container "CodeFlare Operator" "Distributed AI/ML workload orchestration" "Go Controller" "Compute"
            kuberay = container "KubeRay" "Ray cluster lifecycle management" "Go Controller" "Compute"
            kueue = container "Kueue" "Job queueing and fair-share scheduling" "Go Controller" "Compute"

            # AI Safety & Features
            trustyai = container "TrustyAI" "AI explainability, LM evaluation, and guardrails" "Quarkus + Python" "AI Safety"
            feast = container "Feast Operator" "Feature store for training/serving consistency" "Go Controller + Python" "Features"
            llamastack = container "Llama Stack Operator" "LLM inference with Ollama, vLLM, TGI" "Go Controller" "LLM Serving"
        }

        # External Systems - Infrastructure
        openshift = softwareSystem "OpenShift Container Platform 4.11+" "Kubernetes distribution with Routes, OAuth, monitoring" "External Infrastructure"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic management, observability" "External Infrastructure"
        knative = softwareSystem "Knative Serving" "Serverless platform for autoscaling workloads" "External Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Infrastructure"

        # External Systems - Storage
        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts, training data, pipeline outputs" "External Storage"
        postgresql = softwareSystem "PostgreSQL/MySQL" "Relational database for metadata storage" "External Storage"
        redis = softwareSystem "Redis" "In-memory data store for feature serving cache" "External Storage"

        # External Systems - AI/ML Services
        ngc = softwareSystem "NVIDIA NGC" "NIM account management and model catalog" "External AI Service"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained model and dataset repository" "External AI Service"
        containerRegistry = softwareSystem "Container Registries" "Image storage (quay.io, registry.redhat.io)" "External Infrastructure"

        # Relationships - Users to Platform
        dataScientist -> dashboard "Creates notebooks, submits training jobs, deploys models" "HTTPS/OAuth"
        dataScientist -> notebooks "Develops models interactively" "HTTPS/OAuth"
        dataScientist -> kserve "Deploys and tests inference services" "HTTPS/REST"
        mlEngineer -> dashboard "Manages pipelines, monitors model performance" "HTTPS/OAuth"
        mlEngineer -> pipelines "Creates and executes ML workflows" "HTTPS/OAuth"
        mlEngineer -> modelRegistry "Registers and versions models" "HTTPS/REST"
        platformAdmin -> operator "Configures platform via DataScienceCluster CR" "kubectl/YAML"
        platformAdmin -> prometheus "Monitors platform health and metrics" "HTTPS/PromQL"

        # Relationships - Platform Internal
        operator -> dashboard "Deploys and manages"
        operator -> kserve "Deploys and manages"
        operator -> modelmesh "Deploys and manages"
        operator -> modelController "Deploys and manages"
        operator -> notebooks "Deploys and manages"
        operator -> training "Deploys and manages"
        operator -> pipelines "Deploys and manages"
        operator -> codeflare "Deploys and manages"
        operator -> kuberay "Deploys and manages"
        operator -> kueue "Deploys and manages"
        operator -> trustyai "Deploys and manages"
        operator -> feast "Deploys and manages"
        operator -> llamastack "Deploys and manages"
        operator -> modelRegistry "Deploys and manages"

        dashboard -> kserve "Queries InferenceService status" "REST API"
        dashboard -> modelRegistry "Queries model metadata" "REST API"
        dashboard -> notebooks "Creates Notebook CRs" "Kubernetes API"
        dashboard -> pipelines "Manages pipeline definitions" "REST API"

        kserve -> modelController "Extended by for Routes, OAuth, monitoring" "Watch Events"
        modelController -> istio "Creates VirtualServices and Gateways" "Kubernetes API"
        modelController -> ngc "Validates NIM accounts" "HTTPS/REST"

        kserve -> s3 "Loads model artifacts" "HTTPS/S3 API"
        modelmesh -> s3 "Loads model artifacts" "HTTPS/S3 API"
        training -> s3 "Saves training checkpoints" "HTTPS/S3 API"
        notebooks -> s3 "Accesses user data and training data" "HTTPS/S3 API"
        pipelines -> s3 "Stores pipeline artifacts" "HTTPS/S3 API"

        pipelines -> kserve "Deploys models from workflows" "Kubernetes API"
        pipelines -> modelRegistry "Registers models" "REST API"
        pipelines -> postgresql "Stores pipeline metadata" "PostgreSQL"

        training -> modelRegistry "Registers trained models" "REST API"
        training -> huggingface "Downloads pre-trained models" "HTTPS"

        codeflare -> kuberay "Manages RayCluster CRs" "Kubernetes API"
        codeflare -> kueue "Queues AppWrappers for admission" "Kubernetes API"
        kueue -> training "Admits training jobs" "Kubernetes API"
        kueue -> trustyai "Admits LM evaluation jobs" "Kubernetes API"

        trustyai -> kserve "Monitors InferenceServices for bias" "Payload Injection"
        trustyai -> postgresql "Stores explainability metrics" "PostgreSQL"

        feast -> postgresql "Stores feature metadata" "PostgreSQL"
        feast -> redis "Caches online features" "Redis Protocol"

        modelRegistry -> postgresql "Stores model metadata and lineage" "PostgreSQL"

        # Relationships - Platform to Infrastructure
        kserve -> knative "Uses for autoscaling and traffic routing" "Kubernetes API"
        kserve -> istio "Uses for mTLS and service mesh" "Kubernetes API"
        operator -> openshift "Deploys on OpenShift cluster" "Kubernetes API"
        dashboard -> openshift "Authenticates via OpenShift OAuth" "OAuth Protocol"
        notebooks -> openshift "Authenticates via OpenShift OAuth" "OAuth Protocol"

        operator -> containerRegistry "Pulls component images" "HTTPS/Docker Registry"
        notebooks -> containerRegistry "Pulls workbench images" "HTTPS/Docker Registry"
        kserve -> containerRegistry "Pulls runtime images" "HTTPS/Docker Registry"

        kserve -> prometheus "Exposes inference metrics" "Prometheus Scrape"
        training -> prometheus "Exposes training metrics" "Prometheus Scrape"
        dashboard -> prometheus "Queries platform metrics" "HTTPS/PromQL"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout
        }

        container rhoai "PlatformContainers" {
            include *
            autoLayout
        }

        container rhoai "ModelServingView" {
            include dataScientist mlEngineer
            include kserve modelmesh modelController modelRegistry
            include s3 istio knative prometheus
            autoLayout
        }

        container rhoai "TrainingPipelineView" {
            include dataScientist mlEngineer
            include notebooks training pipelines modelRegistry
            include s3 postgresql huggingface
            autoLayout
        }

        container rhoai "DistributedComputeView" {
            include dataScientist mlEngineer
            include codeflare kuberay kueue training
            include s3 openshift
            autoLayout
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
            element "Platform Core" {
                background #e74c3c
                color #ffffff
            }
            element "Model Serving" {
                background #9b59b6
                color #ffffff
            }
            element "Development" {
                background #16a085
                color #ffffff
            }
            element "Compute" {
                background #f39c12
                color #ffffff
            }
            element "AI Safety" {
                background #27ae60
                color #ffffff
            }
            element "Features" {
                background #27ae60
                color #ffffff
            }
            element "LLM Serving" {
                background #9b59b6
                color #ffffff
            }
            element "External Infrastructure" {
                background #95a5a6
                color #ffffff
            }
            element "External Storage" {
                background #f8c471
                color #000000
            }
            element "External AI Service" {
                background #aed6f1
                color #000000
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
