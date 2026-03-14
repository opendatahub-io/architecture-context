workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs distributed ML training jobs"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and optimizes distributed training"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native framework for distributed ML training across multiple frameworks (PyTorch, TensorFlow, MPI, JAX, XGBoost, PaddlePaddle)" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and orchestrates distributed training workloads" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Manages distributed PyTorch training with elastic training support" "Go Reconciler"
                tfController = component "TFJob Controller" "Manages TensorFlow parameter server and collective training" "Go Reconciler"
                mpiController = component "MPIJob Controller" "Manages MPI-based HPC and distributed training workloads" "Go Reconciler"
                jaxController = component "JAXJob Controller" "Manages JAX distributed training jobs" "Go Reconciler"
                xgboostController = component "XGBoostJob Controller" "Manages XGBoost distributed training for gradient boosting" "Go Reconciler"
                paddleController = component "PaddleJob Controller" "Manages PaddlePaddle distributed training" "Go Reconciler"
            }
            webhook = container "Webhook Server" "Validates and mutates training job resources before creation" "Go Admission Controller"
            pythonSDK = container "Python SDK" "Simplifies training job creation and management for data scientists" "Python Library"
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration platform" "Platform"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for training datasets, checkpoints, and trained models" "External"
        registry = softwareSystem "Container Registry" "Stores training framework container images (PyTorch, TensorFlow, etc.)" "External"
        volcano = softwareSystem "Volcano" "Advanced gang scheduling and job queueing for batch workloads" "External Optional"
        kueue = softwareSystem "Kueue" "Job queuing and resource quota management for fair resource sharing" "External Optional"

        notebooks = softwareSystem "Notebooks (Workbenches)" "Interactive development environment for data science" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "End-to-end ML workflow orchestration" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Centralized repository for model metadata and versioning" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing framework for hybrid ML workloads" "Internal ODH"
        mlflow = softwareSystem "MLFlow" "Experiment tracking and model logging platform" "Internal ODH"

        # User interactions
        dataScientist -> pythonSDK "Creates training jobs using Python SDK"
        dataScientist -> notebooks "Submits training jobs from workbench"
        mlEngineer -> trainingOperator "Monitors training job metrics and health"

        # SDK and notebook interactions
        pythonSDK -> k8s "Creates PyTorchJob, TFJob, MPIJob CRs via kubectl/client-go"
        notebooks -> k8s "Submits training jobs via Kubernetes API"

        # Kubernetes API interactions
        k8s -> webhook "Validates and mutates training job CRs before creation" "HTTPS/9443 TLS 1.2+"
        k8s -> controller "Notifies of training job CR events (create, update, delete)" "Watch API"

        # Operator interactions
        controller -> k8s "Creates and manages Pods, Services, ConfigMaps, ServiceAccounts for training jobs" "HTTPS/6443 ServiceAccount Token"

        # Training job interactions
        trainingOperator -> s3 "Training pods load datasets and save checkpoints/models" "HTTPS/443 AWS credentials"
        trainingOperator -> registry "Pulls training framework container images (PyTorch, TensorFlow, etc.)" "HTTPS/443 Token"
        trainingOperator -> modelRegistry "Registers trained models after job completion" "HTTP/8080 Bearer Token"
        trainingOperator -> mlflow "Logs training metrics and experiments" "HTTP/5000"

        # External dependencies (optional)
        trainingOperator -> volcano "Uses for gang scheduling when enabled" "CRD Integration"
        trainingOperator -> kueue "Uses for job queueing and resource quotas when enabled" "CRD Integration"

        # Internal ODH integrations
        pipelines -> trainingOperator "Executes distributed training as pipeline steps"
        trainingOperator -> ray "Coordinates with Ray for hybrid workloads" "Integration"
    }

    views {
        systemContext trainingOperator "TrainingOperatorSystemContext" {
            include *
            autoLayout lr
        }

        container trainingOperator "TrainingOperatorContainers" {
            include *
            autoLayout lr
        }

        component controller "TrainingOperatorComponents" {
            include *
            autoLayout tb
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #f5a623
                color #000000
            }
        }
    }
}
