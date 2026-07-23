workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"
        platformAdmin = person "Platform Admin" "Deploys and configures the training operator"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator for managing distributed ML training jobs across PyTorch, TensorFlow, XGBoost, JAX, MPI, and PaddlePaddle" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs, creates Pods, Services, and supporting resources" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates training job CRDs on CREATE and UPDATE operations" "Go (9443/TCP HTTPS)"
            certRotator = container "Cert Rotator" "Manages webhook TLS certificate lifecycle" "OPA cert-controller"
            metricsServer = container "Metrics Endpoint" "Exposes Prometheus metrics for training jobs" "Go (8080/TCP HTTP+TLS)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting system with Prometheus Operator" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys training-operator via Kustomize" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduling via PodGroups" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler-Plugins" "Optional alternative gang scheduling" "External Optional"
        hpaController = softwareSystem "HPA Controller" "Horizontal Pod Autoscaler for elastic PyTorch training" "External"
        kueue = softwareSystem "Kueue (MultiKueue)" "Optional external job management via ManagedBy field" "External Optional"

        # User interactions
        user -> trainingOperator "Creates training jobs (PyTorchJob, TFJob, MPIJob, etc.) via kubectl" "HTTPS/443"
        platformAdmin -> rhodsOperator "Configures platform deployment"

        # Operator interactions
        trainingOperator -> k8sAPI "Reconciles CRDs, creates Pods/Services/ConfigMaps/RBAC" "HTTPS/443 TLS 1.2+"
        trainingOperator -> openShiftAPI "Reads cluster TLS security profile" "HTTPS/443 TLS 1.2+"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroups (alternative scheduler)" "HTTPS/443"
        trainingOperator -> hpaController "Creates HPAs for PyTorch elastic training" "HTTPS/443"

        # Platform interactions
        k8sAPI -> trainingOperator "Sends admission review requests to webhook" "HTTPS/9443"
        prometheus -> trainingOperator "Scrapes metrics via PodMonitor" "HTTP/8080 TLS"
        rhodsOperator -> trainingOperator "Deploys via Kustomize manifests" "Kustomize"

        # Internal container relationships
        controller -> webhookServer "Validates CRDs before processing"
        certRotator -> webhookServer "Provides auto-rotated TLS certificates"
        controller -> metricsServer "Registers training_operator_jobs_* counters"
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
                background #cccccc
                color #333333
                border dashed
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
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
        }
    }
}
