workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator for distributed training of ML models across multiple frameworks (PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle)" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and manages Pod/Service lifecycle" "Go Operator" {
                pytorchController = component "PyTorch Controller" "Manages PyTorch distributed training jobs" "Go Reconciler"
                tfController = component "TensorFlow Controller" "Manages TensorFlow distributed training jobs" "Go Reconciler"
                xgboostController = component "XGBoost Controller" "Manages XGBoost distributed training jobs" "Go Reconciler"
                mpiController = component "MPI Controller" "Manages MPI-based training jobs" "Go Reconciler"
                jaxController = component "JAX Controller" "Manages JAX distributed training jobs" "Go Reconciler"
                paddleController = component "PaddlePaddle Controller" "Manages PaddlePaddle distributed training jobs" "Go Reconciler"
            }

            webhook = container "Validating Webhook Server" "Validates job specifications before creation/update for all 6 job types" "Go Admission Controller" {
                tags "Webhook"
            }

            certManager = container "cert-controller" "Manages TLS certificates for webhook server" "Go Certificate Controller" {
                tags "Certificate"
            }

            metricsServer = container "Metrics Exporter" "Exposes operator metrics on port 8080" "Prometheus Exporter" {
                tags "Metrics"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for improved resource efficiency" "Optional External"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling implementation" "Optional External"
        opendatahubOperator = softwareSystem "opendatahub-operator" "Deploys and manages RHOAI components" "Internal RHOAI"

        # User interactions
        user -> trainingOperator "Creates PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob via kubectl" "HTTPS/443 (via K8s API)"

        # Core dependencies
        trainingOperator -> k8s "Watches CRDs, creates/manages Pods, Services, ConfigMaps, Events, NetworkPolicies" "HTTPS/443, ServiceAccount token"
        k8s -> webhook "Validates job CREATE/UPDATE operations" "HTTPS/9443, mTLS"

        # Monitoring
        prometheus -> metricsServer "Scrapes operator metrics" "HTTP/8080"

        # Optional dependencies
        trainingOperator -> volcano "Creates PodGroups for gang scheduling (if enabled)" "HTTPS/443, ServiceAccount token"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling (if enabled)" "HTTPS/443, ServiceAccount token"

        # Deployment management
        opendatahubOperator -> trainingOperator "Deploys and manages as RHOAI component" "Kubernetes manifests"

        # Internal relationships
        webhook -> certManager "Uses TLS certificates" "In-process"
        controller -> metricsServer "Exposes metrics" "In-process"
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

        component controller "Controllers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Optional External" {
                background #cccccc
                color #000000
            }
            element "Webhook" {
                background #f5a623
                color #000000
            }
            element "Certificate" {
                background #bd10e0
                color #ffffff
            }
            element "Metrics" {
                background #50e3c2
                color #000000
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
                background #85b7e2
                color #000000
            }
        }

        theme default
    }
}
