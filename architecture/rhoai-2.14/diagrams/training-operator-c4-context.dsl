workspace {
    model {
        datascientist = person "Data Scientist" "Creates and monitors distributed ML training jobs"
        mlEngineer = person "ML Engineer" "Configures training infrastructure and manages resources"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for distributed training of machine learning models across PyTorch, TensorFlow, MPI, MXNet, XGBoost, and PaddlePaddle frameworks" {
            manager = container "Training Operator Manager" "Reconciles training job CRDs and manages lifecycle" "Go Binary" {
                pytorchController = component "PyTorch Controller" "Manages PyTorchJob CRs and elastic training" "Go Reconciler"
                tfController = component "TensorFlow Controller" "Manages TFJob CRs with parameter servers" "Go Reconciler"
                mpiController = component "MPI Controller" "Manages MPIJob CRs for MPI-based training" "Go Reconciler"
                mxnetController = component "MXNet Controller" "Manages MXJob CRs" "Go Reconciler"
                xgboostController = component "XGBoost Controller" "Manages XGBoostJob CRs" "Go Reconciler"
                paddleController = component "PaddlePaddle Controller" "Manages PaddleJob CRs" "Go Reconciler"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for job and controller health" "HTTP Endpoint :8080"
            healthProbes = container "Health Probe Server" "Provides liveness and readiness probes" "HTTP Endpoint :8081"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        dashboard = softwareSystem "ODH Dashboard" "User interface for creating and monitoring training jobs" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduler for batch scheduling of training pods" "External (Optional)"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduler implementation" "External (Optional)"
        registry = softwareSystem "Container Registry" "Stores training container images and operator image" "External"

        # User interactions
        datascientist -> dashboard "Creates PyTorchJob/TFJob via UI"
        datascientist -> kubernetes "Creates training jobs via kubectl/API" "kubectl/HTTPS 443"
        mlEngineer -> trainingOperator "Configures gang scheduling, resource limits" "kubectl/HTTPS 443"
        mlEngineer -> prometheus "Monitors training job metrics and health"

        # Operator interactions with Kubernetes
        trainingOperator -> kubernetes "Watches CRDs, creates Pods/Services/ConfigMaps, updates status" "HTTPS 443/TCP, ServiceAccount Token"
        kubernetes -> trainingOperator "Sends watch events for training job CRs" "Watch API"

        # Operator interactions with ODH components
        dashboard -> kubernetes "Creates training job CRs via Kubernetes API" "HTTPS 443/TCP"
        prometheus -> metricsServer "Scrapes /metrics endpoint" "HTTP 8080/TCP"
        kubernetes -> healthProbes "Health and readiness probes" "HTTP 8081/TCP"

        # Gang scheduling (optional)
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "Kubernetes API"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "Kubernetes API"
        volcano -> kubernetes "Reads PodGroups, schedules pods atomically" "HTTPS 443/TCP"
        schedulerPlugins -> kubernetes "Reads PodGroups, schedules pods atomically" "HTTPS 443/TCP"

        # External dependencies
        trainingOperator -> registry "Pulls operator image" "HTTPS 443/TCP, Pull Secrets"
        kubernetes -> registry "Pulls training container images" "HTTPS 443/TCP, Pull Secrets"
    }

    views {
        systemContext trainingOperator "TrainingOperatorContext" {
            include *
            autoLayout
        }

        container trainingOperator "TrainingOperatorContainers" {
            include *
            autoLayout
        }

        component manager "TrainingOperatorComponents" {
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
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
