workspace {
    model {
        user = person "Data Scientist" "Trains large language models and ML models using distributed computing"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for distributed training of LLMs and ML workloads across PyTorch, JAX, TensorFlow, and other frameworks" {
            controllerManager = container "trainer-controller-manager" "Manages TrainJob lifecycle and creates JobSet resources" "Go Operator" {
                trainjobController = component "TrainJob Controller" "Reconciles TrainJob CRs and creates JobSets" "Controller"
                runtimeController = component "TrainingRuntime Controller" "Manages TrainingRuntime resources" "Controller"
                clusterRuntimeController = component "ClusterTrainingRuntime Controller" "Manages ClusterTrainingRuntime resources" "Controller"
                progressionWatcher = component "Progression Watcher" "Tracks distributed training job progression" "RHOAI Plugin"
            }
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources" "Go Webhook Service"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        jobset = softwareSystem "JobSet" "Manages sets of Jobs for distributed training workloads" "External"
        volcano = softwareSystem "Volcano" "Gang scheduling for distributed training" "External (Optional)"
        certManager = softwareSystem "cert-manager" "Certificate provisioning for webhook TLS" "External (Optional)"

        dashboard = softwareSystem "RHOAI Dashboard" "Web interface for creating and managing TrainJobs" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores trained model metadata and artifacts" "Internal RHOAI"

        s3 = softwareSystem "S3 Storage" "Object storage for datasets and model checkpoints" "External"
        registry = softwareSystem "Container Registry" "Stores training runtime container images" "External"

        # User interactions
        user -> trainer "Creates and manages TrainJobs via kubectl/API"
        user -> dashboard "Creates TrainJobs through UI"

        # Dashboard interactions
        dashboard -> k8s "Creates TrainJob CRs via Kubernetes API" "HTTPS/6443"
        dashboard -> trainer "Manages TrainJobs"

        # Trainer core interactions
        trainer -> k8s "Watches CRDs, creates JobSets, manages resources" "HTTPS/6443"
        k8s -> webhookServer "Validates TrainJob resources" "HTTPS/9443 mTLS"

        # External dependencies
        trainer -> jobset "Creates JobSet resources for distributed training" "CRD API"
        jobset -> k8s "Creates Jobs and Pods" "Kubernetes API"
        trainer -> volcano "Creates PodGroups for gang scheduling (optional)" "CRD API"
        trainer -> certManager "Provisions webhook TLS certificates (optional)" "cert-manager API"

        # Training workload interactions
        jobset -> s3 "Downloads training datasets" "HTTPS/443"
        jobset -> s3 "Uploads model checkpoints" "HTTPS/443"
        jobset -> registry "Pulls training runtime images" "HTTPS/443"
        jobset -> modelRegistry "Stores trained model metadata (optional)" "API"

        # Monitoring
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8443"
    }

    views {
        systemContext trainer "SystemContext" {
            include *
            autoLayout lr
        }

        container trainer "Containers" {
            include *
            autoLayout lr
        }

        component controllerManager "ControllerComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (Optional)" {
                background #cccccc
                color #333333
                shape Component
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5a9fd4
                color #ffffff
            }
            element "Component" {
                background #6aaee4
                color #ffffff
            }
        }

        theme default
    }
}
