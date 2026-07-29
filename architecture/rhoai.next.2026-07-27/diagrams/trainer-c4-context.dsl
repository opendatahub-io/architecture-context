workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRDs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntimes and operator settings"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator managing distributed ML training job lifecycle through TrainJob orchestration via JobSet with gang scheduling support" {
            controllerManager = container "Controller Manager" "Reconciles TrainJob resources, resolves runtime templates, creates downstream JobSet workloads" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources on CREATE/UPDATE" "Validating Admission Webhooks (TLS :9443)"
            runtimePlugins = container "Runtime Plugins" "Pluggable framework for JobSet creation, MPI configuration, and gang scheduling integration" "Go plugins"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and RBAC enforcement" "External"
        jobset = softwareSystem "JobSet" "Manages replicated Job sets for distributed workload execution" "Internal RHOAI"
        coscheduling = softwareSystem "Kubernetes Scheduler Plugins (CoScheduling)" "Gang scheduling via PodGroup resources for coordinated pod placement" "Internal RHOAI"
        volcano = softwareSystem "Volcano Scheduler" "Alternative gang scheduling via Volcano PodGroup resources" "Internal RHOAI"
        opaCertController = softwareSystem "OPA cert-controller" "Automated webhook certificate management and rotation" "External"
        openShiftAPI = softwareSystem "OpenShift API" "Provides cluster TLS profile configuration" "External"

        # Relationships
        dataScientist -> trainer "Creates TrainJob, TrainingRuntime via kubectl"
        platformAdmin -> trainer "Configures ClusterTrainingRuntime, Configuration CRDs"

        controllerManager -> webhookServer "Registers webhook handlers"
        controllerManager -> runtimePlugins "Delegates resource creation to plugins"

        trainer -> kubernetesAPI "Watches CRDs, creates JobSets/PodGroups/ConfigMaps/Secrets" "HTTPS/6443 TLS 1.2+"
        trainer -> jobset "Creates and reconciles JobSet workloads" "Kubernetes API"
        trainer -> coscheduling "Creates PodGroup for gang scheduling" "Kubernetes API"
        trainer -> volcano "Creates PodGroup for gang scheduling" "Kubernetes API"
        trainer -> opaCertController "Certificate management for webhook TLS"
        trainer -> openShiftAPI "Resolves cluster TLS profile" "Kubernetes API"

        kubernetesAPI -> trainer "Sends admission webhook requests" "HTTPS/9443 TLS"
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
        }
    }
}
