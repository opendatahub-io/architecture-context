workspace {
    model {
        # Users
        dataScientist = person "Data Scientist" "Develops and deploys ML models using notebooks, pipelines, and model serving"
        mlEngineer = person "ML Engineer" "Manages distributed training jobs and Ray clusters for large-scale ML workloads"
        admin = person "Platform Administrator" "Manages RHOAI platform configuration and component lifecycle"

        # RHOAI Platform
        rhoai = softwareSystem "Red Hat OpenShift AI 2.14" "Enterprise ML platform for developing, training, serving, and monitoring ML models on OpenShift" {
            # Platform Orchestration
            rhodsOperator = container "rhods-operator" "Platform orchestrator managing all component lifecycles" "Go Operator v1.6.0-826"

            # Core Services
            dashboard = container "odh-dashboard" "Unified web UI for managing notebooks, pipelines, and model serving" "Node.js + React v1.21.0-18" {
                tags "Web Application"
            }

            notebookController = container "notebook-controller" "Manages Jupyter/code-server/RStudio workbench lifecycles" "Go Controller v1.27.0-663"

            # Model Serving
            kserve = container "KServe" "Serverless and raw deployment model serving platform" "Go Operator 1fdf877e7" {
                tags "Model Serving"
            }

            modelmesh = container "ModelMesh Serving" "Multi-model serving with intelligent placement and routing" "Go/Java Operator v1.27.0-261" {
                tags "Model Serving"
            }

            modelController = container "odh-model-controller" "OpenShift and Service Mesh integration for model serving" "Go Controller v1.27.0-483"

            modelRegistry = container "Model Registry" "ML model versioning and metadata management" "Python/gRPC v-2160" {
                tags "Registry"
            }

            # ML Workflows
            dspo = container "Data Science Pipelines" "Argo-based ML workflow orchestration and execution" "Go Operator 6b7b774" {
                tags "Pipelines"
            }

            # Distributed Computing
            codeflare = container "CodeFlare Operator" "Ray cluster orchestration with OAuth and AppWrapper batch scheduling" "Go Operator v1.9.0" {
                tags "Distributed Computing"
            }

            kuberay = container "KubeRay" "Kubernetes operator for Ray distributed computing clusters" "Go Operator d490ea60" {
                tags "Distributed Computing"
            }

            trainingOperator = container "Training Operator" "Distributed training for PyTorch, TensorFlow, MPI, XGBoost" "Go Operator 4b4e3bb4" {
                tags "Distributed Computing"
            }

            kueue = container "Kueue" "Job queueing system with quota management and fair sharing" "Go Operator v0.8.1" {
                tags "Job Scheduling"
            }

            # Monitoring & Governance
            trustyai = container "TrustyAI Service" "Model explainability, fairness monitoring, and bias detection" "Java Service 1.17.0" {
                tags "Monitoring"
            }
        }

        # External OpenShift Dependencies
        openshift = softwareSystem "OpenShift Container Platform 4.12+" "Enterprise Kubernetes platform providing container orchestration" "External OpenShift"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and authorization" "External Service Mesh"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe" "External Serverless"
        oauth = softwareSystem "OpenShift OAuth" "Authentication and authorization for platform UIs and APIs" "External Auth"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"

        # External Storage & Databases
        s3 = softwareSystem "S3 / MinIO / GCS / Azure Blob" "Object storage for model artifacts, pipeline artifacts, and training checkpoints" "External Storage"
        database = softwareSystem "PostgreSQL / MySQL / MariaDB" "Relational databases for pipeline metadata, model registry, and TrustyAI metrics" "External Database"

        # External Services
        containerRegistry = softwareSystem "Container Registry" "Container image storage for platform operators and workloads" "External Registry"
        pypi = softwareSystem "PyPI / Conda" "Python package repositories for notebook dependencies" "External Repository"
        git = softwareSystem "Git Repositories" "Source code version control for notebooks and pipelines" "External VCS"

        # User Relationships
        dataScientist -> dashboard "Access platform via web UI" "HTTPS (OAuth)"
        dataScientist -> notebookController "Create and manage notebooks" "Kubernetes API via Dashboard"
        dataScientist -> kserve "Deploy models for inference" "Kubernetes API via Dashboard"
        dataScientist -> dspo "Submit ML pipelines" "kfp SDK (HTTPS Bearer Token)"
        dataScientist -> modelRegistry "Register and version models" "gRPC/REST API"

        mlEngineer -> trainingOperator "Submit distributed training jobs" "Kubernetes API"
        mlEngineer -> codeflare "Create Ray clusters for distributed computing" "Kubernetes API"
        mlEngineer -> kueue "Manage job queues and quotas" "Kubernetes API"

        admin -> rhodsOperator "Configure platform components" "Kubernetes API (DataScienceCluster CR)"
        admin -> dashboard "Manage platform via UI" "HTTPS (OAuth)"
        admin -> prometheus "Monitor platform health" "HTTPS (Prometheus UI)"

        # Platform Internal Relationships
        rhodsOperator -> dashboard "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> notebookController "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> kserve "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> modelmesh "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> modelRegistry "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> dspo "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> codeflare "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> kuberay "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> trainingOperator "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> kueue "Manages deployment lifecycle" "Kubernetes API"
        rhodsOperator -> trustyai "Manages deployment lifecycle" "Kubernetes API"

        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API"
        dashboard -> kserve "Creates InferenceService CRs" "Kubernetes API"
        dashboard -> dspo "Creates DSPA CRs" "Kubernetes API"
        dashboard -> modelRegistry "Integrates model metadata" "gRPC/REST API"

        kserve -> modelController "Notifies of InferenceService changes" "Kubernetes Watch"
        modelmesh -> modelController "Notifies of Predictor changes" "Kubernetes Watch"
        modelController -> istio "Creates VirtualServices and Gateways" "Kubernetes API"

        dspo -> kserve "Deploys models from pipelines" "Kubernetes API (InferenceService CR)"

        codeflare -> kuberay "Orchestrates Ray cluster management" "Kubernetes API"
        codeflare -> kueue "Integrates AppWrappers for batch scheduling" "Kubernetes API"

        trainingOperator -> kueue "Integrates training jobs with queueing" "Kubernetes API"
        kuberay -> kueue "Integrates Ray jobs with queueing" "Kubernetes API"

        trustyai -> kserve "Monitors InferenceServices for bias" "Kubernetes Watch + HTTP payload"
        trustyai -> modelmesh "Monitors ModelMesh for fairness" "HTTP payload processor"

        # Platform to OpenShift Dependencies
        rhoai -> openshift "Runs on Kubernetes/OpenShift" "Container orchestration"

        kserve -> istio "Uses for traffic routing and mTLS" "Service Mesh integration"
        kserve -> knative "Uses for serverless autoscaling" "Knative Service creation"
        modelmesh -> istio "Uses for traffic routing" "Service Mesh integration"
        modelRegistry -> istio "Uses for API gateway and mTLS" "Service Mesh integration"

        dashboard -> oauth "Authenticates users" "OAuth proxy"
        notebookController -> oauth "Authenticates notebook access" "OAuth proxy"
        codeflare -> oauth "Authenticates Ray dashboard access" "OAuth proxy"

        rhoai -> prometheus "Exposes metrics for monitoring" "Prometheus /metrics endpoints"

        # Platform to External Storage & Databases
        kserve -> s3 "Downloads model artifacts" "HTTPS (AWS IAM / GCS SA)"
        modelmesh -> s3 "Loads models from storage" "HTTPS/HTTP (S3 API)"
        dspo -> s3 "Stores pipeline artifacts" "HTTPS/HTTP (S3 API)"
        dspo -> database "Stores pipeline metadata" "MySQL/PostgreSQL over TLS"
        trainingOperator -> s3 "Saves training checkpoints" "HTTPS (from training pods)"
        modelRegistry -> database "Stores model metadata" "PostgreSQL/MySQL over TLS"
        trustyai -> database "Stores fairness metrics" "PostgreSQL over TLS"

        # Platform to External Services
        rhodsOperator -> containerRegistry "Pulls operator images" "HTTPS (Docker Registry API)"
        rhodsOperator -> git "Downloads component manifests" "HTTPS (github.com)"
        notebookController -> containerRegistry "Pulls workbench images" "HTTPS (Docker Registry API)"
        notebookController -> pypi "Installs Python packages in notebooks" "HTTPS (PyPI API)"
        notebookController -> git "Clones repositories in notebooks" "HTTPS (Git protocol)"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout
        }

        container rhoai "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "External Service Mesh" {
                background #466bb0
                color #ffffff
            }
            element "External Serverless" {
                background #0066cc
                color #ffffff
            }
            element "External Auth" {
                background #cc0000
                color #ffffff
            }
            element "External Monitoring" {
                background #e6522c
                color #ffffff
            }
            element "External Storage" {
                background #ff9900
                color #ffffff
            }
            element "External Database" {
                background #336791
                color #ffffff
            }
            element "External Registry" {
                background #0db7ed
                color #ffffff
            }
            element "External Repository" {
                background #3775a9
                color #ffffff
            }
            element "External VCS" {
                background #f05032
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Application" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }
            element "Model Serving" {
                background #2ecc71
                color #ffffff
            }
            element "Pipelines" {
                background #9b59b6
                color #ffffff
            }
            element "Distributed Computing" {
                background #f39c12
                color #ffffff
            }
            element "Job Scheduling" {
                background #e67e22
                color #ffffff
            }
            element "Monitoring" {
                background #1abc9c
                color #ffffff
            }
            element "Registry" {
                background #16a085
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
