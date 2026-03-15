workspace {
    model {
        # Personas
        dataScientist = person "Data Scientist" "Develops and deploys ML models using notebooks, pipelines, and training jobs"
        mlEngineer = person "ML Engineer" "Deploys and manages model serving infrastructure and monitors model performance"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform, operators, and infrastructure"

        # Main Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 3.3" "Enterprise AI/ML platform providing complete ML lifecycle capabilities on OpenShift" {
            # Control Plane Components
            rhods_operator = container "RHODS Operator" "Manages platform lifecycle and component deployment" "Go Operator v1.6.0-5550" {
                tags "Operator" "Control Plane"
            }

            kserve_operator = container "KServe Operator" "Manages serverless model serving infrastructure" "Go Operator v0.15" {
                tags "Operator" "Control Plane"
            }

            odh_model_controller = container "odh-model-controller" "Extends KServe with OpenShift Routes and NVIDIA NIM" "Go Operator v1.27.0-1157" {
                tags "Operator" "Control Plane"
            }

            dsp_operator = container "Data Science Pipelines Operator" "Manages Kubeflow Pipelines for ML workflow orchestration" "Go Operator v0.0.1" {
                tags "Operator" "Control Plane"
            }

            # Platform Services
            dashboard = container "ODH Dashboard" "Web UI for managing projects, workbenches, models, and pipelines" "React v1.21.0-18" {
                tags "Web Application" "Platform Service"
            }

            # User Workloads
            notebooks = container "Workbenches" "Jupyter/RStudio/CodeServer environments with ML frameworks" "Container Images v20xx.2-1184" {
                tags "User Workload" "Development"
            }

            inferenceServices = container "InferenceServices" "Model serving pods with autoscaling and traffic management" "KServe Predictors" {
                tags "User Workload" "Production"
            }

            pipelines = container "Pipeline Runs" "Argo Workflow-based ML pipeline executions" "Kubeflow Pipelines v2" {
                tags "User Workload" "Orchestration"
            }

            training = container "Training Jobs" "Distributed training for PyTorch, TensorFlow, XGBoost, JAX" "Training Operator v1.9.0 + Kubeflow Trainer v2.1.0" {
                tags "User Workload" "Training"
            }

            modelRegistry = container "Model Registry" "Model metadata storage and versioning" "Model Registry Operator 4fdd8de" {
                tags "User Workload" "Metadata"
            }

            featureStore = container "Feast Feature Store" "Online/offline feature serving and materialization" "Feast Operator 98a224e7c" {
                tags "User Workload" "Features"
            }

            mlflow = container "MLflow" "Experiment tracking and model registry" "MLflow Operator 49b5d8d" {
                tags "Platform Service" "Tracking"
            }

            trustyai = container "TrustyAI Services" "AI explainability, bias detection, drift monitoring" "TrustyAI Operator v1.39.0" {
                tags "User Workload" "Governance"
            }
        }

        # External OpenShift/Kubernetes Dependencies
        openshift = softwareSystem "OpenShift Container Platform 4.12+" "Kubernetes distribution providing platform infrastructure" {
            tags "External Dependency" "Infrastructure"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and observability" {
            tags "External Dependency" "Service Mesh"
        }

        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for InferenceServices" {
            tags "External Dependency" "Serverless"
        }

        certManager = softwareSystem "cert-manager" "Kubernetes certificate management for TLS" {
            tags "External Dependency" "Security"
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoutes" {
            tags "External Dependency" "Networking"
        }

        oauth = softwareSystem "OpenShift OAuth" "Centralized authentication for platform services" {
            tags "External Dependency" "Security"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "External Dependency" "Observability"
        }

        # External Services
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts, pipeline data, and training datasets" {
            tags "External Service" "Storage"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for Model Registry, MLflow, Feast, TrustyAI metadata" {
            tags "External Service" "Database"
        }

        redis = softwareSystem "Redis" "In-memory cache for Feast online feature store" {
            tags "External Service" "Cache"
        }

        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository for training jobs" {
            tags "External Service" "Model Hub"
        }

        nvidia_ngc = softwareSystem "NVIDIA NGC API" "NVIDIA NIM account validation and model downloads" {
            tags "External Service" "LLM Serving"
        }

        imageRegistry = softwareSystem "Image Registries" "Container image storage (Quay, RHIO)" {
            tags "External Service" "Images"
        }

        # User Interactions
        dataScientist -> dashboard "Manages notebooks, models, pipelines, and experiments" "HTTPS/443 (OAuth)"
        dataScientist -> notebooks "Develops models, runs experiments, submits pipelines" "HTTPS/443 (OAuth)"
        dataScientist -> mlflow "Tracks experiments and logs metrics" "HTTPS/443 (OAuth)"

        mlEngineer -> dashboard "Deploys InferenceServices and monitors models" "HTTPS/443 (OAuth)"
        mlEngineer -> inferenceServices "Invokes model predictions" "HTTPS/443 (Bearer Token)"
        mlEngineer -> trustyai "Monitors model bias, drift, and explainability" "HTTPS/443 (OAuth)"

        platformAdmin -> dashboard "Configures platform components" "HTTPS/443 (OAuth)"
        platformAdmin -> prometheus "Monitors platform health and metrics" "HTTPS/443 (OAuth)"

        # Platform Internal Relationships
        rhods_operator -> dashboard "Deploys and manages" "Kubernetes API"
        rhods_operator -> kserve_operator "Deploys and manages" "Kubernetes API"
        rhods_operator -> odh_model_controller "Deploys and manages" "Kubernetes API"
        rhods_operator -> dsp_operator "Deploys and manages" "Kubernetes API"

        dashboard -> notebooks "Creates Notebook CRs" "Kubernetes API/6443"
        dashboard -> inferenceServices "Creates InferenceService CRs" "Kubernetes API/6443"
        dashboard -> modelRegistry "Creates ModelRegistry CRs" "Kubernetes API/6443"
        dashboard -> featureStore "Creates FeatureStore CRs" "Kubernetes API/6443"
        dashboard -> mlflow "Creates MLflow CRs" "Kubernetes API/6443"

        kserve_operator -> inferenceServices "Reconciles and deploys" "Kubernetes API"
        odh_model_controller -> inferenceServices "Extends with Routes and NIM" "Kubernetes API"
        dsp_operator -> pipelines "Manages pipeline stacks" "Kubernetes API"

        notebooks -> pipelines "Submits pipeline runs" "Pipeline API/8888"
        notebooks -> inferenceServices "Creates InferenceServices" "Kubernetes API/6443"
        pipelines -> inferenceServices "Deploys models" "Kubernetes API/6443"
        pipelines -> modelRegistry "Registers model metadata" "REST API/8443"

        training -> featureStore "Retrieves training features" "HTTP/8815 (offline)"
        inferenceServices -> featureStore "Retrieves online features" "gRPC/6566 (online)"

        trustyai -> inferenceServices "Patches for payload logging" "Kubernetes API + Istio VirtualService"

        # External Dependencies
        rhoai -> openshift "Deployed on" "Kubernetes API/6443"
        rhoai -> oauth "Authenticates users via" "OAuth 2.0/OIDC"
        rhoai -> prometheus "Exports metrics to" "Prometheus scraping"

        kserve_operator -> istio "Uses for traffic routing" "Istio VirtualService"
        kserve_operator -> knative "Uses for autoscaling (optional)" "Knative Service"
        kserve_operator -> certManager "Uses for TLS certificates" "cert-manager Certificate"

        odh_model_controller -> gatewayAPI "Creates HTTPRoutes for notebooks and MLflow" "Kubernetes API"

        # External Service Dependencies
        inferenceServices -> s3 "Downloads model artifacts from" "HTTPS/443 (AWS IAM)"
        pipelines -> s3 "Stores pipeline artifacts to" "HTTPS/443 (AWS IAM)"
        training -> s3 "Stores checkpoints and datasets to" "HTTPS/443 (AWS IAM)"
        notebooks -> s3 "Saves models to" "HTTPS/443 (AWS IAM)"

        modelRegistry -> postgresql "Persists model metadata to" "PostgreSQL/5432 (TLS)"
        mlflow -> postgresql "Persists experiments to" "PostgreSQL/5432 (TLS)"
        featureStore -> postgresql "Persists feature metadata to" "PostgreSQL/5432 (TLS)"
        trustyai -> postgresql "Persists inference data to" "PostgreSQL/5432 (TLS)"

        featureStore -> redis "Caches online features in" "Redis/6379"

        training -> huggingface "Downloads models and datasets from" "HTTPS/443 (API Token)"

        odh_model_controller -> nvidia_ngc "Validates NIM accounts with" "HTTPS/443 (NGC API Key)"

        rhoai -> imageRegistry "Pulls container images from" "HTTPS/443 (Pull Secrets)"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout
            title "Red Hat OpenShift AI 3.3 - System Context Diagram"
            description "High-level view of RHOAI platform, users, and external dependencies"
        }

        container rhoai "Containers" {
            include *
            autoLayout
            title "Red Hat OpenShift AI 3.3 - Container Diagram"
            description "Internal components and their relationships within RHOAI platform"
        }

        dynamic rhoai "NotebookToInference" "Notebook-based model development and deployment workflow" {
            dataScientist -> dashboard "1. Access platform UI"
            dashboard -> notebooks "2. Create Notebook CR"
            dataScientist -> notebooks "3. Develop model in Jupyter"
            notebooks -> s3 "4. Save model artifacts"
            notebooks -> inferenceServices "5. Create InferenceService CR"
            kserve_operator -> inferenceServices "6. Deploy predictor"
            inferenceServices -> s3 "7. Download model"
            mlEngineer -> inferenceServices "8. Invoke predictions"
            autoLayout
            title "Workflow: Notebook-Based Model Development and Deployment"
        }

        dynamic rhoai "PipelineWorkflow" "Pipeline-based training and model deployment workflow" {
            dataScientist -> dashboard "1. Create pipeline via Dashboard"
            dashboard -> pipelines "2. Submit pipeline run"
            pipelines -> training "3. Launch training job"
            training -> s3 "4. Save trained model"
            pipelines -> modelRegistry "5. Register model metadata"
            pipelines -> inferenceServices "6. Deploy model"
            inferenceServices -> s3 "7. Download model"
            mlEngineer -> inferenceServices "8. Invoke predictions"
            autoLayout
            title "Workflow: Pipeline-Based Training and Model Deployment"
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
            element "Operator" {
                background #9b59b6
                color #ffffff
            }
            element "Control Plane" {
                background #9b59b6
                color #ffffff
            }
            element "Platform Service" {
                background #3498db
                color #ffffff
            }
            element "User Workload" {
                background #2ecc71
                color #ffffff
            }
            element "External Dependency" {
                background #95a5a6
                color #ffffff
            }
            element "External Service" {
                background #f39c12
                color #ffffff
            }
            element "Web Application" {
                shape WebBrowser
            }
        }
    }
}
