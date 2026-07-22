workspace {
    model {
        dataScientist = person "Data Scientist" "Submits distributed training jobs via TrainJob CRs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        trainerOperator = softwareSystem "Trainer Operator" "Manages lifecycle of Kubeflow Trainer V2 on RHOAI clusters" {
            controller = container "trainer-operator" "Watches Trainer CR, renders kustomize manifests, deploys operand" "Go Operator (controller-runtime)"
            depChecker = container "Dependency Checker" "Verifies JobSet Operator is installed and healthy" "Go Module"
            manifestRenderer = container "Manifest Renderer" "Copies templates, applies RELATED_IMAGE_* overrides, renders via kustomize" "odh-platform-utilities"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer V2" "Upstream controller that reconciles TrainJobs into distributed training workloads" {
            trainerController = container "kubeflow-trainer-controller-manager" "Watches TrainJob CRs, creates JobSets for distributed training" "Go Controller"
            validatingWebhook = container "Validating Webhook" "Validates TrainJob, ClusterTrainingRuntime, TrainingRuntime on admission" "HTTPS/9443"
        }

        rhoaiPlatform = softwareSystem "RHOAI Platform Operator" "Creates Trainer CR to trigger component deployment; injects image refs" "Internal RHOAI"
        jobsetOperator = softwareSystem "JobSet Operator" "Provides JobSet CRD for orchestrating multi-replica distributed jobs" "OpenShift"
        k8sApi = softwareSystem "Kubernetes/OpenShift API" "Central API for cluster resource management" "Infrastructure"
        prometheus = softwareSystem "OpenShift Monitoring" "Metrics collection and alerting" "Infrastructure"
        olmSystem = softwareSystem "OLM" "Operator Lifecycle Manager for operator installation" "Infrastructure"

        # Platform Admin flows
        platformAdmin -> rhoaiPlatform "Manages RHOAI platform"
        rhoaiPlatform -> trainerOperator "Creates Trainer CR (default-trainer)" "CRD Watch"
        rhoaiPlatform -> trainerOperator "Injects RELATED_IMAGE_* env vars" "Environment"

        # Operator internal flows
        controller -> depChecker "Checks dependencies before deploying"
        controller -> manifestRenderer "Renders kustomize manifests"
        depChecker -> jobsetOperator "Verifies installed and healthy" "K8s API"
        depChecker -> olmSystem "Checks OperatorConditions" "K8s API"

        # Operator → Operand deployment
        trainerOperator -> kubeflowTrainer "Deploys and monitors" "kustomize + Server-Side Apply"
        trainerOperator -> k8sApi "CRUD on CRDs, Deployments, RBAC, Services, ConfigMaps" "HTTPS/443"

        # User flows
        dataScientist -> k8sApi "Creates TrainJob CR" "kubectl / HTTPS"
        k8sApi -> validatingWebhook "Validates admission" "HTTPS/443→9443"
        trainerController -> k8sApi "Creates JobSets from TrainJobs" "HTTPS/443"
        jobsetOperator -> k8sApi "Creates Jobs/Pods for distributed training" "HTTPS/443"

        # Monitoring
        prometheus -> trainerOperator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> kubeflowTrainer "Scrapes controller metrics" "HTTPS/8443 (insecureSkipVerify)"
    }

    views {
        systemContext trainerOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainerOperator "TrainerOperatorContainers" {
            include *
            autoLayout
        }

        container kubeflowTrainer "KubeflowTrainerContainers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
