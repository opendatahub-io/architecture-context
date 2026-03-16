workspace {
    model {
        dataScientist = person "Data Scientist" "Runs distributed machine learning training workloads on Kubernetes"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator for orchestrating distributed ML training jobs across PyTorch, TensorFlow, XGBoost, MPI, MXNet, and PaddlePaddle frameworks" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and manages lifecycle" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Manages PyTorch distributed training" "Go Reconciler"
                tfController = component "TFJob Controller" "Manages TensorFlow distributed training" "Go Reconciler"
                mpiController = component "MPIJob Controller" "Manages MPI-based training" "Go Reconciler"
                xgboostController = component "XGBoostJob Controller" "Manages XGBoost training" "Go Reconciler"
                podControl = component "PodControl" "Creates and manages training pods" "Resource Controller"
                serviceControl = component "ServiceControl" "Creates headless services for pod discovery" "Resource Controller"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server :8080"
            healthServer = container "Health Probes" "Liveness and readiness endpoints" "HTTP Server :8081"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        prometheus = softwareSystem "Prometheus" "User Workload Monitoring for metrics collection" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for multi-pod coordination" "Optional External"
        registry = softwareSystem "Container Registry" "Stores container images for operator and training workloads" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and configures training-operator via DSC/DSCI" "Internal RHOAI"

        # Relationships
        dataScientist -> k8sAPI "Creates PyTorchJob/TFJob CRDs via kubectl/UI" "HTTPS/6443 TLS1.2+"
        dataScientist -> trainingOperator "Manages distributed training jobs"

        controller -> k8sAPI "Watches CRDs, creates/updates pods and services" "HTTPS/6443 TLS1.2+ SA Token"
        k8sAPI -> controller "Notifies on CRD changes" "Watch API TLS1.2+"

        pytorchController -> podControl "Delegates pod creation"
        pytorchController -> serviceControl "Delegates service creation"
        tfController -> podControl "Delegates pod creation"
        tfController -> serviceControl "Delegates service creation"
        mpiController -> podControl "Delegates pod creation"

        prometheus -> metricsServer "Scrapes /metrics endpoint" "HTTP/8080"
        k8sAPI -> healthServer "Liveness and readiness probes" "HTTP/8081"

        controller -> volcano "Creates PodGroup for gang scheduling" "HTTPS/6443 TLS1.2+ SA Token"
        volcano -> k8sAPI "Schedules all pods atomically" "HTTPS/6443"

        controller -> registry "Pulls operator image" "HTTPS/443 TLS1.2+"
        podControl -> registry "Training pods pull images" "HTTPS/443 TLS1.2+ Pull Secrets"

        rhoaiOperator -> trainingOperator "Deploys and configures" "Kubernetes CRD"
        rhoaiOperator -> k8sAPI "Manages operator resources" "HTTPS/6443"
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

        component controller "Components" {
            include *
            autoLayout lr
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
        }

        theme default
    }
}
