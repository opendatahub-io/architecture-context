workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs distributed ML training jobs"
        ciSystem = person "CI/CD System" "Automates training job submission and monitoring"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed ML training across multiple frameworks (PyTorch, TensorFlow, MPI, XGBoost, MXNet, PaddlePaddle)" {
            controller = container "Training Operator Controller" "Reconciles training job CRs and manages pod lifecycle" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Manages distributed PyTorch training jobs with elastic scaling"
                tfController = component "TFJob Controller" "Manages distributed TensorFlow training jobs with parameter server architecture"
                mpiController = component "MPIJob Controller" "Manages MPI-based distributed training jobs (Horovod)"
                xgboostController = component "XGBoostJob Controller" "Manages distributed XGBoost training jobs"
                mxnetController = component "MXNetJob Controller" "Manages distributed MXNet training jobs"
                paddleController = component "PaddleJob Controller" "Manages distributed PaddlePaddle training jobs"
            }
            webhookServer = container "Webhook Server" "Validates and mutates training job CRs" "Go HTTPS Service"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for operator and job statistics" "Go HTTP Service"
            healthProbe = container "Health Probe Server" "Provides liveness and readiness endpoints" "Go HTTP Service"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal ODH"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for training jobs" "External Optional"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Alternative gang scheduling implementation" "External Optional"
        certManager = softwareSystem "cert-manager" "Automatic certificate management" "External Optional"
        s3Storage = softwareSystem "S3 Storage" "Object storage for training datasets and model checkpoints" "External"
        nfsStorage = softwareSystem "NFS Storage" "Network file system for shared training data" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores training job container images" "External"

        # User interactions
        dataScientist -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob, etc. via kubectl" "Kubernetes API"
        ciSystem -> trainingOperator "Automates job submission and monitoring" "Kubernetes API / Python SDK"

        # Core dependencies
        trainingOperator -> kubernetes "Watches CRs, creates/updates pods, services, configmaps" "REST API/6443 HTTPS TLS1.2+"
        webhookServer -> kubernetes "Validates and mutates job CRs" "mTLS/9443"
        controller -> kubernetes "Reconciles job resources and updates status" "REST API/6443 HTTPS TLS1.2+"

        # Monitoring
        prometheus -> metricsServer "Scrapes operator metrics (job counts, reconciliation times)" "HTTP/8080"
        kubernetes -> healthProbe "Health checks (liveness/readiness)" "HTTP/8081"

        # Optional gang scheduling
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "REST API/6443 HTTPS TLS1.2+" "Optional"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "REST API/6443 HTTPS TLS1.2+" "Optional"

        # Certificate management
        webhookServer -> certManager "Automatic webhook certificate provisioning" "CRD" "Optional"

        # Training job external dependencies
        trainingOperator -> s3Storage "Training pods download datasets and save checkpoints" "HTTPS/443 AWS IAM"
        trainingOperator -> nfsStorage "Training pods access shared datasets" "NFS Protocol"
        trainingOperator -> containerRegistry "Pulls training job container images" "HTTPS/443"
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

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
