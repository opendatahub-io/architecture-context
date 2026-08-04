workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs"

        trainer = softwareSystem "Kubeflow Trainer (RHOAI)" "Kubernetes operator that orchestrates distributed ML training via TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs" {
            controllerManager = container "Trainer Controller Manager" "Reconciles TrainJob CRDs, selects scheduling plugins, manages workload lifecycle" "Go controller-runtime operator"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime on CREATE/UPDATE" "Validating Admission Webhook, port 9443/TLS"
            networkPolicyMgr = container "NetworkPolicy Manager" "Creates per-TrainJob NetworkPolicy for workload isolation (RHOAI extension)" "Go package pkg/rhai/networkpolicy"
            progressionTracker = container "Progression Tracker" "Polls primary training pod HTTP endpoint for training metrics (RHOAI extension)" "Go package pkg/rhai/progression"
            datasetInitializer = container "Dataset Initializer" "Prepares training data as init container" "Python"
            modelInitializer = container "Model Initializer" "Prepares model artifacts as init container" "Python"

            controllerManager -> webhookServer "Serves admission requests"
            controllerManager -> networkPolicyMgr "Creates per-TrainJob NetworkPolicies"
            controllerManager -> progressionTracker "Tracks training progress"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD, watches, admission" "External"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS security profile configuration" "External"
        jobset = softwareSystem "JobSet Controller" "Manages replicated distributed training jobs via JobSet CRDs" "Internal Platform"
        coscheduling = softwareSystem "Kubernetes Scheduler Plugins (CoScheduling)" "Gang scheduling via scheduler-plugins PodGroups" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via Volcano PodGroups" "Internal Platform"
        certController = softwareSystem "cert-controller" "Provisions and rotates TLS certificates for webhook server" "External"

        user -> trainer "Creates TrainJob referencing TrainingRuntime" "kubectl / Kubernetes API"
        trainer -> kubeAPI "CRUD on CRDs, JobSets, PodGroups, NetworkPolicies, ConfigMaps, Secrets" "HTTPS/6443, SA token"
        trainer -> openshiftAPI "Reads TLS security profile at startup" "HTTPS, SA token"
        trainer -> jobset "Creates and watches JobSet resources for distributed training" "Kubernetes API"
        trainer -> coscheduling "Creates and watches PodGroup resources for gang scheduling" "Kubernetes API"
        trainer -> volcano "Creates and watches PodGroup resources for gang scheduling" "Kubernetes API"
        certController -> trainer "Provisions webhook TLS certificate" "kubeflow-trainer-webhook-cert"

        trainingPod = softwareSystem "Training Pod" "Executes ML training workloads in user namespace" "Training Workload"
        trainer -> trainingPod "Polls HTTP metrics endpoint for progression tracking" "HTTP (plain, in-cluster)"
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
            element "Training Workload" {
                background #f5a623
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
