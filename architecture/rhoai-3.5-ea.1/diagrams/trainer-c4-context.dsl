workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRDs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntimes and deploys the trainer operator"

        trainer = softwareSystem "Kubeflow Trainer V2" "Kubernetes operator that manages distributed ML training jobs by reconciling TrainJob CRs into JobSet workloads using pluggable TrainingRuntime templates" {
            controller = container "TrainJob Controller" "Reconciles TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; orchestrates plugin framework" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime on create/update" "Go (9443/TCP HTTPS)"
            pluginFramework = container "Plugin Framework" "Pluggable ML policy enforcement (Torch, MPI, TorchTune), gang-scheduling (Coscheduling, Volcano), and JobSet construction" "Go"
            progressionTracker = container "Progression Tracker (RHAI)" "Polls training pod /metrics endpoints for real-time training progress; stores in TrainJob annotations" "Go (RHOAI extension)"
            certController = container "Cert Controller" "Self-managed webhook certificate rotation" "Go (open-policy-agent/cert-controller)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics over secure HTTPS" "Go (8443/TCP HTTPS)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (API server, etcd, scheduler)" "External"
        jobsetOperator = softwareSystem "JobSet Operator" "Manages multi-replica workloads via JobSet CRDs" "Internal Platform"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Gang-scheduling via coscheduling PodGroups" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Gang-scheduling with network topology support via Volcano PodGroups" "Internal Platform"
        kueue = softwareSystem "Kueue (MultiKueue)" "Multi-cluster job management via managedBy field delegation" "Internal Platform"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and monitoring" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys trainer controller and ClusterTrainingRuntimes via kustomize" "Internal Platform"
        trainingPods = softwareSystem "Training Pods" "User ML training workloads (PyTorch, MPI, TorchTune) created by JobSet" "Runtime"

        # User interactions
        user -> trainer "Creates TrainJob CR via kubectl/Dashboard"
        platformAdmin -> trainer "Configures ClusterTrainingRuntimes"

        # Controller outbound
        trainer -> kubernetes "CRUD on CRDs, JobSet, PodGroup, NetworkPolicy, ConfigMap, Secret" "HTTPS/443 TLS 1.2+ ServiceAccount Bearer Token"
        trainer -> jobsetOperator "Creates JobSet resources owned by TrainJob" "via Kubernetes API"
        trainer -> schedulerPlugins "Creates PodGroup for gang-scheduling" "via Kubernetes API"
        trainer -> volcano "Creates Volcano PodGroup for gang-scheduling" "via Kubernetes API"
        trainer -> trainingPods "Polls /metrics for progression tracking (RHAI)" "HTTP/28080 plaintext NetworkPolicy enforced"

        # Inbound
        kubernetes -> trainer "Webhook validation calls" "HTTPS/9443 TLS self-managed certs"
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8443 TLS PodMonitor"
        rhodsOperator -> trainer "Deploys controller and runtimes" "kustomize manifests"

        # Integration
        kueue -> trainer "Delegates scheduling via managedBy field" "N/A"
        jobsetOperator -> trainingPods "Creates Jobs and Pods from JobSet" "via Kubernetes API"
    }

    views {
        systemContext trainer "SystemContext" {
            include *
            autoLayout
        }

        container trainer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
