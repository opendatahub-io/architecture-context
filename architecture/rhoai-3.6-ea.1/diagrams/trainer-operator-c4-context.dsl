workspace {
    model {
        platformOperator = person "Platform Operator" "Manages RHOAI platform components via odh-operator/rhods-operator"
        dataScientist = person "Data Scientist" "Creates and manages distributed training jobs"

        trainerOperator = softwareSystem "trainer-operator" "Kubernetes operator managing the Kubeflow Trainer v2 lifecycle on RHOAI" {
            controllerManager = container "Controller Manager" "Reconciles Trainer CR, manages training runtimes and resources" "Go controller-runtime Operator"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics on port 8080" "HTTP (plaintext)"
            healthEndpoint = container "Health Endpoint" "Kubernetes health/readiness probes on port 8081" "HTTP"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        jobSetOperator = softwareSystem "JobSetOperator" "Manages JobSet resources on OpenShift" "External (OpenShift)"
        jobSetCRD = softwareSystem "JobSet CRD" "Defines JobSet custom resources" "External (Kubernetes)"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring stack" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, deployment helpers" "Internal Platform"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2" "Distributed training framework (TrainJobs, TrainingRuntimes)" "Managed by trainer-operator"

        platformOperator -> trainerOperator "Creates/updates Trainer CR (default-trainer)" "Kubernetes API/HTTPS"
        dataScientist -> kubeflowTrainer "Creates TrainJobs for distributed training" "kubectl/HTTPS"

        trainerOperator -> kubernetesAPI "CRUD operations on cluster resources" "HTTPS/6443 TLS 1.2+"
        trainerOperator -> jobSetOperator "Checks dependency status (OpenShift)" "Kubernetes API/HTTPS"
        trainerOperator -> jobSetCRD "Checks CRD existence (Kubernetes)" "Kubernetes API/HTTPS"
        trainerOperator -> prometheusOperator "Creates PodMonitor resources" "Kubernetes API/HTTPS"
        trainerOperator -> kubeflowTrainer "Deploys and manages training runtimes" "Kubernetes API/HTTPS"
        trainerOperator -> olm "Lists OperatorConditions" "Kubernetes API/HTTPS"

        prometheus -> trainerOperator "Scrapes metrics" "HTTP/8080 (plaintext, no auth)"

        controllerManager -> metricsEndpoint "Exposes metrics"
        controllerManager -> healthEndpoint "Serves health probes"
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
            element "External (OpenShift)" {
                background #cc0000
                color #ffffff
            }
            element "External (Kubernetes)" {
                background #326ce5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Managed by trainer-operator" {
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
