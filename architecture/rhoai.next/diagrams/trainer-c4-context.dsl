workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs"
        clusterAdmin = person "Cluster Admin" "Manages ClusterTrainingRuntimes and operator configuration"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator managing distributed ML training jobs via plugin-based runtime framework" {
            controllerManager = container "trainer-controller-manager" "Manages TrainJob lifecycle, creates JobSets and supporting resources via plugin framework" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime on create/update" "Admission Webhook, 9443/TCP"
            runtimeFramework = container "Runtime Plugin Framework" "Composes ML-specific and scheduling-specific Kubernetes resources" "Go Plugin System" {
                torchPlugin = component "PyTorch Plugin" "Configures PyTorch distributed training (torchrun, rendezvous)" "EnforceMLPolicy"
                mpiPlugin = component "MPI Plugin" "Configures OpenMPI training with SSH keys and hostfiles" "EnforceMLPolicy"
                torchtunePlugin = component "TorchTune Plugin" "Configures TorchTune fine-tuning workloads" "EnforceMLPolicy"
                jobsetPlugin = component "JobSet Plugin" "Creates JobSet resources and headless services" "ComponentBuilder"
                volcanoPlugin = component "Volcano Plugin" "Creates Volcano PodGroups for gang scheduling" "EnforcePodGroupPolicy"
                coschedulingPlugin = component "CoScheduling Plugin" "Creates scheduler-plugins PodGroups" "EnforcePodGroupPolicy"
            }
            rhaiProgression = container "RHAI Progression Tracking" "Polls training pod metrics and stores progression as TrainJob annotations" "Go Controller Extension, RHOAI-only"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes API for CRD management and resource operations" "HTTPS/443"
        }

        jobset = softwareSystem "JobSet Controller" "Manages groups of related Jobs for distributed training" "External"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling via Volcano PodGroups" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins (CoScheduling)" "Gang scheduling via scheduler-plugins PodGroups" "External"
        certController = softwareSystem "cert-controller (OPA)" "Webhook certificate rotation and management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "External"
        openshiftRegistry = softwareSystem "OpenShift Image Registry" "Training Hub workbench images via ImageStreams" "Internal RHOAI"

        # Relationships
        dataScientist -> trainer "Creates TrainJob via kubectl/API" "HTTPS/443"
        clusterAdmin -> trainer "Manages ClusterTrainingRuntimes" "HTTPS/443"

        controllerManager -> webhookServer "Runs admission validation" "In-process"
        controllerManager -> runtimeFramework "Delegates resource composition" "In-process"
        controllerManager -> rhaiProgression "Tracks training progression" "In-process"

        controllerManager -> apiServer "CRD watches, resource CRUD, status updates" "HTTPS/443, SA Bearer Token"
        rhaiProgression -> apiServer "List pods, patch annotations" "HTTPS/443, SA Bearer Token"

        trainer -> jobset "Creates JobSet resources" "Kubernetes API, TLS"
        trainer -> volcanoScheduler "Creates Volcano PodGroups" "Kubernetes API, TLS"
        trainer -> schedulerPlugins "Creates scheduler-plugins PodGroups" "Kubernetes API, TLS"
        certController -> trainer "Manages webhook certificates" "Certificate rotation"
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8443, PodMonitor"
        trainer -> openshiftRegistry "References Training Hub images" "ImageStream"

        apiServer -> webhookServer "Admission validation requests" "HTTPS/9443, TLS Client Cert"
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

        component runtimeFramework "RuntimePlugins" {
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
