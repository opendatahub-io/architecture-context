workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"
        platformAdmin = person "Platform Admin" "Deploys and configures the training operator via RHOAI"

        trainer = softwareSystem "Kubeflow Trainer V2" "Orchestrates distributed ML training jobs via TrainJob CRDs and pluggable runtime templates" {
            controllerManager = container "trainer-controller-manager" "Reconciles TrainJob, TrainingRuntime, ClusterTrainingRuntime CRDs; creates JobSets, PodGroups, Secrets, ConfigMaps, NetworkPolicies" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime on CREATE/UPDATE" "Admission Webhook (9443/TCP HTTPS)"
            pluginFramework = container "Runtime Plugin Framework" "Extensible plugin system for ML policy enforcement (Torch, MPI, PlainML) and gang-scheduling (CoScheduling, Volcano)" "Go Library"
            progressionTracker = container "Progression Tracker (RHAI)" "Polls training pod metrics for real-time training progress reporting" "Go (HTTP client)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        jobsetController = softwareSystem "JobSet Controller" "Reconciles JobSet CRs into Jobs and Pods" "External (jobset.x-k8s.io)"
        kueue = softwareSystem "Kueue / scheduler-plugins" "Gang-scheduling via PodGroup for multi-node training" "External (optional)"
        volcano = softwareSystem "Volcano" "Alternative gang-scheduler for PodGroups" "External (optional)"
        certController = softwareSystem "cert-controller" "Internal webhook certificate management" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator, deploys trainer via kustomize" "Internal RHOAI"
        trainingImages = softwareSystem "Training Hub Images" "Pre-built CUDA/ROCm/CPU training images" "Internal RHOAI (registry.redhat.io)"

        # Relationships
        user -> trainer "Creates TrainJob via kubectl/Dashboard"
        platformAdmin -> rhodsOperator "Configures RHOAI platform"
        rhodsOperator -> trainer "Deploys via kustomize manifests"

        controllerManager -> webhookServer "Delegates validation"
        controllerManager -> pluginFramework "Enforces ML policies"
        controllerManager -> progressionTracker "Polls training metrics"

        trainer -> kubernetesAPI "Watches CRDs, creates resources" "HTTPS/443 TLS 1.2+ SA token"
        trainer -> jobsetController "Creates JobSet CRs" "Kubernetes API"
        trainer -> kueue "Creates PodGroup CRs (CoScheduling)" "Kubernetes API"
        trainer -> volcano "Creates PodGroup CRs (Volcano)" "Kubernetes API"

        kubernetesAPI -> webhookServer "Sends admission requests" "HTTPS/9443 TLS"
        certController -> trainer "Manages webhook TLS certificates"

        progressionTracker -> kubernetesAPI "Lists training pods, updates TrainJob status" "HTTPS/443"

        jobsetController -> kubernetesAPI "Creates Jobs/Pods from JobSets" "HTTPS/443"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI (registry.redhat.io)" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
