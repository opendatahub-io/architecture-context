workspace {
    model {
        dataScientist = person "Data Scientist" "Trains distributed machine learning models using PyTorch, TensorFlow, MPI, XGBoost, JAX, or PaddlePaddle"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed training of ML models across multiple frameworks" {
            controllerManager = container "Training Operator Controller" "Manages lifecycle of distributed training jobs" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Reconciles PyTorchJob resources" "Go Reconciler"
                tfController = component "TFJob Controller" "Reconciles TFJob resources" "Go Reconciler"
                mpiController = component "MPIJob Controller" "Reconciles MPIJob resources for HPC workloads" "Go Reconciler"
                xgboostController = component "XGBoostJob Controller" "Reconciles XGBoostJob resources" "Go Reconciler"
                jaxController = component "JAXJob Controller" "Reconciles JAXJob resources" "Go Reconciler"
                paddleController = component "PaddleJob Controller" "Reconciles PaddleJob resources" "Go Reconciler"
            }
            webhookServer = container "Validation Webhook Server" "Validates job specifications on CREATE/UPDATE" "Go Admission Controller"
            pythonSDK = container "Python SDK" "Programmatic job creation and management" "Python Library (kubeflow-training)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate generation for webhooks" "External (Optional)"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for coordinated pod placement" "External (Optional)"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling implementation" "External (Optional)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External (Optional)"
        containerRegistry = softwareSystem "Container Registries" "Stores training job container images" "External (quay.io, docker.io)"
        objectStorage = softwareSystem "S3/Object Storage" "Stores datasets and model checkpoints" "External (AWS S3, MinIO)"

        odhOperator = softwareSystem "OpenDataHub Operator" "Deploys and manages ODH platform components" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workloads" "Internal RHOAI"

        # User interactions
        dataScientist -> trainingOperator "Creates training jobs via kubectl or Python SDK"
        dataScientist -> pythonSDK "Uses programmatic API for job creation"

        # Core dependencies
        trainingOperator -> kubernetes "Watches CRDs, creates pods/services, manages job lifecycle" "HTTPS/6443 (TLS 1.2+, ServiceAccount Token)"
        kubernetes -> webhookServer "Validates job specifications" "HTTPS/9443 (TLS 1.2+, mTLS)"
        prometheus -> controllerManager "Scrapes operator metrics" "HTTP/8080 (no auth)"

        # Optional dependencies
        trainingOperator -> certManager "Requests TLS certificates for webhooks" "Kubernetes API"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling" "Kubernetes API (CRD)"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling" "Kubernetes API (CRD)"

        # Training job dependencies
        controllerManager -> containerRegistry "Pulls training container images" "HTTPS/443 (TLS 1.2+, Image Pull Secrets)"
        controllerManager -> objectStorage "Accesses datasets and model checkpoints" "HTTPS/443 (TLS 1.2+, AWS IAM/Credentials)"

        # Internal ODH integrations
        odhOperator -> trainingOperator "Deploys and manages" "Kubernetes API"
        odhDashboard -> trainingOperator "Provides UI for viewing and managing jobs" "Kubernetes API"
    }

    views {
        systemContext trainingOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainingOperator "Containers" {
            include *
            autoLayout
        }

        component controllerManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (Optional)" {
                background #cccccc
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
