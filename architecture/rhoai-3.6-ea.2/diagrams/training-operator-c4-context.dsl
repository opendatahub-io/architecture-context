workspace {
    model {
        datascientist = person "Data Scientist" "Creates and submits distributed training jobs for ML models"
        mlengineering = person "ML Engineer" "Manages training configurations, monitors job status"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes-native operator for orchestrating distributed training and fine-tuning of ML models across PyTorch, TensorFlow, JAX, XGBoost, PaddlePaddle, and MPI" {
            controllerManager = container "Controller Manager" "controller-runtime based manager hosting six framework reconcilers" "Go"
            pytorchReconciler = container "PyTorch Reconciler" "Manages PyTorchJob lifecycle including elastic training with HPA" "Go"
            tfReconciler = container "TensorFlow Reconciler" "Manages TFJob lifecycle" "Go"
            jaxReconciler = container "JAX Reconciler" "Manages JAXJob lifecycle" "Go"
            mpiReconciler = container "MPI Reconciler" "Manages MPIJob lifecycle with additional ConfigMaps, RBAC, and kubectl-delivery" "Go"
            xgboostReconciler = container "XGBoost Reconciler" "Manages XGBoostJob lifecycle" "Go"
            paddleReconciler = container "PaddlePaddle Reconciler" "Manages PaddleJob lifecycle" "Go"
            webhookServer = container "Webhook Server" "Validates training job specs at admission time (5 validating webhooks)" "Go, TLS 9443/TCP"
            certController = container "Cert Controller" "Self-managed TLS certificate rotation via OPA cert-controller" "Go"
            kubectlDelivery = container "kubectl-delivery" "Init container delivering kubectl binary to MPI launcher pods" "Shell"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        openshiftApiServer = softwareSystem "OpenShift APIServer" "OpenShift cluster configuration including TLS security profiles" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "Internal RHOAI"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRD" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Gang scheduling via PodGroup CRD" "External"

        datascientist -> trainingOperator "Submits PyTorchJob, TFJob, etc. via kubectl"
        mlengineering -> trainingOperator "Configures training parameters, monitors jobs"

        trainingOperator -> k8sApiServer "CRUD on Pods, Services, ConfigMaps, CRDs, RBAC, HPA, NetworkPolicies" "HTTPS/6443"
        trainingOperator -> openshiftApiServer "Reads cluster TLS security profile" "HTTPS/6443"
        trainingOperator -> volcanoScheduler "Creates PodGroups for gang scheduling" "HTTPS/6443 (via K8s API)"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling" "HTTPS/6443 (via K8s API)"
        prometheus -> trainingOperator "Scrapes operator metrics" "HTTP(S)/8080"

        k8sApiServer -> trainingOperator "Sends admission webhook requests" "HTTPS/9443"
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

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
