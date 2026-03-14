workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages distributed ML training jobs and LLM fine-tuning workloads"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for distributed machine learning training and LLM fine-tuning across PyTorch, JAX, TensorFlow, DeepSpeed, and MLX frameworks" {
            controller = container "trainer-controller-manager" "Manages TrainJob lifecycle and creates training workloads" "Go Operator" {
                trainjobController = component "TrainJob Controller" "Reconciles TrainJob resources and creates JobSets" "Go Reconciler"
                runtimeController = component "TrainingRuntime Controller" "Watches runtime templates and notifies TrainJobs" "Go Reconciler"
                clusterRuntimeController = component "ClusterTrainingRuntime Controller" "Watches cluster-scoped runtime templates" "Go Reconciler"
                progressionTracker = component "Progression Tracker (RHOAI)" "Polls training pod metrics for real-time progress updates" "RHOAI Extension"
                networkPolicyManager = component "Network Policy Manager (RHOAI)" "Creates NetworkPolicies to isolate training pods" "RHOAI Extension"
            }

            webhook = container "Validating Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime on CREATE/UPDATE" "Go Admission Controller"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        jobset = softwareSystem "JobSet" "Creates sets of Jobs for distributed training" "External" {
            jobsetController = container "JobSet Controller" "Manages multi-node training job patterns" "K8s Operator v0.10.1"
        }
        volcano = softwareSystem "Volcano Scheduler" "Gang-scheduling plugin for all-or-nothing pod scheduling" "External Optional"
        coscheduling = softwareSystem "Coscheduling Plugin" "Kubernetes scheduler-plugins gang-scheduling" "External Optional"
        leaderworkerset = softwareSystem "LeaderWorkerSet" "Manages leader-worker pod topologies" "External Optional"

        kueue = softwareSystem "Kueue" "Queue-based job management system" "Internal ODH"
        servicemesh = softwareSystem "OpenShift Service Mesh" "Secure inter-pod communication with mTLS" "Internal ODH"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based cluster monitoring" "Internal ODH"

        s3 = softwareSystem "S3 Storage" "Model artifact and dataset storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained model and dataset repository" "External"
        gcs = softwareSystem "Google Cloud Storage" "Cloud storage alternative for models/datasets" "External"

        # User interactions
        datascientist -> trainer "Creates TrainJobs for distributed training via kubectl/SDK"

        # Trainer → External dependencies
        trainer -> kubernetes "Watches CRDs, creates JobSets and PodGroups" "gRPC/HTTPS 6443"
        trainer -> jobset "Creates JobSets for multi-node training" "K8s API"
        trainer -> volcano "Creates PodGroups for gang scheduling" "K8s API (optional)"
        trainer -> coscheduling "Uses coscheduling for gang scheduling" "K8s API (optional)"
        trainer -> leaderworkerset "Uses for leader-worker topologies" "K8s API (optional)"

        # Trainer → Internal ODH dependencies
        trainer -> kueue "Integrates via managedBy field for job queueing" "CRD watch"
        trainer -> servicemesh "Training pods may use mesh for secure communication" "Optional"
        trainer -> monitoring "Exposes controller metrics via PodMonitor" "HTTPS 8080"

        # Training pods → External services
        jobsetController -> s3 "Downloads model artifacts and datasets" "HTTPS/443 (AWS IAM)"
        jobsetController -> huggingface "Downloads pre-trained models" "HTTPS/443 (HF token)"
        jobsetController -> gcs "Downloads from GCS" "HTTPS/443 (GCP SA)"

        # Trainer internal components
        trainjobController -> kubernetes "Creates JobSets, PodGroups, NetworkPolicies" "ServiceAccount token"
        progressionTracker -> kubernetes "Lists training pods" "ServiceAccount token"
        progressionTracker -> jobsetController "Polls /metrics endpoint for training progress" "HTTP/28080"
        webhook -> kubernetes "Validates TrainJob resources" "mTLS"
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

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "RHOAI Extension" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
