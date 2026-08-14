workspace {
    model {
        admin = person "Platform Admin" "Manages RHOAI platform components"
        datascientist = person "Data Scientist" "Creates and runs distributed training jobs"

        trainerOperator = softwareSystem "trainer-operator" "Kubernetes operator that reconciles the Trainer component CR to deploy and manage Kubeflow Trainer v2 on OpenShift AI" {
            controller = container "Trainer Controller" "Watches Trainer CR and reconciles Kubeflow Trainer v2 resources using odh-platform-utilities framework" "Go controller-runtime"
            reconciler = container "Reconciliation Pipeline" "Sequential action pipeline: checkDependencies → ensureNamespace → updateReleases → renderManifests → deploy" "odh-platform-utilities/framework"
            manifests = container "Bundled Manifests" "Trainer infrastructure, training runtimes, and OpenShift image stream templates" "Kustomize/YAML"
        }

        platformOperator = softwareSystem "ODH Platform Operator" "Creates and manages component CRs including the Trainer CR" "Internal RHOAI"
        jobsetOperator = softwareSystem "JobSet Operator" "Manages JobSet CRDs for distributed job orchestration; hard prerequisite on OpenShift" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource CRUD operations" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via PodMonitor" "Internal RHOAI"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared Go library for platform detection, manifest rendering, and deployment helpers" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2" "Distributed training framework providing TrainJobs, TrainingRuntimes, ClusterTrainingRuntimes" "External"

        admin -> platformOperator "Configures Trainer component"
        platformOperator -> trainerOperator "Creates/updates Trainer CR" "Kubernetes API"
        trainerOperator -> kubeAPI "CRUD on resources" "HTTPS/6443 TLS 1.2+"
        trainerOperator -> jobsetOperator "Verifies installation and health" "Kubernetes API"
        trainerOperator -> kubeflowTrainer "Deploys TrainJobs, Runtimes" "Kubernetes API"
        prometheus -> trainerOperator "Scrapes metrics" "HTTP/8080"
        controller -> reconciler "Executes action pipeline"
        reconciler -> manifests "Renders templates"

        datascientist -> kubeflowTrainer "Creates TrainJobs for distributed training"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
