workspace {
    model {
        admin = person "Platform Admin" "Creates and manages the Trainer CR to deploy the training stack"
        datascientist = person "Data Scientist" "Submits TrainJobs to train ML models"

        trainerOperator = softwareSystem "Trainer Operator" "Standalone operator that reconciles the Trainer CR to deploy and manage upstream Kubeflow Trainer v2 resources on OpenShift via kustomize rendering and Server-Side Apply" {
            controllerManager = container "trainer-operator-controller-manager" "Watches singleton Trainer CR, renders upstream manifests through RHOAI kustomize overlay, deploys via SSA, manages lifecycle (GC, finalization, upgrades)" "Go Operator"
            kustomizeRenderer = container "Kustomize Renderer" "Renders upstream Kubeflow Trainer manifests with RHOAI overlay and RELATED_IMAGE overrides" "Internal"
            tlsResolver = container "TLS Profile Resolver" "Resolves OpenShift cluster TLS profile and configures cipher suites; triggers restart on profile changes" "Internal"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2" "Upstream training controller-manager deployed and managed by this operator" {
            trainerController = container "kubeflow-trainer-controller-manager" "Manages TrainJobs, TrainingRuntimes, ClusterTrainingRuntimes, OptimizationJobs" "Go Controller"
            admissionWebhooks = container "Admission Webhooks" "Mutating (TrainJob defaulting) and Validating (TrainJob, TrainingRuntime, ClusterTrainingRuntime)" "Webhook Server"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD, watches, SSA" "External"
        jobsetOperator = softwareSystem "JobSet Operator" "Provides JobSet CRD required by Kubeflow Trainer" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile and adherence policy configuration" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitors for metrics collection" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from operator and trainer controller" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager; checked for JobSet Operator installation" "External"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Framework library providing reconciler lifecycle, action pipeline, GC, kustomize, SSA" "Internal ODH"

        admin -> trainerOperator "Creates Trainer CR (default-trainer)" "kubectl"
        datascientist -> kubeflowTrainer "Submits TrainJobs" "kubectl / SDK"
        trainerOperator -> kubernetesAPI "CR watch, resource CRUD, SSA deploy, GC" "HTTPS/6443"
        trainerOperator -> openshiftAPIServer "Reads cluster TLS profile" "HTTPS/6443"
        trainerOperator -> jobsetOperator "Verifies installation and health" "HTTPS/6443 (API)"
        trainerOperator -> olm "Checks JobSet Operator status" "HTTPS/6443 (API)"
        trainerOperator -> kubeflowTrainer "Deploys and manages via SSA"
        trainerOperator -> prometheusOperator "Creates ServiceMonitor" "HTTPS/6443 (API)"
        prometheus -> trainerOperator "Scrapes metrics" "HTTPS/8443"
        kubeflowTrainer -> kubernetesAPI "TrainJob reconciliation" "HTTPS/6443"
    }

    views {
        systemContext trainerOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainerOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container kubeflowTrainer "TrainerContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
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
