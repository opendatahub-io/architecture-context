workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"
        dashboard = person "ODH Dashboard User" "Monitors training jobs via web UI"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator for distributed ML training across PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and manages job lifecycle" "Go 1.23" {
                pytorchController = component "PyTorchJob Controller" "Manages PyTorch distributed training jobs"
                tfController = component "TFJob Controller" "Manages TensorFlow distributed training jobs"
                xgboostController = component "XGBoostJob Controller" "Manages XGBoost distributed training jobs"
                mpiController = component "MPIJob Controller" "Manages MPI-based HPC and training jobs"
                paddleController = component "PaddleJob Controller" "Manages PaddlePaddle distributed training jobs"
                jaxController = component "JAXJob Controller" "Manages JAX distributed training jobs"
            }

            webhook = container "Webhook Server" "Validates training job CRs before admission" "Go Webhook Server" {
                tags "Webhook"
            }

            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for operator and jobs" "HTTP Server" {
                tags "Monitoring"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "External" {
            tags "Kubernetes"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal ODH" {
            tags "Internal"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH" {
            tags "Internal"
        }

        volcano = softwareSystem "Volcano Scheduler" "Gang scheduler for batch jobs" "External" {
            tags "Optional"
        }

        schedulerPlugins = softwareSystem "Scheduler Plugins" "Alternative gang scheduling implementation" "External" {
            tags "Optional"
        }

        containerRegistry = softwareSystem "Container Registry" "Stores training images and init containers" "External"

        # User interactions
        user -> trainingOperator "Creates PyTorchJob/TFJob/XGBoostJob/MPIJob/PaddleJob/JAXJob via kubectl"
        dashboard -> odhDashboard "Monitors training jobs via web UI"

        # Operator dependencies
        trainingOperator -> k8s "Watches CRDs, manages Pods/Services/NetworkPolicies via API" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        k8s -> webhook "Validates training job CRs via ValidatingWebhook" "HTTPS/9443, TLS 1.2+, mTLS"

        # Monitoring
        prometheus -> metricsServer "Scrapes metrics" "HTTP/8080"

        # Optional integrations
        controller -> volcano "Creates PodGroups for gang scheduling" "HTTPS/6443 (optional)"
        controller -> schedulerPlugins "Creates PodGroups for gang scheduling" "HTTPS/6443 (optional)"

        # Dashboard integration
        odhDashboard -> k8s "Reads training job status" "HTTPS/6443"

        # Image registry
        trainingOperator -> containerRegistry "Pulls init container images" "HTTPS/443, TLS 1.2+"
        k8s -> containerRegistry "Pulls training images for job pods" "HTTPS/443, TLS 1.2+"
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
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                background #cccccc
                color #000000
            }
            element "Kubernetes" {
                background #326CE5
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #000000
            }
            element "Monitoring" {
                background #50E3C2
                color #000000
            }
        }
    }
}
