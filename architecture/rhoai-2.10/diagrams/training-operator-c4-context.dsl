workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed training jobs for ML models"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed training across multiple ML frameworks" {
            controller = container "Training Operator Controller" "Orchestrates distributed training jobs" "Go Operator" {
                pytorchController = component "PyTorch Controller" "Manages PyTorchJob resources with elastic training support"
                tfController = component "TensorFlow Controller" "Manages TFJob resources for parameter server/worker architecture"
                mpiController = component "MPI Controller" "Manages MPIJob resources with launcher/worker pattern"
                xgboostController = component "XGBoost Controller" "Manages XGBoostJob resources"
                mxnetController = component "MXNet Controller" "Manages MXJob resources"
                paddleController = component "PaddlePaddle Controller" "Manages PaddleJob resources"
            }

            webhook = container "Webhook Server" "Validates and defaults training job specifications" "Admission Webhook" {
                tags "Security"
            }

            sdk = container "Python SDK" "Client library for programmatic job management" "Python Library" {
                tags "Client"
            }

            metricsExporter = container "Metrics Exporter" "Exposes operator metrics" "Prometheus Exporter"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "Infrastructure"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI" {
            tags "Monitoring"
        }

        schedulerPlugins = softwareSystem "scheduler-plugins" "Gang scheduler for co-scheduling training pods" "External" {
            tags "Scheduler"
        }

        volcano = softwareSystem "Volcano Scheduler" "Alternative gang scheduler" "External" {
            tags "Scheduler"
        }

        serviceMesh = softwareSystem "Service Mesh" "Istio/Linkerd for pod-to-pod mTLS" "Internal RHOAI" {
            tags "Networking"
        }

        odhDashboard = softwareSystem "OpenDataHub Dashboard" "Web UI for managing data science workloads" "Internal RHOAI" {
            tags "UI"
        }

        registry = softwareSystem "Container Registry" "Storage for operator and training images" "External" {
            tags "Storage"
        }

        // User interactions
        user -> trainingOperator "Creates/manages training jobs via kubectl or SDK" "HTTPS/6443"
        user -> sdk "Submits jobs programmatically" "Python API"
        user -> odhDashboard "Monitors job status" "HTTPS/443"

        // SDK interactions
        sdk -> kubernetes "Submits training job CRDs" "HTTPS/6443"

        // Operator interactions
        trainingOperator -> kubernetes "Watches CRDs, manages pods/services/PodGroups" "HTTPS/6443"
        kubernetes -> webhook "Validates training job specs" "HTTPS/9443"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling (default)" "HTTPS/6443"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling (optional)" "HTTPS/6443"
        trainingOperator -> registry "Pulls operator and training images" "HTTPS/443"

        // Monitoring interactions
        prometheus -> metricsExporter "Scrapes operator metrics" "HTTP/8080"

        // Integration points
        odhDashboard -> kubernetes "Queries training job status" "HTTPS/6443"
        controller -> serviceMesh "Training pods may use mesh for inter-pod mTLS" "Optional"

        // Internal container relationships
        controller -> webhook "Relies on for CR validation"
        pytorchController -> kubernetes "Creates PyTorchJob worker pods"
        tfController -> kubernetes "Creates TFJob parameter server and worker pods"
        mpiController -> kubernetes "Creates MPI launcher and worker pods"
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
            autoLayout tb
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
            element "Infrastructure" {
                background #0066cc
                color #ffffff
            }
            element "Scheduler" {
                background #f5a623
                color #000000
            }
            element "Monitoring" {
                background #9673a6
                color #ffffff
            }
            element "Storage" {
                background #d6b656
                color #000000
            }
            element "Networking" {
                background #82b366
                color #ffffff
            }
            element "UI" {
                background #4a90e2
                color #ffffff
            }
            element "Security" {
                background #d79b00
                color #ffffff
            }
            element "Client" {
                background #50e3c2
                color #000000
            }
        }

        themes default
    }
}
