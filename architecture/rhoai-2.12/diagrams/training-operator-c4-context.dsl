workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed ML training jobs"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed ML training across multiple frameworks" {
            controller = container "Training Operator Controller" "Main reconciliation controller managing all training job types" "Go 1.21 Operator" {
                pytorchController = component "PyTorch Controller" "Manages PyTorchJob CRDs with elastic training support" "Reconciler"
                tfController = component "TensorFlow Controller" "Manages TFJob CRDs for distributed TensorFlow" "Reconciler"
                mpiController = component "MPI Controller" "Manages MPIJob CRDs for MPI-based training" "Reconciler"
                mxnetController = component "MXNet Controller" "Manages MXJob CRDs for Apache MXNet" "Reconciler"
                xgboostController = component "XGBoost Controller" "Manages XGBoostJob CRDs for XGBoost" "Reconciler"
                paddleController = component "PaddlePaddle Controller" "Manages PaddleJob CRDs for PaddlePaddle" "Reconciler"
            }
            webhook = container "Webhook Server" "Validates and mutates training job specifications" "Admission Webhook"
            pythonSDK = container "Python SDK" "Python client library for managing training jobs" "Python Library"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for coordinated pod scheduling" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling implementation" "External Optional"
        certManager = softwareSystem "cert-manager" "Certificate management for webhook TLS" "External Optional"
        containerRegistry = softwareSystem "Container Registry" "Stores training container images" "External"

        odhOperator = softwareSystem "OpenDataHub Operator" "Deploys and manages ODH components" "Internal ODH"
        monitoring = softwareSystem "ODH Monitoring" "Monitoring stack with Prometheus Operator" "Internal ODH"

        # User relationships
        user -> trainingOperator "Creates training jobs via kubectl or Python SDK"
        user -> pythonSDK "Uses TrainingClient API to manage jobs programmatically"

        # Core dependencies
        trainingOperator -> kubernetes "Watches CRDs, manages pods/services/configmaps" "HTTPS/6443 TLS1.2+"
        controller -> kubernetes "Reconciles training jobs and creates resources" "HTTPS/6443"

        # Webhook integration
        kubernetes -> webhook "Validates and mutates training job CRs" "mTLS"

        # Monitoring
        prometheus -> controller "Scrapes operator and job metrics" "HTTP/8080"
        monitoring -> controller "Configures PodMonitor for metrics collection" "Prometheus Operator"

        # Optional gang scheduling
        controller -> volcano "Creates PodGroup resources for gang scheduling" "HTTPS/6443 TLS1.2+" "Optional"
        controller -> schedulerPlugins "Creates PodGroup resources for gang scheduling" "HTTPS/6443 TLS1.2+" "Optional"
        volcano -> kubernetes "Schedules pods atomically via PodGroup CRD" "HTTPS/6443"
        schedulerPlugins -> kubernetes "Schedules pods atomically via PodGroup CRD" "HTTPS/6443"

        # Certificate management
        certManager -> webhook "Provisions TLS certificates for webhook server" "Optional"

        # External services
        trainingOperator -> containerRegistry "Pulls training container images" "HTTPS/443 TLS1.2+"

        # ODH integration
        odhOperator -> trainingOperator "Deploys via kustomize manifests to opendatahub namespace"

        # Python SDK
        pythonSDK -> kubernetes "Creates and manages training job CRDs" "HTTPS/6443 TLS1.2+"
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
            element "External Monitoring" {
                background #ff9900
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
