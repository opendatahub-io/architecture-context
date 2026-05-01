workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs"
        platformAdmin = person "Platform Admin" "Configures ClusterTrainingRuntimes and manages operator"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes operator for distributed ML training using plugin-based runtime framework" {
            controllerManager = container "trainer-controller-manager" "Reconciles TrainJob/TrainingRuntime/ClusterTrainingRuntime CRDs, manages training job lifecycle" "Go Operator (controller-runtime)"
            runtimeFramework = container "Runtime Framework" "Plugin system composing ML-specific and scheduling-specific Kubernetes resources" "Go Plugin System"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime on create/update" "Admission Webhooks (9443/TCP)"
            rhaiProgression = container "RHAI Progression Tracking" "Polls training pod metrics endpoints, stores progression as TrainJob annotations" "Go Controller Extension"

            controllerManager -> runtimeFramework "Uses plugin chain to compose resources"
            controllerManager -> webhookServer "Serves admission webhooks"
            controllerManager -> rhaiProgression "Runs progression tracking loop"
        }

        kubernetes = softwareSystem "Kubernetes" "Core platform for CRDs, controllers, and workloads" "External"
        jobsetController = softwareSystem "JobSet Controller" "Manages groups of related Jobs for distributed training" "External"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling via Volcano PodGroups" "Internal Platform"
        coscheduling = softwareSystem "Scheduler Plugins (CoScheduling)" "Gang scheduling via scheduler-plugins PodGroups" "Internal Platform"
        certController = softwareSystem "cert-controller" "Webhook certificate rotation and management" "External"
        openshiftRegistry = softwareSystem "OpenShift Image Registry" "Training Hub workbench images via ImageStreams" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "Internal Platform"
        kueue = softwareSystem "Kueue (MultiKueue)" "Optional workload scheduling and queuing" "Internal Platform"

        dataScientist -> trainer "Creates TrainJob via kubectl/API"
        platformAdmin -> trainer "Configures ClusterTrainingRuntimes"

        trainer -> kubernetes "CRD watches, resource CRUD, status updates" "HTTPS/443"
        trainer -> jobsetController "Creates JobSet resources" "Kubernetes API"
        trainer -> volcanoScheduler "Creates Volcano PodGroups" "Kubernetes API"
        trainer -> coscheduling "Creates CoScheduling PodGroups" "Kubernetes API"
        certController -> trainer "Manages webhook TLS certificates"
        trainer -> openshiftRegistry "References workbench ImageStreams"
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8443"
        kueue -> trainer "Manages TrainJob scheduling via managedBy field" "Kubernetes API"

        rhaiProgression -> kubernetes "Lists pods, patches TrainJob annotations" "HTTPS/443"
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
