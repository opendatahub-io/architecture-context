workspace {
    model {
        user = person "Data Scientist" "Creates and monitors distributed training jobs for ML models"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages distributed training workloads for PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX frameworks" {
            controllerManager = container "Controller Manager" "Manages training job lifecycle and resource creation" "Go Operator" {
                pytorchController = component "PyTorchJob Controller" "Reconciles PyTorchJob CRs" "Go Controller"
                tfController = component "TFJob Controller" "Reconciles TFJob CRs" "Go Controller"
                mpiController = component "MPIJob Controller" "Reconciles MPIJob CRs" "Go Controller"
                xgboostController = component "XGBoostJob Controller" "Reconciles XGBoostJob CRs" "Go Controller"
                paddleController = component "PaddleJob Controller" "Reconciles PaddleJob CRs" "Go Controller"
                jaxController = component "JAXJob Controller" "Reconciles JAXJob CRs" "Go Controller"
            }
            webhookServer = container "Webhook Server" "Validates training job specifications on CREATE/UPDATE" "Go ValidatingWebhook"
            metricsExporter = container "Metrics Exporter" "Exposes Prometheus metrics for operator and jobs" "Go HTTP Server"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for training jobs" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Alternative gang scheduling implementation" "External Optional"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores trained model metadata and artifacts" "Internal ODH"

        s3 = softwareSystem "S3 Storage" "Object storage for datasets and trained models" "External"
        registry = softwareSystem "Container Registry" "Stores training container images" "External"

        # Relationships
        user -> trainingOperator "Creates and monitors training jobs via kubectl/UI"
        user -> odhDashboard "Manages training jobs via web UI"

        odhDashboard -> trainingOperator "Creates training job CRs via K8s API" "HTTPS/443"

        trainingOperator -> k8s "Watches CRs, manages pods/services/events" "HTTPS/443"
        k8s -> webhookServer "Validates training job specs" "HTTPS/9443"

        trainingOperator -> volcano "Creates PodGroups for gang scheduling" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling" "HTTPS/443"

        prometheus -> metricsExporter "Scrapes operator and job metrics" "HTTP/8080"

        controllerManager -> s3 "Training pods load datasets and save models" "HTTPS/443"
        controllerManager -> registry "Pulls training container images" "HTTPS/443"
        controllerManager -> modelRegistry "Stores model metadata post-training" "gRPC/HTTP"
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

        component controllerManager "Components" {
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
                color #000000
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
                background #4a90e2
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
