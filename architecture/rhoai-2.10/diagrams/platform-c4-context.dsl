workspace {
    model {
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Manages distributed training, model serving, and MLOps workflows"
        platformAdmin = person "Platform Admin" "Configures and monitors RHOAI platform components"

        rhoai = softwareSystem "Red Hat OpenShift AI 2.10" "Enterprise AI/ML platform for end-to-end ML lifecycle" {
            rhods = container "RHODS Operator" "Platform orchestrator managing all component deployments" "Kubernetes Operator (Go)"
            dashboard = container "ODH Dashboard" "Web UI and API gateway for platform management" "React + FastAPI"

            notebookController = container "Notebook Controller" "Manages Jupyter notebook lifecycle" "Kubernetes Operator (Go)"
            notebookImages = container "Notebook Images" "Pre-built workbench images" "Container Images (Jupyter/VS Code/RStudio)"

            kserve = container "KServe" "Serverless model serving with autoscaling" "Kubernetes Operator (Go)"
            modelmesh = container "ModelMesh Serving" "High-density multi-model serving" "Kubernetes Operator (Go)"
            modelController = container "ODH Model Controller" "OpenShift integration for model serving" "Kubernetes Operator (Go)"

            pipelines = container "Data Science Pipelines" "ML workflow orchestration" "Kubernetes Operator (Go) + Argo"

            trainingOp = container "Training Operator" "Distributed training (PyTorch/TF/MPI/XGBoost)" "Kubernetes Operator (Go)"
            codeflare = container "CodeFlare Operator" "Ray cluster and AppWrapper management" "Kubernetes Operator (Go)"
            kuberay = container "KubeRay Operator" "Ray cluster lifecycle management" "Kubernetes Operator (Go)"

            kueue = container "Kueue" "Multi-tenant job queueing and quota management" "Kubernetes Operator (Go)"
            trustyai = container "TrustyAI Service" "AI fairness and explainability" "Kubernetes Operator (Go)"
        }

        # External Systems
        openshift = softwareSystem "OpenShift Container Platform 4.11+" "Kubernetes distribution with enterprise features" "External Platform"
        istio = softwareSystem "Istio Service Mesh" "Traffic management, mTLS, and telemetry" "External Infrastructure"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External Monitoring"
        authorino = softwareSystem "Authorino" "Kubernetes-native authorization service" "External Security"

        s3Storage = softwareSystem "S3-compatible Storage" "Model artifacts, datasets, pipeline outputs" "External Storage"
        externalDB = softwareSystem "External MySQL/MariaDB" "Pipeline metadata storage (optional)" "External Database"

        gitRepos = softwareSystem "Git Repositories" "Source code and notebooks (GitHub/GitLab)" "External Services"
        packageRepos = softwareSystem "Package Repositories" "Python packages (PyPI/Conda)" "External Services"
        containerRegistry = softwareSystem "Container Registries" "Component and workload images (Quay/Docker Hub)" "External Services"

        modelRegistry = softwareSystem "Model Registry" "Model metadata and lineage tracking" "Internal ODH (Optional)"

        # User interactions
        dataScientist -> dashboard "Creates projects, notebooks, and models via web UI"
        dataScientist -> notebookImages "Develops ML code in Jupyter/VS Code/RStudio"
        dataScientist -> pipelines "Defines and runs ML pipelines"

        mlEngineer -> dashboard "Manages model serving and training jobs"
        mlEngineer -> kserve "Deploys inference services"
        mlEngineer -> trainingOp "Runs distributed training jobs"

        platformAdmin -> dashboard "Monitors platform health and usage"
        platformAdmin -> rhods "Configures platform components"

        # RHOAI internal relationships
        rhods -> dashboard "Deploys and manages"
        rhods -> notebookController "Deploys and manages"
        rhods -> kserve "Deploys and manages"
        rhods -> modelmesh "Deploys and manages"
        rhods -> modelController "Deploys and manages"
        rhods -> pipelines "Deploys and manages"
        rhods -> trainingOp "Deploys and manages"
        rhods -> codeflare "Deploys and manages"
        rhods -> kuberay "Deploys and manages"
        rhods -> kueue "Deploys and manages"
        rhods -> trustyai "Deploys and manages"

        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API"
        dashboard -> pipelines "Creates DSPA CRs" "Kubernetes API"
        dashboard -> kserve "Creates InferenceService CRs" "Kubernetes API"
        dashboard -> prometheus "Queries metrics" "HTTP/9090"

        notebookController -> notebookImages "Uses container images" "Image pull"
        notebookController -> istio "Creates VirtualServices for routing" "Kubernetes API"

        kserve -> knative "Uses for serverless autoscaling" "Kubernetes CRDs"
        kserve -> istio "Uses for traffic management and mTLS" "Kubernetes API"
        kserve -> modelController "Extended by" "Kubernetes watch"
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443 S3 API"

        modelmesh -> modelController "Extended by" "Kubernetes watch"
        modelmesh -> s3Storage "Downloads models" "HTTPS/443 S3 API"
        modelmesh -> trustyai "Sends inference data" "HTTP/8080"

        modelController -> authorino "Creates auth policies" "Kubernetes API"
        modelController -> istio "Creates VirtualServices and PeerAuthentication" "Kubernetes API"
        modelController -> prometheus "Creates ServiceMonitors" "Kubernetes API"

        pipelines -> kserve "Deploys models from pipelines" "Kubernetes API"
        pipelines -> s3Storage "Stores artifacts and outputs" "HTTPS/443 S3 API"
        pipelines -> externalDB "Stores pipeline metadata (optional)" "TCP/3306 MySQL"
        pipelines -> modelRegistry "Registers model metadata" "gRPC/HTTP API"

        trainingOp -> kueue "Workload admission and queueing" "Admission webhook"
        trainingOp -> s3Storage "Reads training data and saves checkpoints" "HTTPS/443"

        codeflare -> kuberay "Manages RayCluster CRs" "Kubernetes API"
        codeflare -> kueue "AppWrapper scheduling" "Admission webhook"

        kuberay -> prometheus "Exports metrics" "ServiceMonitor"

        kueue -> trainingOp "Admits training jobs" "Admission webhook"
        kueue -> codeflare "Admits AppWrappers" "Admission webhook"

        # External dependencies
        rhoai -> openshift "Runs on" "Kubernetes API/6443"
        rhoai -> containerRegistry "Pulls component images" "HTTPS/443"

        notebookImages -> gitRepos "Clones repositories" "HTTPS/443"
        notebookImages -> packageRepos "Installs packages" "HTTPS/443"
        notebookImages -> s3Storage "Reads/writes datasets" "HTTPS/443"
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
            element "External Platform" {
                background #34495e
                color #ffffff
            }
            element "External Infrastructure" {
                background #7f8c8d
                color #ffffff
            }
            element "External Monitoring" {
                background #e67e22
                color #ffffff
            }
            element "External Security" {
                background #c0392b
                color #ffffff
            }
            element "External Storage" {
                background #f39c12
                color #ffffff
            }
            element "External Database" {
                background #3498db
                color #ffffff
            }
            element "External Services" {
                background #95a5a6
                color #ffffff
            }
            element "Internal ODH (Optional)" {
                background #27ae60
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
