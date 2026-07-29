workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or notebook UIs"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator managing distributed ML training jobs (PyTorch, TensorFlow, MPI, XGBoost, Paddle, JAX) via Kubeflow Training v1 API" {
            controllerManager = container "Controller Manager" "Hosts 6 reconcilers for training job CRDs, manages pod lifecycle, services, RBAC, and optional gang scheduling" "Go / controller-runtime 0.19.1"
            webhookServer = container "Webhook Server" "Validates training job CRDs on CREATE/UPDATE with TLS on port 9443" "Go / Validating Admission Webhook"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics over TLS on port 8080" "Go / prometheus/client_golang"
            certController = container "cert-controller" "Manages TLS certificate rotation for webhook and metrics servers" "Go / OPA cert-controller"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, watches, and admission webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        openShiftConfig = softwareSystem "OpenShift Cluster Config" "Provides cluster-wide TLS profile via config.openshift.io/v1/APIServer" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduling via PodGroup CRDs" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Optional gang scheduling via scheduling.x-k8s.io PodGroup CRDs" "External Optional"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench integration" "Internal RHOAI"

        # Relationships
        user -> trainingOperator "Submits training jobs via CRDs (PyTorchJob, TFJob, MPIJob, etc.)"
        trainingOperator -> k8sAPI "Watches CRDs, creates Pods/Services/RBAC/NetworkPolicies" "HTTPS+WSS/6443 TLS 1.2+"
        trainingOperator -> openShiftConfig "Reads cluster TLS profile at startup" "HTTPS/6443"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling" "via K8s API (optional)"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang scheduling" "via K8s API (optional)"
        trainingOperator -> kubeflowNotebooks "Integrates with notebook workbenches" "CRD CRUD"
        prometheus -> trainingOperator "Scrapes training operator metrics" "HTTPS/8080 TLS"
        k8sAPI -> trainingOperator "Sends admission webhook requests" "HTTPS/9443 TLS"

        # Internal container relationships
        controllerManager -> webhookServer "Registers webhook handlers"
        controllerManager -> metricsServer "Registers metrics collectors"
        certController -> webhookServer "Provides TLS certificates"
        certController -> metricsServer "Provides TLS certificates"
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
