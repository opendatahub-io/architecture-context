workspace {
    model {
        dataScientist = person "Data Scientist" "Develops ML models, runs experiments, and deploys inference services"
        mlEngineer = person "ML Engineer" "Manages ML infrastructure, pipelines, and model deployment"
        endUser = person "End User / Application" "Consumes ML predictions via API"

        rhoai = softwareSystem "Red Hat OpenShift AI 3.3.0" "Comprehensive ML platform for end-to-end AI workloads on OpenShift" {
            dashboard = container "ODH Dashboard" "Web UI for platform management" "React + Node.js" {
                tags "Web Application"
            }

            notebooks = container "Notebooks" "Interactive development environments" "JupyterLab/RStudio/VS Code" {
                tags "Workbench"
            }

            kserve = container "KServe" "Model serving platform" "Go Operator + Python Runtimes" {
                tags "Model Serving"
            }

            pipelines = container "Data Science Pipelines" "ML workflow orchestration" "Kubeflow Pipelines v2 + Argo" {
                tags "Orchestration"
            }

            modelRegistry = container "Model Registry" "Model metadata and versioning" "Python + PostgreSQL/MySQL" {
                tags "Registry"
            }

            mlflow = container "MLflow" "Experiment tracking and model registry" "Python + PostgreSQL" {
                tags "Tracking"
            }

            feast = container "Feast" "Feature store for ML features" "Python + PostgreSQL/Redis" {
                tags "Feature Store"
            }

            trainer = container "Kubeflow Trainer" "Distributed training and LLM fine-tuning" "Go Operator + JobSet" {
                tags "Training"
            }

            trainingOperator = container "Training Operator" "Multi-framework distributed training" "Go Operator (PyTorch/TF/JAX/MPI)" {
                tags "Training"
            }

            trustyai = container "TrustyAI" "Model explainability and guardrails" "Python + PostgreSQL" {
                tags "Governance"
            }

            modelController = container "odh-model-controller" "OpenShift integrations for KServe" "Go Operator" {
                tags "Extension"
            }

            notebookController = container "odh-notebook-controller" "Gateway API integration for notebooks" "Go Operator" {
                tags "Extension"
            }
        }

        openshift = softwareSystem "OpenShift Container Platform 4.17+" "Kubernetes platform with enterprise features" "External"
        istio = softwareSystem "Istio Service Mesh" "Traffic management and mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        s3 = softwareSystem "S3-compatible Storage" "Object storage for models, artifacts, and features" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for metadata" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained models and datasets" "External"
        ngc = softwareSystem "NVIDIA NGC" "NIM inference and GPU-optimized models" "External"

        // User interactions
        dataScientist -> dashboard "Manages notebooks, models, pipelines via web UI" "HTTPS/OAuth"
        dataScientist -> notebooks "Develops models, runs experiments" "HTTPS/OAuth"
        mlEngineer -> dashboard "Configures platform, monitors deployments" "HTTPS/OAuth"
        endUser -> kserve "Requests model predictions" "HTTPS/REST API"

        // Dashboard interactions
        dashboard -> openshift "Creates/manages resources via K8s API" "HTTPS/6443"
        dashboard -> notebooks "Manages notebook lifecycle"
        dashboard -> kserve "Manages InferenceServices"
        dashboard -> pipelines "Manages pipeline runs"
        dashboard -> modelRegistry "Manages model registries"
        dashboard -> mlflow "Manages experiments"

        // Notebook interactions
        notebooks -> pipelines "Submits ML workflows" "HTTPS/8888"
        notebooks -> kserve "Calls inference endpoints" "HTTPS"
        notebooks -> mlflow "Logs experiments and metrics" "HTTPS/5000"
        notebooks -> feast "Retrieves features for training" "HTTP/6566"
        notebooks -> modelRegistry "Registers model metadata" "HTTPS/8443"
        notebooks -> s3 "Reads/writes data and models" "HTTPS/443"
        notebooks -> huggingface "Downloads pre-trained models" "HTTPS/443"

        // KServe dependencies
        kserve -> istio "Uses for traffic routing" "VirtualServices/DestinationRules"
        kserve -> knative "Uses for autoscaling" "Knative Services"
        kserve -> modelController "Extended by for OpenShift features" "Watches InferenceServices"
        kserve -> s3 "Downloads model artifacts" "HTTPS/443"
        kserve -> modelRegistry "Reads model metadata" "HTTPS/8443"
        kserve -> feast "Fetches online features for inference" "HTTP/6566"
        kserve -> certManager "Obtains TLS certificates" "cert-manager API"

        // Pipeline orchestration
        pipelines -> openshift "Executes Argo Workflows" "K8s API"
        pipelines -> s3 "Stores pipeline artifacts" "HTTPS/443"
        pipelines -> postgresql "Stores pipeline metadata" "PostgreSQL/5432"
        pipelines -> kserve "Deploys models from pipelines" "K8s API"
        pipelines -> modelRegistry "Registers pipeline outputs" "HTTPS/8443"

        // Training dependencies
        trainer -> openshift "Creates JobSets for distributed training" "K8s API"
        trainer -> s3 "Downloads datasets, saves models" "HTTPS/443"
        trainer -> huggingface "Downloads base models for fine-tuning" "HTTPS/443"
        trainer -> mlflow "Logs training metrics" "HTTPS/5000"
        trainer -> modelRegistry "Registers trained models" "HTTPS/8443"
        trainingOperator -> trainer "Supports distributed training frameworks"

        // Feature store
        feast -> postgresql "Stores feature metadata" "PostgreSQL/5432"
        feast -> s3 "Stores offline features" "HTTPS/443"

        // MLflow dependencies
        mlflow -> postgresql "Stores experiment metadata" "PostgreSQL/5432"
        mlflow -> s3 "Stores model artifacts" "HTTPS/443"

        // Model Registry dependencies
        modelRegistry -> postgresql "Stores model metadata" "PostgreSQL/5432"

        // TrustyAI monitoring
        trustyai -> kserve "Monitors inference for explainability" "Metrics API"
        trustyai -> postgresql "Stores monitoring data" "PostgreSQL/5432"
        trustyai -> prometheus "Exports metrics" "Prometheus API"
        trustyai -> huggingface "Downloads evaluation models" "HTTPS/443"

        // Controller integrations
        modelController -> openshift "Creates Routes, NetworkPolicies" "K8s API"
        modelController -> prometheus "Creates ServiceMonitors" "Prometheus Operator API"
        modelController -> ngc "Validates NIM accounts" "HTTPS/443"
        notebookController -> openshift "Creates HTTPRoutes" "Gateway API"
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

        container rhoai "ModelServing" {
            include dataScientist endUser
            include kserve modelController istio knative s3 modelRegistry feast certManager
            autoLayout
        }

        container rhoai "ModelTraining" {
            include dataScientist
            include notebooks trainer trainingOperator mlflow s3 huggingface modelRegistry
            autoLayout
        }

        container rhoai "MLWorkflow" {
            include dataScientist
            include notebooks pipelines kserve modelRegistry s3 postgresql
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Application" {
                shape WebBrowser
                background #4a90e2
            }
            element "Workbench" {
                background #7ed321
            }
            element "Model Serving" {
                background #f5a623
            }
            element "Orchestration" {
                background #bd10e0
            }
            element "Registry" {
                background #50e3c2
            }
            element "Tracking" {
                background #50e3c2
            }
            element "Feature Store" {
                background #50e3c2
            }
            element "Training" {
                background #f8e71c
            }
            element "Governance" {
                background #d0021b
            }
            element "Extension" {
                background #9013fe
            }
        }
    }
}
