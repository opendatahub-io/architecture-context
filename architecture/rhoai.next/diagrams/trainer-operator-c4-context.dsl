workspace {
    model {
        admin = person "Platform Admin" "Configures and manages the RHOAI platform"
        datascientist = person "Data Scientist" "Creates and runs distributed training jobs"

        trainerOperator = softwareSystem "Trainer Operator" "Reconciles Trainer CR to deploy and lifecycle-manage Kubeflow Trainer v2 on OpenShift" {
            controller = container "trainer-operator" "Watches Trainer CR, renders kustomize overlays, applies via SSA" "Go Operator (controller-runtime)"
            kfController = container "kubeflow-trainer-controller-manager" "Manages TrainJob lifecycle, creates JobSets, runs admission webhooks" "Deployed Deployment"
            webhooks = container "Admission Webhooks" "Defaults and validates TrainJobs, TrainingRuntimes, ClusterTrainingRuntimes" "Webhook Server (port 9443)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        jobsetOperator = softwareSystem "JobSet Operator" "Manages JobSet resources for batch workloads" "External"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared reconciliation framework for ODH operators" "Internal RHOAI"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages monitoring resources (ServiceMonitor)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        olm = softwareSystem "OLM / ClusterExtensions" "Operator lifecycle management" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile configuration" "External"

        admin -> trainerOperator "Creates Trainer CR (default-trainer) via kubectl"
        datascientist -> kfController "Creates TrainJob CRs"

        controller -> k8sAPI "Watch Trainer CR, SSA deploy manifests" "HTTPS/6443"
        controller -> jobsetOperator "Checks operator health as prerequisite" "HTTPS/6443"
        controller -> openshiftAPIServer "Reads cluster TLS profile" "HTTPS/6443"
        controller -> prometheusOperator "Creates ServiceMonitor" "HTTPS/6443"

        kfController -> k8sAPI "Manages JobSets, watches TrainJobs" "HTTPS/6443"
        k8sAPI -> webhooks "Admission requests" "HTTPS/9443"
        prometheus -> kfController "Scrapes /metrics" "HTTPS/8443"
        olm -> trainerOperator "Manages operator subscription"
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
