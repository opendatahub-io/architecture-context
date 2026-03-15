workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for scalable distributed training of ML models across multiple frameworks (PyTorch, TensorFlow, MPI, XGBoost, PaddlePaddle, JAX)" {
            controller = container "Training Controller Manager" "Manages lifecycle of all training job types" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Reconciles PyTorchJob CRs" "Kubernetes Controller"
                tfjobController = component "TFJob Controller" "Reconciles TFJob CRs" "Kubernetes Controller"
                mpiController = component "MPIJob Controller" "Reconciles MPIJob CRs" "Kubernetes Controller"
                xgboostController = component "XGBoostJob Controller" "Reconciles XGBoostJob CRs" "Kubernetes Controller"
                paddleController = component "PaddleJob Controller" "Reconciles PaddleJob CRs" "Kubernetes Controller"
                jaxController = component "JAXJob Controller" "Reconciles JAXJob CRs" "Kubernetes Controller"
            }
            webhook = container "Webhook Server" "Validates training job specs on CREATE/UPDATE" "Go ValidatingWebhookServer" {
                tags "Security"
            }
            certManager = container "Certificate Manager" "Manages TLS certificates for webhook" "Go Service"
            metricsExporter = container "Metrics Exporter" "Exposes operator and job metrics" "Prometheus Exporter"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "Kubernetes API Server" "REST API for cluster management" "External Service"
        }

        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for training jobs" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Alternative gang scheduling" "External Optional"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores trained model metadata and artifacts" "Internal ODH"

        containerRegistry = softwareSystem "Container Registry" "Stores training container images" "External Service"
        objectStorage = softwareSystem "Object Storage (S3)" "Stores training data, checkpoints, and final models" "External Service"

        # User interactions
        dataScientist -> trainingOperator "Creates training jobs (PyTorchJob, TFJob, etc.) via kubectl or Python SDK"
        dataScientist -> odhDashboard "Creates and monitors training jobs via web UI"

        # Operator internal relationships
        controller -> webhook "Validates job specs before creation"
        certManager -> webhook "Provisions TLS certificates"
        controller -> metricsExporter "Exposes metrics"

        # Operator to Kubernetes
        trainingOperator -> kubernetes "Watches CRDs, manages pods/services/events" "HTTPS/443, ServiceAccount Token"
        kubernetes -> webhook "Validates CRs via ValidatingWebhook" "HTTPS/9443, mTLS"

        # Monitoring
        prometheus -> trainingOperator "Scrapes metrics" "HTTP/8080"

        # Gang scheduling (optional)
        trainingOperator -> volcano "Creates PodGroup resources for gang scheduling" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroup resources for gang scheduling" "HTTPS/443"

        # ODH integrations
        odhDashboard -> kubernetes "Creates training jobs via Kubernetes API" "HTTPS/443"
        trainingOperator -> modelRegistry "Trained models stored post-training" "Integration Point"

        # External services
        trainingOperator -> containerRegistry "Pulls training container images" "HTTPS/443, Pull Secrets"
        trainingOperator -> objectStorage "Loads training data, saves checkpoints and models" "HTTPS/443, AWS IAM"

        # Training pods
        trainingPods = softwareSystem "Training Pods" "Master and worker pods executing distributed training" "Managed Resource" {
            tags "Managed"
        }
        trainingOperator -> trainingPods "Creates and manages training pods"
        trainingPods -> objectStorage "Loads data, saves checkpoints" "HTTPS/443, AWS IAM"
        trainingPods -> containerRegistry "Pulls images" "HTTPS/443"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Managed" {
                background #6c8ebf
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
            element "Security" {
                background #d5008f
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
