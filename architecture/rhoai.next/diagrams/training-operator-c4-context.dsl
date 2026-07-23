workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed AI/ML training jobs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator deployment"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator for managing distributed AI/ML training jobs across multiple frameworks (PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, JAX)" {
            controller = container "Training Operator Controller" "Manages training job CRD lifecycle, creates pods, services, and PodGroups" "Go (controller-runtime)" {
                pytorchController = component "PyTorch Controller" "Handles PyTorchJob reconciliation with elastic scaling, HPA, and NetworkPolicy support" "Go"
                tfController = component "TensorFlow Controller" "Handles TFJob reconciliation with parameter server and dynamic worker support" "Go"
                xgboostController = component "XGBoost Controller" "Handles XGBoostJob reconciliation with master-worker topology" "Go"
                mpiController = component "MPI Controller" "Handles MPIJob reconciliation with launcher-worker pattern and per-job RBAC" "Go"
                paddleController = component "PaddlePaddle Controller" "Handles PaddleJob reconciliation with elastic scaling" "Go"
                jaxController = component "JAX Controller" "Handles JAXJob reconciliation with coordinator-worker pattern" "Go"
                jobControllerBase = component "JobController Base" "Shared pod lifecycle, service management, status tracking, cleanup, gang scheduling" "Go"
            }
            webhookServer = container "Webhook Server" "Validates training job CRs on CREATE/UPDATE with framework-specific constraints" "Go HTTPS Server" "9443/TCP"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for training job lifecycle events" "Go HTTP Server" "8080/TCP"
            certController = container "OPA cert-controller" "Manages webhook TLS certificate rotation" "Go Library"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides TLS profile configuration for webhook/metrics TLS settings" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRDs for colocated training pod execution" "External"
        schedulerPlugins = softwareSystem "Scheduler-Plugins" "Alternative gang scheduling via scheduler-plugins PodGroups" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and monitoring" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys and manages the Training Operator via kustomize manifests" "Internal RHOAI"

        # Relationships
        user -> trainingOperator "Creates training job CRDs (PyTorchJob, TFJob, etc.) via kubectl/Dashboard"
        platformAdmin -> rhodsOperator "Configures operator deployment"

        trainingOperator -> k8sAPI "CRUD pods, services, configmaps, RBAC, PodGroups" "HTTPS/443"
        trainingOperator -> openShiftAPI "Reads TLS profile configuration (non-fatal if unavailable)" "HTTPS/443"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling (optional)" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroups for alternative gang scheduling (optional)" "HTTPS/443"
        prometheus -> trainingOperator "Scrapes training_operator_jobs_* metrics via PodMonitor" "HTTP/8080"
        rhodsOperator -> trainingOperator "Deploys via kustomize manifests (manifests/rhoai/)"
        k8sAPI -> trainingOperator "Routes admission webhook validation requests" "HTTPS/9443"

        # Internal container relationships
        controller -> webhookServer "Validates CRs"
        certController -> webhookServer "Rotates TLS certificates"
        controller -> k8sAPI "Manages training workload resources" "HTTPS/443"
        webhookServer -> k8sAPI "Receives admission requests" "HTTPS/9443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3d9
                color #ffffff
            }
            element "Component" {
                background #7bb8e0
                color #333333
            }
        }
    }
}
