workspace {
    model {
        datascientist = person "Data Scientist" "Develops and trains ML models, creates notebooks, deploys models"
        mlengineer = person "ML Engineer" "Deploys models to production, manages inference pipelines"
        platformadmin = person "Platform Administrator" "Manages RHOAI platform, operators, and infrastructure"

        rhoai = softwareSystem "Red Hat OpenShift AI 2.13" "Enterprise AI/ML platform for end-to-end data science workflows" {
            platformOrchestration = container "Platform Orchestration" "Manages all platform components" "RHODS Operator, ODH Dashboard" {
                rhodsOperator = component "RHODS Operator" "Deploys and manages all data science components" "Go Operator (v1.6.0-2256)"
                odhDashboard = component "ODH Dashboard" "Web-based management console" "React/TypeScript (v1.21.0-18)"
            }

            developmentEnvironments = container "Development Environments" "Interactive workbenches for data science" "Notebook Controller, Workbench Images" {
                notebookController = component "Notebook Controller" "Manages Jupyter/VS Code/RStudio lifecycle" "Go Operator (v1.27.0-376)"
                workbenches = component "Workbench Images" "Pre-built environments with ML frameworks" "Container Images"
            }

            modelServing = container "Model Serving" "Serverless and multi-model inference" "KServe, ModelMesh, ODH Model Controller" {
                kserveController = component "KServe Controller" "Serverless model serving with autoscaling" "Go Operator (v0.12.1)"
                modelmesh = component "ModelMesh Serving" "Multi-model serving with resource optimization" "Go Operator (v1.27.0-292)"
                odhModelController = component "ODH Model Controller" "OpenShift extensions for KServe" "Go Operator (v1.27.0-527)"
            }

            mlPipelines = container "ML Pipelines & Training" "Pipeline orchestration and distributed training" "DSP, Training Operator" {
                dsp = component "Data Science Pipelines" "ML pipeline orchestration" "Kubeflow Pipelines (Argo/Tekton)"
                trainingOperator = component "Training Operator" "Distributed ML training" "Kubeflow Training (PyTorch/TF/MPI/XGBoost)"
            }

            distributedComputing = container "Distributed Computing" "Ray clusters and job queueing" "CodeFlare, KubeRay, Kueue" {
                codeflare = component "CodeFlare Operator" "AppWrapper and Ray security" "Go Operator"
                kuberay = component "KubeRay Operator" "Ray cluster lifecycle management" "Go Operator (v1.1.0)"
                kueue = component "Kueue" "Job queueing and resource management" "Go Operator"
            }

            aiOperations = container "AI Operations" "Model monitoring and explainability" "TrustyAI" {
                trustyai = component "TrustyAI Operator" "AI fairness and explainability metrics" "Go Operator (v1.17.0)"
            }
        }

        openshift = softwareSystem "OpenShift Container Platform 4.11+" "Kubernetes platform with enterprise features" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for models, datasets, and artifacts" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal ODH Component"
        gitRepos = softwareSystem "Git Repositories" "Source code and notebook repositories" "External"
        packageRepos = softwareSystem "Package Repositories" "Python/R package registries (PyPI, CRAN)" "External"
        containerRegistry = softwareSystem "Container Registries" "Container image storage (Quay, Red Hat Registry)" "External"

        # User relationships
        datascientist -> odhDashboard "Creates notebooks, trains models, views pipelines" "HTTPS/443 OAuth"
        mlengineer -> odhDashboard "Deploys models, manages inference services" "HTTPS/443 OAuth"
        platformadmin -> rhodsOperator "Manages platform via DataScienceCluster CR" "kubectl/OpenShift Console"

        # Dashboard relationships
        odhDashboard -> notebookController "Creates Notebook CRs" "Kubernetes API (mTLS)"
        odhDashboard -> kserveController "Creates InferenceService CRs" "Kubernetes API (mTLS)"
        odhDashboard -> dsp "Creates DataSciencePipelinesApplication CRs" "Kubernetes API (mTLS)"

        # RHODS Operator relationships
        rhodsOperator -> odhDashboard "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> notebookController "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> kserveController "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> modelmesh "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> dsp "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> trainingOperator "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> codeflare "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> kuberay "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> kueue "Deploys and manages" "Kubernetes API (mTLS)"
        rhodsOperator -> trustyai "Deploys and manages" "Kubernetes API (mTLS)"

        # Notebook workflows
        notebookController -> workbenches "Creates StatefulSets with workbench images" "Kubernetes API (mTLS)"
        workbenches -> s3Storage "Accesses datasets and models" "HTTPS/443 S3 API"
        workbenches -> gitRepos "Clones repositories via JupyterLab Git" "HTTPS/443 or SSH/22"
        workbenches -> packageRepos "Installs Python/R packages" "HTTPS/443"

        # Model serving workflows
        kserveController -> knative "Creates Knative Services for serverless autoscaling" "Kubernetes API (mTLS)"
        kserveController -> istio "Uses for traffic management" "Kubernetes API (mTLS)"
        odhModelController -> kserveController "Watches InferenceService CRs" "Kubernetes API (mTLS)"
        odhModelController -> openshift "Creates OpenShift Routes for external access" "Kubernetes API (mTLS)"
        odhModelController -> istio "Creates Istio VirtualServices" "Kubernetes API (mTLS)"
        kserveController -> s3Storage "Downloads model artifacts" "HTTPS/443 S3 API"
        kserveController -> modelRegistry "Fetches model metadata" "gRPC/9090"
        modelmesh -> s3Storage "Downloads model artifacts" "HTTPS/443 S3 API"

        # Pipeline workflows
        dsp -> s3Storage "Stores pipeline artifacts" "HTTPS/443 or HTTP/9000 (Minio)"
        dsp -> kserveController "Deploys models from pipeline steps" "Kubernetes API (mTLS)"

        # Training workflows
        trainingOperator -> kueue "Queues PyTorchJob/TFJob/MPIJob" "Kubernetes API (mTLS)"
        trainingOperator -> s3Storage "Saves trained models" "HTTPS/443 S3 API"

        # Distributed computing workflows
        codeflare -> kuberay "Watches RayCluster CRs, injects OAuth/mTLS" "Kubernetes API (mTLS)"
        codeflare -> kueue "Queues AppWrappers for Ray clusters" "Kubernetes API (mTLS)"
        kuberay -> s3Storage "Accesses datasets for distributed processing" "HTTPS/443 S3 API"

        # Model monitoring
        trustyai -> kserveController "Patches InferenceService deployments" "Kubernetes API (mTLS)"
        trustyai -> modelmesh "Monitors ModelMesh predictors" "Kubernetes API (mTLS)"
        trustyai -> prometheus "Exposes fairness metrics" "HTTP/9090 /metrics"

        # Platform dependencies
        rhoai -> openshift "Runs on Kubernetes, uses OAuth, Routes, Service Mesh" "Multiple Protocols"
        rhoai -> prometheus "Exports metrics from all components" "HTTP/9090 ServiceMonitors"
        rhoai -> istio "Uses for service mesh and mTLS" "Multiple Protocols"
        rhoai -> knative "Uses for serverless autoscaling" "Kubernetes API (mTLS)"
        rhoai -> containerRegistry "Pulls container images" "HTTPS/443 Docker Registry API"

        # External client relationships
        externalClient = person "External Client" "Consumes model predictions via API"
        externalClient -> odhModelController "Sends inference requests" "HTTPS/443 (via OpenShift Route)"
    }

    views {
        systemContext rhoai "PlatformSystemContext" {
            include *
            autoLayout lr
        }

        container rhoai "PlatformContainers" {
            include *
            autoLayout lr
        }

        component platformOrchestration "PlatformOrchestrationComponents" {
            include *
            autoLayout lr
        }

        component modelServing "ModelServingComponents" {
            include *
            autoLayout lr
        }

        component distributedComputing "DistributedComputingComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH Component" {
                background #2ecc71
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
                shape RoundedBox
            }
            element "Component" {
                background #85bbf0
                color #000000
                shape Component
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }
}
