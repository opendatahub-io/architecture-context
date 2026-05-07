workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or OpenShift console"

        trainingOperator = softwareSystem "Kubeflow Training Operator (KFTO)" "Kubernetes-native operator managing distributed AI/ML training jobs across 6 frameworks" {
            controller = container "Training Operator Controller" "Reconciles 6 training job CRDs, manages Pod/Service lifecycle, gang scheduling integration" "Go Operator (controller-runtime)"
            pytorchController = container "PyTorchJob Controller" "Elastic training, HPA, init containers, NetworkPolicy, NCCL/Gloo rendezvous" "Go Controller"
            tfController = container "TFJob Controller" "TF_CONFIG generation, PS/Worker/Chief/Evaluator topology" "Go Controller"
            mpiController = container "MPIJob Controller" "Launcher/Worker RBAC, ConfigMap hostfiles, kubectl-delivery init container" "Go Controller"
            jaxController = container "JAXJob Controller" "Coordinator-based JAX distributed training" "Go Controller"
            paddleController = container "PaddleJob Controller" "Collective and parameter-server PaddlePaddle training" "Go Controller"
            xgboostController = container "XGBoostJob Controller" "XGBoost/LightGBM master/worker distributed training" "Go Controller"
            webhookServer = container "Webhook Server" "Validates CREATE/UPDATE of 5 training job CRDs (9443/TCP HTTPS)" "Go Admission Webhook"
            certManager = container "Certificate Manager" "Auto-generates and rotates TLS certs for webhook server" "cert-controller"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core API for Pod, Service, ConfigMap, RBAC, Event management" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRD (scheduling.volcano.sh/v1beta1)" "External Optional"
        schedulerPlugins = softwareSystem "Kubernetes scheduler-plugins" "Gang scheduling via PodGroup CRD (scheduling.x-k8s.io/v1alpha1)" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor on port 8080" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys KFTO via kustomize manifests" "Internal RHOAI"
        kueue = softwareSystem "Kueue (MultiKueue)" "Optional external controller via RunPolicy.ManagedBy" "External Optional"
        hpaController = softwareSystem "Kubernetes HPA Controller" "Horizontal Pod Autoscaler for elastic PyTorch training" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Cluster monitoring stack accessing /metrics via NetworkPolicy" "Internal RHOAI"

        # Relationships
        user -> trainingOperator "Creates training job CRDs via kubectl" "HTTPS/443"
        user -> kubernetesAPI "kubectl apply PyTorchJob/TFJob/MPIJob/JAXJob/PaddleJob/XGBoostJob" "HTTPS/443"

        trainingOperator -> kubernetesAPI "Pod, Service, ConfigMap, RBAC, Event, NetworkPolicy lifecycle" "HTTPS/443 TLS 1.2+"
        trainingOperator -> volcano "Creates/watches PodGroup CRDs for gang scheduling" "HTTPS/443 via K8s API"
        trainingOperator -> schedulerPlugins "Creates/watches PodGroup CRDs for gang scheduling" "HTTPS/443 via K8s API"
        trainingOperator -> hpaController "Creates HPA for elastic PyTorch training" "HTTPS/443 via K8s API"

        kubernetesAPI -> trainingOperator "Webhook validation calls" "HTTPS/9443 TLS (self-signed)"

        prometheus -> trainingOperator "Scrapes /metrics endpoint" "HTTP/8080"
        openshiftMonitoring -> trainingOperator "Metrics access via NetworkPolicy" "HTTP/8080"
        rhodsOperator -> trainingOperator "Deploys via manifests/rhoai kustomize overlay" "Kustomize"
        kueue -> trainingOperator "External controller via RunPolicy.ManagedBy" "K8s API"

        # Internal container relationships
        controller -> pytorchController "Delegates PyTorchJob reconciliation"
        controller -> tfController "Delegates TFJob reconciliation"
        controller -> mpiController "Delegates MPIJob reconciliation"
        controller -> jaxController "Delegates JAXJob reconciliation"
        controller -> paddleController "Delegates PaddleJob reconciliation"
        controller -> xgboostController "Delegates XGBoostJob reconciliation"
        certManager -> webhookServer "Provides TLS certificates"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
