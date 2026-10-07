workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed training workloads on OpenShift AI"
        platformAdmin = person "Platform Admin" "Manages ClusterTrainingRuntimes and operator configuration"

        trainer = softwareSystem "Trainer Operator" "Kubernetes operator that orchestrates distributed ML training workloads via TrainJob → TrainingRuntime → JobSet pipeline" {
            controller = container "trainer-controller-manager" "Reconciles TrainJob, TrainingRuntime, ClusterTrainingRuntime, and OptimizationJob CRDs" "Go controller-runtime operator"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for Trainer CRDs" "Go HTTPS server, port 9443"
            statusServer = container "Status Server" "Receives runtime status updates from training pods via OIDC auth" "Go HTTPS server, port 10443, feature-gated"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with secure serving" "Go HTTPS server, port 8443"
            pluginFramework = container "Plugin Framework" "Composable runtime plugins: torch, mpi, deepspeed, jobset, coscheduling, volcano" "Go library"
            datasetInitializer = container "Dataset Initializer" "Downloads datasets from HuggingFace, S3, or other sources" "Python init container"
            modelInitializer = container "Model Initializer" "Downloads pre-trained models for fine-tuning" "Python init container"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API server for CRD reconciliation and resource management" "External"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet workloads for distributed training topology" "Internal Platform"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "CoScheduling PodGroup for gang scheduling" "Internal Platform"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Volcano PodGroup for gang scheduling" "Internal Platform"
        katib = softwareSystem "Katib" "Hyperparameter tuning suggestion algorithms" "Internal Platform"
        certController = softwareSystem "cert-controller" "Webhook certificate rotation and management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from openshift-monitoring namespace" "Internal Platform"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset registry" "External"
        s3Storage = softwareSystem "S3 / Object Storage" "Model artifact and dataset storage" "External"

        # Relationships
        dataScientist -> trainer "Creates TrainJob via kubectl / API" "HTTPS/6443"
        platformAdmin -> trainer "Manages ClusterTrainingRuntimes" "HTTPS/6443"

        controller -> k8sApi "Reconciles CRDs, creates JobSets, leader election" "HTTPS+WSS/6443"
        controller -> pluginFramework "Resolves runtime plugin chain"
        controller -> jobsetController "Creates and watches JobSet workloads" "Kubernetes API"
        controller -> schedulerPlugins "Creates CoScheduling PodGroups" "Kubernetes API"
        controller -> volcanoScheduler "Creates Volcano PodGroups" "Kubernetes API"
        controller -> katib "Hyperparameter suggestions for OptimizationJob" "Go library"

        k8sApi -> webhookServer "Admission reviews" "HTTPS/9443"
        certController -> controller "Rotates webhook serving certificates" "Go library"

        datasetInitializer -> huggingface "Downloads datasets" "HTTPS/443"
        datasetInitializer -> s3Storage "Downloads datasets" "HTTPS/443"
        modelInitializer -> huggingface "Downloads models" "HTTPS/443"
        modelInitializer -> s3Storage "Downloads models" "HTTPS/443"

        prometheus -> metricsServer "Scrapes metrics" "HTTPS/8443"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
