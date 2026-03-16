workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using RHOAI platform"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and pipelines"
        admin = person "Platform Administrator" "Manages RHOAI platform components and resources"

        # RHOAI Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 2.17" "Enterprise ML platform for developing, training, serving, and monitoring AI/ML models" {
            # Platform Orchestration
            rhodsOperator = container "rhods-operator" "Platform orchestration operator managing all component lifecycles via DataScienceCluster CRD" "Go Operator"

            # User Interface
            dashboard = container "ODH Dashboard" "Web UI for managing workbenches, pipelines, and model serving" "React/Node.js" {
                tags "Web Application"
            }

            # Development Environment
            notebookController = container "Notebook Controller" "Manages Jupyter notebook lifecycle with OAuth and Routes" "Go Operator"
            workbenches = container "Workbench Pods" "Jupyter, RStudio, Code Server with ML frameworks (PyTorch, TensorFlow)" "Python/R"

            # Model Serving
            kserve = container "KServe" "Serverless model serving with autoscaling" "Go Operator + Python Runtimes"
            modelMesh = container "ModelMesh Serving" "Multi-model serving with intelligent placement" "Go Operator + Java/Python Runtimes"
            modelController = container "Model Controller" "OpenShift integration for Routes, Istio, and Authorino" "Go Operator"

            # ML Pipelines
            dspOperator = container "Data Science Pipelines" "Kubeflow Pipelines v2 with Argo Workflows backend" "Go Operator + Python"
            modelRegistry = container "Model Registry" "Model metadata, versioning, and lineage tracking" "Go Operator + Python/gRPC"

            # Distributed Computing
            kuberay = container "KubeRay" "Ray cluster lifecycle management for distributed computing" "Go Operator"
            codeflare = container "CodeFlare" "Ray security (OAuth, mTLS) and AppWrapper orchestration" "Go Operator"
            kueue = container "Kueue" "Job queueing with fair sharing and preemption" "Go Operator"

            # Training
            trainingOperator = container "Training Operator" "Distributed training for PyTorch, TensorFlow, MPI, XGBoost" "Go Operator"

            # AI Trust
            trustyai = container "TrustyAI" "AI explainability, fairness metrics, and LLM evaluation" "Go Operator + Java"
        }

        # OpenShift Platform
        openshift = softwareSystem "Red Hat OpenShift Container Platform 4.11+" "Kubernetes platform with enterprise features" {
            tags "OpenShift"
        }

        # Service Mesh
        serviceMesh = softwareSystem "Red Hat OpenShift Service Mesh (Istio)" "Service mesh for mTLS, traffic management, and observability" {
            tags "Service Mesh"
        }

        # Serverless
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe" {
            tags "External Dependency"
        }

        # Authentication
        authorino = softwareSystem "Authorino" "Kubernetes-native authorization service" {
            tags "External Dependency"
        }

        # Monitoring
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" {
            tags "External Dependency"
        }

        # Storage
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts, pipeline artifacts, and training checkpoints" {
            tags "External Service"
        }

        # Databases
        databases = softwareSystem "PostgreSQL / MySQL / MariaDB" "Relational databases for model registry, pipelines, and TrustyAI metadata" {
            tags "External Service"
        }

        # Container Registry
        registry = softwareSystem "Red Hat Container Registry" "Container image registry (registry.redhat.io)" {
            tags "External Service"
        }

        # External APIs
        nvidia = softwareSystem "NVIDIA NGC API" "NVIDIA GPU Cloud for NIM account validation" {
            tags "External Service"
        }

        packageRepos = softwareSystem "PyPI / Conda Repositories" "Python package repositories for workbench dependencies" {
            tags "External Service"
        }

        # Relationships - Users to Platform
        dataScientist -> dashboard "Uses web UI to manage projects, notebooks, and models" "HTTPS/OAuth"
        dataScientist -> workbenches "Develops and trains models" "HTTPS/OAuth"
        dataScientist -> kserve "Deploys models for inference" "kubectl/HTTPS"
        mlEngineer -> dashboard "Manages model serving and pipelines" "HTTPS/OAuth"
        mlEngineer -> dspOperator "Creates and monitors ML pipelines" "HTTPS/OAuth"
        admin -> rhodsOperator "Configures platform via DataScienceCluster CR" "kubectl"

        # Platform orchestration
        rhodsOperator -> dashboard "Manages lifecycle"
        rhodsOperator -> notebookController "Manages lifecycle"
        rhodsOperator -> kserve "Manages lifecycle"
        rhodsOperator -> modelMesh "Manages lifecycle"
        rhodsOperator -> modelController "Manages lifecycle"
        rhodsOperator -> dspOperator "Manages lifecycle"
        rhodsOperator -> modelRegistry "Manages lifecycle"
        rhodsOperator -> kuberay "Manages lifecycle"
        rhodsOperator -> codeflare "Manages lifecycle"
        rhodsOperator -> kueue "Manages lifecycle"
        rhodsOperator -> trainingOperator "Manages lifecycle"
        rhodsOperator -> trustyai "Manages lifecycle"

        # Dashboard integrations
        dashboard -> notebookController "Creates/manages notebooks" "Kubernetes API"
        dashboard -> kserve "Queries InferenceService status" "Kubernetes API"
        dashboard -> modelRegistry "Fetches model metadata" "Kubernetes API"
        dashboard -> dspOperator "Manages pipelines" "Kubernetes API"
        dashboard -> prometheus "Queries metrics" "Prometheus API/Thanos"

        # Notebook workflow
        notebookController -> workbenches "Deploys notebook pods with OAuth proxy" "Kubernetes API"
        workbenches -> s3Storage "Saves trained models" "HTTPS/S3 API"
        workbenches -> packageRepos "Installs Python packages" "HTTPS"

        # Model serving integrations
        kserve -> knative "Uses for serverless autoscaling" "Kubernetes API"
        kserve -> serviceMesh "Uses for traffic routing and mTLS" "Istio API"
        kserve -> modelController "Notifies on InferenceService changes" "Kubernetes Watch"
        modelController -> serviceMesh "Creates Gateway, VirtualService" "Istio API"
        modelController -> authorino "Creates AuthConfig for authentication" "Kubernetes API"
        modelController -> prometheus "Creates ServiceMonitor" "Kubernetes API"
        modelController -> nvidia "Validates NIM accounts" "HTTPS/REST"
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/S3 API"
        kserve -> modelRegistry "Fetches model metadata (optional)" "gRPC"
        modelMesh -> s3Storage "Downloads model artifacts" "HTTPS/S3 API"

        # Pipeline integrations
        dspOperator -> s3Storage "Stores pipeline artifacts" "HTTPS/S3 API"
        dspOperator -> databases "Stores pipeline metadata" "PostgreSQL/MySQL"
        dspOperator -> kserve "Deploys models from pipelines (optional)" "Kubernetes API"
        dspOperator -> modelRegistry "Registers models (optional)" "gRPC"

        # Model Registry
        modelRegistry -> databases "Stores model metadata" "PostgreSQL/MySQL"
        modelRegistry -> serviceMesh "Uses for Gateway and mTLS" "Istio API"
        modelRegistry -> authorino "Uses for authentication" "Kubernetes API"

        # Distributed computing
        codeflare -> kuberay "Watches RayCluster CRs, injects security" "Kubernetes Watch"
        codeflare -> kueue "Uses AppWrapper for workload scheduling" "Kubernetes API"
        kuberay -> prometheus "Exports Ray metrics" "Prometheus API"

        # Training
        trainingOperator -> kueue "Queues training jobs" "Kubernetes API"
        kueue -> trainingOperator "Admits PyTorchJob, TFJob, etc." "Kubernetes API"
        kueue -> kuberay "Admits RayJob, RayCluster" "Kubernetes API"

        # AI Trust
        trustyai -> kserve "Monitors InferenceServices for bias" "Kubernetes Watch + HTTP"
        trustyai -> modelMesh "Monitors ModelMesh predictions" "HTTP"
        trustyai -> prometheus "Exports fairness metrics" "Prometheus API"
        trustyai -> databases "Stores monitoring data" "JDBC"
        trustyai -> kueue "Queues LMEvalJobs" "Kubernetes API"

        # Platform dependencies
        rhoai -> openshift "Runs on OpenShift, uses OAuth, Routes, NetworkPolicy" "Kubernetes API"
        rhoai -> serviceMesh "Uses for mTLS and traffic management" "Istio API"
        rhoai -> registry "Pulls container images" "HTTPS/Docker Registry API"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            title "RHOAI 2.17 Platform - System Context Diagram"
            description "High-level view of RHOAI platform and its interactions with users and external systems"
        }

        container rhoai "Containers" {
            include *
            autoLayout tb
            title "RHOAI 2.17 Platform - Container Diagram"
            description "Detailed view of RHOAI platform components and their relationships"
        }

        dynamic rhoai "ModelDevelopmentWorkflow" "Model Development to Deployment Workflow" {
            dataScientist -> dashboard "1. Create Data Science Project"
            dashboard -> notebookController "2. Launch Jupyter Workbench"
            notebookController -> workbenches "3. Deploy notebook pod"
            dataScientist -> workbenches "4. Develop and train model"
            workbenches -> s3Storage "5. Save trained model"
            dataScientist -> dashboard "6. Create InferenceService"
            dashboard -> kserve "7. Deploy InferenceService"
            kserve -> s3Storage "8. Download model artifacts"
            kserve -> modelController "9. Notify of InferenceService"
            modelController -> serviceMesh "10. Create Istio Gateway"
            modelController -> authorino "11. Create AuthConfig"
            dataScientist -> kserve "12. Send inference request"
            kserve -> trustyai "13. Log predictions"
            trustyai -> prometheus "14. Export fairness metrics"
            autoLayout lr
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
            element "Web Application" {
                shape WebBrowser
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Service Mesh" {
                background #466bb0
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f4c430
                color #000000
            }
        }

        theme default
    }
}
