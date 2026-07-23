workspace {
    model {
        dataScientist = person "Data Scientist" "Creates TrainJob CRs to submit distributed training workloads"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform installation and configuration"

        trainerOperator = softwareSystem "Trainer Operator" "Manages lifecycle of Kubeflow Trainer V2 training stack on OpenShift" {
            operatorController = container "odh-trainer-operator" "Watches Trainer CR, validates dependencies, renders kustomize manifests, deploys Kubeflow Trainer controller" "Go Operator"
            kfController = container "kubeflow-trainer-controller-manager" "Reconciles TrainJob CRs, creates JobSets for distributed training" "Go Controller (deployed)"
            webhook = container "Validating Webhook" "Validates TrainJob, ClusterTrainingRuntime, TrainingRuntime CRs on CREATE/UPDATE" "Webhook Server, 9443/TCP TLS"
            clusterRuntimes = container "ClusterTrainingRuntimes" "Pre-configured training templates: PyTorch (CUDA/ROCm/CPU), DeepSpeed, MLX, TorchTune" "CRDs"
            imageStreams = container "ImageStreams" "OpenShift ImageStreams for training-hub-universal workbench images (CPU, CUDA, ROCm)" "OpenShift Resources"
        }

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that manages component modules" "Internal RHOAI"
        jobsetOperator = softwareSystem "JobSet Operator" "Provides JobSet CRD for distributed job orchestration" "External"
        jobsetController = softwareSystem "JobSet Controller" "Orchestrates Kubernetes Jobs from JobSet CRs" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        openshiftImageRegistry = softwareSystem "OpenShift Image Registry" "Hosts container images referenced by ImageStreams" "External"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling for training workloads" "External (optional)"
        kueueScheduler = softwareSystem "Kueue" "Pod-level scheduling for training workloads" "External (optional)"

        # Relationships
        platformAdmin -> rhodsOperator "Configures platform via DSCInitialization/DataScienceCluster"
        rhodsOperator -> trainerOperator "Creates Trainer CR (default-trainer)" "HTTPS/6443 via K8s API"
        dataScientist -> trainerOperator "Creates TrainJob CRs" "HTTPS/6443 via K8s API"

        operatorController -> jobsetOperator "Validates dependency health" "HTTPS/6443 via K8s API"
        operatorController -> kfController "Deploys via kustomize manifests" "Server-side apply"
        operatorController -> clusterRuntimes "Provisions training runtime templates" "Server-side apply"
        operatorController -> imageStreams "Provisions workbench image references" "Server-side apply"

        kfController -> jobsetController "Creates JobSet CRs for distributed training" "HTTPS/6443 via K8s API"
        kfController -> webhook "Registers webhook configurations" "HTTPS/9443"

        prometheus -> trainerOperator "Scrapes metrics" "HTTPS/8443, HTTP/8080"
        trainerOperator -> openshiftImageRegistry "References container images via ImageStreams"
        kfController -> volcanoScheduler "Creates PodGroups for gang scheduling" "HTTPS/6443 via K8s API"
        kfController -> kueueScheduler "Creates PodGroups for pod scheduling" "HTTPS/6443 via K8s API"
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
            element "External (optional)" {
                background #cccccc
                color #333333
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
