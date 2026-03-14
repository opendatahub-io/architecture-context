workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates distributed training jobs for LLM fine-tuning and model training"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for distributed machine learning training and LLM fine-tuning" {
            controller = container "trainer-controller-manager" "Manages TrainJob lifecycle, creates JobSets, progression tracking" "Go Operator"
            webhook = container "Validating Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime CRs" "Go HTTPS Service"
            trainjobCtl = container "TrainJob Controller" "Reconciles TrainJobs, creates JobSets and PodGroups" "Go Reconciler"
            progressTracker = container "Progression Tracker (RHOAI)" "Polls training pod metrics for real-time progress" "Go Extension"
            netPolicyMgr = container "Network Policy Manager (RHOAI)" "Creates NetworkPolicies to isolate training pods" "Go Extension"
        }

        k8s = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        jobset = softwareSystem "JobSet Controller" "Creates sets of Jobs for distributed training" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang-scheduling plugin for all-or-nothing pod scheduling" "External Optional"
        coscheduling = softwareSystem "Coscheduling Plugin" "Kubernetes scheduler-plugins gang-scheduling" "External Optional"
        kueue = softwareSystem "Kueue" "Multi-cluster job queueing system" "Internal ODH Optional"
        servicemesh = softwareSystem "OpenShift Service Mesh" "Secure inter-pod communication with mTLS" "Internal ODH Optional"
        prometheus = softwareSystem "OpenShift Monitoring / Prometheus" "Cluster monitoring and metrics collection" "Internal ODH"
        s3 = softwareSystem "S3 Storage" "Model artifacts, datasets, and checkpoint storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained models and datasets" "External"

        # Relationships
        user -> trainer "Creates TrainJob, TrainingRuntime CRs via kubectl/SDK"
        trainer -> k8s "Watches CRDs, creates JobSets, PodGroups, NetworkPolicies" "HTTPS/6443 TLS1.3 ServiceAccount"
        trainer -> jobset "Creates JobSet resources for multi-node training" "via Kubernetes API"
        trainer -> volcano "Creates PodGroup for gang scheduling" "via Kubernetes API (optional)"
        trainer -> coscheduling "Creates PodGroup for gang scheduling" "via Kubernetes API (optional)"
        trainer -> kueue "Integrates via managedBy field for queue management" "CRD watch (optional)"
        trainer -> prometheus "Exposes controller metrics" "HTTPS/8080 TLS PodMonitor"

        jobset -> k8s "Creates Jobs and Pods from JobSet" "HTTPS/6443"
        volcano -> k8s "Watches PodGroups, schedules pods atomically" "HTTPS/6443"
        coscheduling -> k8s "Watches PodGroups, schedules pods atomically" "HTTPS/6443"

        progressTracker -> k8s "Lists training pods to get IPs" "HTTPS/6443 ServiceAccount"
        progressTracker -> s3 "Training pods poll metrics" "HTTP/28080 NetworkPolicy"

        k8s -> s3 "Training pods download models/datasets" "HTTPS/443 AWS IAM"
        k8s -> huggingface "Training pods download models/datasets" "HTTPS/443 HF Token"
        k8s -> s3 "Training pods upload checkpoints" "HTTPS/443 AWS IAM"

        servicemesh -> k8s "Optional: Provides mTLS for inter-pod communication" "mTLS sidecar injection"
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8080 TLS"
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
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal ODH Optional" {
                background #b8e986
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
