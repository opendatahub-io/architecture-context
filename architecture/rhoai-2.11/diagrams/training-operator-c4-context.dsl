workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"
        admin = person "Platform Admin" "Deploys and monitors the training operator"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed ML training across PyTorch, TensorFlow, MPI, XGBoost, MXNet, and PaddlePaddle" {
            controller = container "Training Operator Controller" "Manages training job lifecycle and reconciliation" "Go Operator" {
                pytorchController = component "PyTorch Controller" "Reconciles PyTorchJob CRs" "Go Controller"
                tfController = component "TensorFlow Controller" "Reconciles TFJob CRs" "Go Controller"
                mpiController = component "MPI Controller" "Reconciles MPIJob CRs" "Go Controller"
                xgboostController = component "XGBoost Controller" "Reconciles XGBoostJob CRs" "Go Controller"
                mxnetController = component "MXNet Controller" "Reconciles MXJob CRs" "Go Controller"
                paddleController = component "Paddle Controller" "Reconciles PaddleJob CRs" "Go Controller"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Endpoint :8080"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP Endpoint :8081"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        containerRegistry = softwareSystem "Container Registry" "Storage for training job container images" "External"
        objectStorage = softwareSystem "Object Storage" "Training data and model artifact storage (S3, etc.)" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for distributed training jobs" "External (Optional)"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Kubernetes coscheduling plugin" "External (Optional)"
        odhOperator = softwareSystem "OpenDataHub Operator" "Manages ODH component lifecycle" "Internal ODH"
        odhPrometheus = softwareSystem "Prometheus (ODH)" "ODH-specific monitoring stack" "Internal ODH"

        # User interactions
        user -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob via kubectl/SDK" "HTTPS/443 via K8s API"
        admin -> trainingOperator "Monitors metrics and health" "HTTP/8080, 8081"

        # Operator interactions
        trainingOperator -> k8sAPI "Watches CRDs, manages pods/services/configmaps" "HTTPS/443, ServiceAccount Token"
        trainingOperator -> containerRegistry "Pulls training job images" "HTTPS/443, Pull Secrets"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling (optional)" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroups for coscheduling (optional)" "HTTPS/443"
        metricsServer -> prometheus "Scraped by Prometheus" "HTTP/8080"
        metricsServer -> odhPrometheus "Scraped via PodMonitor" "HTTP/8080"
        odhOperator -> trainingOperator "Deploys and manages operator" "Kubernetes API"

        # Training jobs
        k8sAPI -> objectStorage "Training pods access data" "HTTPS/443, User credentials"
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
            element "External (Optional)" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
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
    }
}
