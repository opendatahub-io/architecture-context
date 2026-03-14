workspace {
    model {
        datascientist = person "Data Scientist" "Trains and fine-tunes ML models using distributed training frameworks"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed ML training across PyTorch, TensorFlow, XGBoost, MPI, JAX, and PaddlePaddle" {
            controller = container "Training Operator Controller" "Manages training job lifecycle and resource creation" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Reconciles PyTorch distributed training jobs" "Go Reconciler"
                tfController = component "TFJob Controller" "Reconciles TensorFlow distributed training jobs" "Go Reconciler"
                xgboostController = component "XGBoostJob Controller" "Reconciles XGBoost distributed training jobs" "Go Reconciler"
                mpiController = component "MPIJob Controller" "Reconciles MPI-based HPC training jobs" "Go Reconciler"
                jaxController = component "JAXJob Controller" "Reconciles JAX distributed training jobs" "Go Reconciler"
                paddleController = component "PaddleJob Controller" "Reconciles PaddlePaddle distributed training jobs" "Go Reconciler"
            }

            webhook = container "Validating Webhook Server" "Validates training job specifications before creation" "Go Admission Controller" {
                webhookEndpoints = component "Webhook Endpoints" "Six framework-specific validation endpoints" "HTTPS Handlers"
            }

            certController = container "Certificate Controller" "Manages TLS certificates for webhook server" "open-policy-agent/cert-controller"

            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for operator monitoring" "HTTP Server"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for batch workloads" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling implementation" "External Optional"
        odhOperator = softwareSystem "opendatahub-operator" "Manages RHOAI component lifecycle" "Internal RHOAI"

        # User interactions
        datascientist -> trainingOperator "Creates PyTorchJob/TFJob/XGBoostJob/MPIJob/JAXJob/PaddleJob via kubectl"
        datascientist -> kubernetes "Submits training job manifests via kubectl apply" "HTTPS/443 kubectl"

        # Training Operator interactions
        trainingOperator -> kubernetes "Manages Pods, Services, ConfigMaps, and training job CRDs" "HTTPS/443 Kubernetes API"
        kubernetes -> webhook "Validates training job specifications during admission control" "HTTPS/9443 mTLS"
        controller -> kubernetes "Watches CRDs and creates training resources" "HTTPS/443 ServiceAccount token"

        # Monitoring
        prometheus -> metricsServer "Scrapes operator metrics" "HTTP/8080 PodMonitor"

        # Optional integrations
        trainingOperator -> volcano "Creates PodGroups for gang scheduling (optional)" "HTTPS/443 Kubernetes API"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling (optional)" "HTTPS/443 Kubernetes API"

        # Certificate management
        certController -> kubernetes "Creates and rotates webhook TLS certificates" "HTTPS/443 Kubernetes API"
        webhook -> certController "Uses TLS certificates for webhook server" "In-process library"

        # Deployment management
        odhOperator -> trainingOperator "Deploys and manages training-operator as RHOAI component" "Kubernetes resources"
    }

    views {
        systemContext trainingOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container trainingOperator "Containers" {
            include *
            autoLayout tb
        }

        component controller "ControllerComponents" {
            include *
            autoLayout tb
            description "Internal structure of the Training Operator Controller showing framework-specific reconcilers"
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout tb
            description "Webhook server structure showing validation endpoints"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }

            element "External Optional" {
                background #cccccc
                color #333333
                border dashed
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
