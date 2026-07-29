workspace {
    model {
        platformAdmin = person "Platform Admin" "Deploys and manages RHOAI platform components"
        dataScientist = person "Data Scientist" "Creates and runs ML training jobs"

        trainerOperator = softwareSystem "Trainer Operator" "Meta-operator that manages the lifecycle of Kubeflow Trainer within RHOAI" {
            reconciler = container "TrainerReconciler" "Reconciles Trainer CR, renders and applies manifests" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime CRs" "Go HTTPS :9443"
            manifestRenderer = container "Manifest Renderer" "Renders embedded templates from /opt/*-template to /opt/manifests-work" "Go Library"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer Controller Manager" "Manages TrainJob lifecycle and creates training workloads" "Managed"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages monitoring resources (PodMonitors)" "Internal RHOAI"
        odhPlatformUtils = softwareSystem "ODH Platform Utilities" "Platform detection, manifest rendering, deployment helpers" "Internal RHOAI"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator subscriptions and conditions" "External"
        openshiftImageStreams = softwareSystem "OpenShift Image Streams" "Container image management and tagging" "External"
        jobsetOperator = softwareSystem "JobSet Operator" "Manages JobSet resources for distributed training" "External"

        # Platform admin deploys Trainer CR
        platformAdmin -> trainerOperator "Creates Trainer CR (default-trainer) via kubectl"

        # Data scientist creates training jobs
        dataScientist -> kubernetesAPI "Creates TrainJob CR via kubectl/SDK"

        # Trainer operator interactions
        trainerOperator -> kubernetesAPI "CRUD on CRDs, Deployments, Services, RBAC, Webhooks" "HTTPS/6443 TLS 1.2+"
        trainerOperator -> kubeflowTrainer "Deploys and manages via rendered manifests"
        trainerOperator -> prometheusOperator "Creates PodMonitor resources" "HTTPS (Kubernetes API)"
        trainerOperator -> olm "Reads operator subscription status" "HTTPS (Kubernetes API)"
        trainerOperator -> openshiftImageStreams "Manages image streams" "HTTPS (Kubernetes API)"

        # Kubeflow Trainer interactions
        kubeflowTrainer -> kubernetesAPI "Manages TrainJobs, creates JobSets" "HTTPS/6443 TLS 1.2+"
        kubeflowTrainer -> jobsetOperator "Creates JobSet resources for training workloads"

        # Internal library dependency
        reconciler -> manifestRenderer "Renders templates"
        reconciler -> webhookServer "Registers webhook handlers"

        # Webhook validates CRDs via API server
        kubernetesAPI -> webhookServer "Admission review requests" "HTTPS/443→9443 TLS"
    }

    views {
        systemContext trainerOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainerOperator "Containers" {
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
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
