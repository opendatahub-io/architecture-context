workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed ML training across PyTorch, TensorFlow, XGBoost, MPI, JAX, and PaddlePaddle" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and manages Pod/Service lifecycle" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Manages PyTorch distributed training jobs" "Reconciler"
                tfController = component "TFJob Controller" "Manages TensorFlow distributed training jobs" "Reconciler"
                xgboostController = component "XGBoostJob Controller" "Manages XGBoost distributed training jobs" "Reconciler"
                mpiController = component "MPIJob Controller" "Manages MPI-based HPC training jobs" "Reconciler"
                jaxController = component "JAXJob Controller" "Manages JAX distributed training jobs" "Reconciler"
                paddleController = component "PaddleJob Controller" "Manages PaddlePaddle distributed training jobs" "Reconciler"
            }
            webhook = container "Validating Webhook Server" "Validates training job specifications before creation/update" "HTTPS/9443"
            certController = container "Cert Controller" "Manages TLS certificates for webhook server" "cert-controller library"
            metricsExporter = container "Metrics Exporter" "Exposes operator metrics for Prometheus" "HTTP/8080"
        }

        k8s = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for efficient resource allocation" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling implementation" "External Optional"
        opendatahubOperator = softwareSystem "opendatahub-operator" "RHOAI platform operator" "Internal RHOAI"

        # User interactions
        user -> trainingOperator "Creates PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob via kubectl"
        user -> k8s "Submits training jobs" "kubectl/HTTPS/443"

        # Operator interactions
        trainingOperator -> k8s "Watches CRDs, creates Pods/Services/ConfigMaps" "HTTPS/443 + SA token"
        k8s -> webhook "Validates job specifications during admission control" "HTTPS/9443 + mTLS"
        trainingOperator -> prometheus "Exposes metrics" "HTTP/8080"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling" "HTTPS/443 (optional)"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling" "HTTPS/443 (optional)"
        opendatahubOperator -> trainingOperator "Deploys and manages operator lifecycle"

        # Internal relationships
        controller -> webhook "Uses for admission validation"
        certController -> webhook "Provides TLS certificates"
        pytorchController -> k8s "Creates PyTorch training pods"
        tfController -> k8s "Creates TensorFlow training pods"
        xgboostController -> k8s "Creates XGBoost training pods"
        mpiController -> k8s "Creates MPI training pods"
        jaxController -> k8s "Creates JAX training pods"
        paddleController -> k8s "Creates PaddlePaddle training pods"
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
            element "Internal RHOAI" {
                background #7ed321
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
                background #7ed321
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
