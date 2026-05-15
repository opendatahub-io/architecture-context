workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or APIs"

        trainingOperator = softwareSystem "Training Operator (KFTO)" "Kubernetes operator managing distributed ML training across 6 frameworks: PyTorch, TensorFlow, MPI, XGBoost, PaddlePaddle, JAX" {
            controller = container "Training Operator Controller" "Unified controller base with framework-specific implementations for job lifecycle management" "Go (controller-runtime)" {
                pytorchCtrl = component "PyTorchJob Controller" "Reconciles PyTorchJobs; supports elastic training with HPA and NetworkPolicy" "Go"
                tfCtrl = component "TFJob Controller" "Reconciles TFJobs; generates TF_CONFIG for distributed TensorFlow" "Go"
                mpiCtrl = component "MPIJob Controller" "Reconciles MPIJobs; manages launcher/worker lifecycle, ConfigMaps, RBAC" "Go"
                xgboostCtrl = component "XGBoostJob Controller" "Reconciles XGBoostJobs; Rabit-based coordination" "Go"
                paddleCtrl = component "PaddleJob Controller" "Reconciles PaddleJobs; Collective and PS modes" "Go"
                jaxCtrl = component "JAXJob Controller" "Reconciles JAXJobs; coordinator-based synchronization" "Go"
                commonBase = component "Common Controller Base" "Generic job lifecycle: pod reconciliation, service management, status tracking, cleanup" "Go"
                gangScheduling = component "Gang Scheduling" "PodGroupControlInterface for Volcano and scheduler-plugins" "Go"
            }
            webhookServer = container "Webhook Server" "Validates job CRs on create/update (5 validating webhooks, no MPI webhook)" "Go, HTTPS/9443"
            certManager = container "Certificate Manager" "Self-manages webhook TLS certificates via cert-controller" "Go (open-policy-agent/cert-controller)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on /metrics" "Go, HTTP/8080"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        rhods = softwareSystem "rhods-operator" "RHOAI platform operator that deploys and configures training-operator" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRD; delays pod creation until Inqueue" "External, Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling via PodGroup CRD; pods created immediately" "External, Optional"
        kueue = softwareSystem "Kueue / MultiKueue" "Multi-cluster job queue management via ManagedBy field delegation" "External, Optional"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "External"
        k8sAutoscaling = softwareSystem "Kubernetes HPA" "Horizontal Pod Autoscaler for PyTorch elastic scaling" "External"

        # Relationships
        user -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob, JAXJob CRs" "kubectl / HTTPS"
        trainingOperator -> k8sAPI "Watches CRDs, creates/manages Pods, Services, ConfigMaps, RBAC" "HTTPS/443, SA Token"
        k8sAPI -> trainingOperator "Sends admission webhook requests" "HTTPS/9443, TLS Certificate"
        rhods -> trainingOperator "Deploys via kustomize manifests/rhoai overlay" "Kustomize"
        trainingOperator -> volcano "Creates/manages Volcano PodGroups for gang scheduling" "HTTPS/443, SA Token"
        trainingOperator -> schedulerPlugins "Creates/manages scheduler-plugins PodGroups" "HTTPS/443, SA Token"
        trainingOperator -> kueue "Delegates job management via RunPolicy.ManagedBy field" "CRD field"
        prometheus -> trainingOperator "Scrapes training_operator_jobs_* metrics" "HTTP/8080, PodMonitor"
        trainingOperator -> k8sAutoscaling "Creates HPA for elastic PyTorchJobs" "HTTPS/443, SA Token"

        # Internal container relationships
        controller -> webhookServer "Shares process; webhooks validate before reconciliation"
        certManager -> webhookServer "Provisions and rotates TLS certificates"
        pytorchCtrl -> commonBase "Implements ControllerInterface"
        tfCtrl -> commonBase "Implements ControllerInterface"
        mpiCtrl -> commonBase "Own lifecycle (architectural outlier)"
        xgboostCtrl -> commonBase "Implements ControllerInterface"
        paddleCtrl -> commonBase "Implements ControllerInterface"
        jaxCtrl -> commonBase "Implements ControllerInterface"
        commonBase -> gangScheduling "Delegates PodGroup management"
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
            element "External, Optional" {
                background #cccccc
                color #333333
                shape RoundedBox
            }
            element "Internal RHOAI" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
