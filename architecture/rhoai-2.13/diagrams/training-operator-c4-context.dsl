workspace {
    model {
        user = person "Data Scientist" "Creates and runs distributed ML training jobs"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator for distributed ML training across multiple frameworks" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs and manages distributed training workloads" "Go Operator" {
                pytorchCtrl = component "PyTorch Controller" "Manages PyTorchJob resources" "Go Reconciler"
                tfCtrl = component "TensorFlow Controller" "Manages TFJob resources" "Go Reconciler"
                mpiCtrl = component "MPI Controller" "Manages MPIJob resources" "Go Reconciler"
                xgboostCtrl = component "XGBoost Controller" "Manages XGBoostJob resources" "Go Reconciler"
                mxnetCtrl = component "MXNet Controller" "Manages MXNetJob resources" "Go Reconciler"
                paddleCtrl = component "PaddlePaddle Controller" "Manages PaddleJob resources" "Go Reconciler"
            }
            pythonSDK = container "Python SDK" "High-level TrainingClient API for job management" "Python Library (kubeflow-training 1.7.0)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External/Optional"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for coordinated pod scheduling" "External/Optional"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Alternative gang scheduling implementation" "External/Optional"
        objectStorage = softwareSystem "Object Storage" "Stores training datasets and model checkpoints" "External (S3/etc)"
        containerRegistry = softwareSystem "Container Registries" "Stores training container images" "External"

        # Relationships
        user -> trainingOperator "Creates distributed training jobs via kubectl or Python SDK"
        user -> pythonSDK "Uses TrainingClient API" "Python"

        pythonSDK -> kubernetes "Creates PyTorchJob, TFJob, MPIJob CRDs" "HTTPS/443"

        controller -> kubernetes "Watches CRDs, creates pods/services/configmaps" "HTTPS/443 (ServiceAccount Token)"
        controller -> prometheus "Exposes operator metrics" "HTTP/8080"
        controller -> volcano "Creates PodGroups for gang scheduling (optional)" "HTTPS/443"
        controller -> schedulerPlugins "Creates PodGroups for gang scheduling (optional)" "HTTPS/443"

        pytorchCtrl -> kubernetes "Reconciles PyTorchJob, creates master/worker pods" "In-cluster"
        tfCtrl -> kubernetes "Reconciles TFJob, creates parameter server/worker pods" "In-cluster"
        mpiCtrl -> kubernetes "Reconciles MPIJob, creates launcher/worker pods" "In-cluster"
        xgboostCtrl -> kubernetes "Reconciles XGBoostJob" "In-cluster"
        mxnetCtrl -> kubernetes "Reconciles MXJob" "In-cluster"
        paddleCtrl -> kubernetes "Reconciles PaddleJob" "In-cluster"

        kubernetes -> objectStorage "Training pods download datasets and save checkpoints" "HTTPS/443"
        kubernetes -> containerRegistry "Pulls training container images" "HTTPS/443"

        prometheus -> controller "Scrapes /metrics endpoint" "HTTP/8080"
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
            element "External/Optional" {
                background #cccccc
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #f5a623
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
