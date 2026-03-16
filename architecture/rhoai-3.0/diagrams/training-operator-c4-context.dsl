workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages distributed ML training jobs"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages distributed ML training workloads across multiple frameworks (PyTorch, TensorFlow, MPI, XGBoost, JAX, PaddlePaddle)" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and manages lifecycle" "Go Controller Manager" {
                pytorchController = component "PyTorchJob Controller" "Manages PyTorch distributed training" "Go Reconciler"
                tfController = component "TFJob Controller" "Manages TensorFlow distributed training" "Go Reconciler"
                mpiController = component "MPIJob Controller" "Manages MPI-based HPC training" "Go Reconciler"
                xgboostController = component "XGBoostJob Controller" "Manages XGBoost distributed training" "Go Reconciler"
                jaxController = component "JAXJob Controller" "Manages JAX distributed training" "Go Reconciler"
                paddleController = component "PaddleJob Controller" "Manages PaddlePaddle distributed training" "Go Reconciler"
            }

            webhook = container "Validation Webhooks" "Validates training job specifications" "Go Admission Controller" {
                pytorchWebhook = component "PyTorchJob Webhook" "Validates PyTorchJob CRDs" "Webhook Handler"
                tfWebhook = component "TFJob Webhook" "Validates TFJob CRDs" "Webhook Handler"
                mpiWebhook = component "MPIJob Webhook" "Validates MPIJob CRDs" "Webhook Handler"
            }

            sdk = container "Python SDK" "Programmatic job creation and management" "Python Library (kubeflow-training)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "Kubernetes API Server" "Manages cluster resources" "K8s Component"
            scheduler = container "Kubernetes Scheduler" "Schedules pods on nodes" "K8s Component"
        }

        certManager = softwareSystem "cert-manager" "Automatic TLS certificate management for webhooks" "External Optional"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for coordinated pod placement" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling implementation" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Optional"

        odhOperator = softwareSystem "OpenDataHub Operator" "Deploys and manages ODH components" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "User interface for managing training jobs" "Internal ODH"

        registry = softwareSystem "Container Registry" "Stores training job container images" "External"
        storage = softwareSystem "S3 / Object Storage" "Stores datasets and model checkpoints" "External"

        trainingPods = softwareSystem "Training Job Pods" "Execute distributed training workloads" "Managed"

        %% User interactions
        datascientist -> trainingOperator "Creates training jobs via kubectl or Python SDK"
        datascientist -> sdk "Uses Python SDK for job creation"
        sdk -> apiServer "Creates training job CRDs" "HTTPS/6443"

        %% Operator interactions
        controller -> apiServer "Watches CRDs, creates pods/services" "HTTPS/6443 (ServiceAccount Token)"
        apiServer -> webhook "Validates job specifications" "HTTPS/9443 (mTLS)"
        controller -> trainingPods "Creates and manages training pods"

        %% External dependencies
        trainingOperator -> kubernetes "Uses for orchestration and scheduling" "HTTPS/6443"
        trainingOperator -> certManager "Uses for webhook certificate generation (optional)" "K8s API"
        trainingOperator -> volcano "Uses for gang scheduling (optional)" "K8s API (PodGroup CRD)"
        trainingOperator -> schedulerPlugins "Alternative gang scheduling (optional)" "K8s API (PodGroup CRD)"
        prometheus -> trainingOperator "Scrapes operator metrics" "HTTP/8080"

        %% ODH integration
        odhOperator -> trainingOperator "Deploys and manages operator"
        dashboard -> trainingOperator "Provides UI for job management" "K8s API"

        %% Training pod interactions
        trainingPods -> registry "Pulls training container images" "HTTPS/443 (Image Pull Secrets)"
        trainingPods -> storage "Downloads datasets, saves checkpoints" "HTTPS/443 (AWS IAM/Credentials)"
        trainingPods -> trainingPods "Inter-pod communication for distributed training" "TCP/23456"

        %% Scheduler
        scheduler -> trainingPods "Schedules training pods on nodes"
        volcano -> scheduler "Provides gang scheduling capabilities"
        schedulerPlugins -> scheduler "Provides alternative gang scheduling"
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

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhook "WebhookComponents" {
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
                color #000000
            }
            element "Managed" {
                background #4a90e2
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
}
