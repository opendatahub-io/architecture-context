workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs and LLM fine-tuning workloads"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for distributed ML training and LLM fine-tuning" {
            controller = container "Trainer Controller Manager" "Manages TrainJob, TrainingRuntime, ClusterTrainingRuntime lifecycle" "Go Operator" {
                trainJobController = component "TrainJob Controller" "Creates JobSets, manages training lifecycle, updates status" "Go Reconciler"
                runtimeController = component "TrainingRuntime Controller" "Watches runtime templates and notifies TrainJobs" "Go Reconciler"
                webhook = component "Validating Webhook" "Validates TrainJob and runtime resources on CREATE/UPDATE" "Admission Controller"
                progressTracker = component "Progression Tracker" "Polls training metrics from pods for real-time progress" "RHOAI Extension"
                netPolManager = component "Network Policy Manager" "Creates NetworkPolicies to isolate training pods" "RHOAI Extension"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "Infrastructure"
        jobset = softwareSystem "JobSet Controller" "Creates sets of Jobs for distributed training" "External Dependency"
        volcano = softwareSystem "Volcano Scheduler" "Gang-scheduling plugin for all-or-nothing pod scheduling" "External Dependency"
        kueue = softwareSystem "Kueue" "Multi-cluster job queueing system" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        s3 = softwareSystem "S3 Storage" "Dataset and model artifact storage" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained models and datasets repository" "External Service"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Secure inter-pod communication" "Internal ODH"

        # User interactions
        user -> trainer "Creates TrainJob for distributed training via kubectl/SDK"
        user -> trainer "Defines TrainingRuntime templates for reusable configurations"

        # Trainer core interactions
        trainer -> k8sAPI "Watches CRDs, creates JobSets, manages resources" "HTTPS/6443 TLS 1.3"
        trainer -> jobset "Creates JobSets for multi-node training workloads" "HTTPS/6443 TLS 1.3"
        trainer -> volcano "Uses for gang-scheduling (all-or-nothing pod scheduling)" "HTTPS/6443 TLS 1.3"
        trainer -> prometheus "Exposes controller metrics via PodMonitor" "HTTPS/8080 TLS"

        # RHOAI extensions
        progressTracker -> k8sAPI "Lists pods in JobSet" "HTTPS/6443 TLS 1.3"
        progressTracker -> trainer "Polls training pod metrics for real-time progress" "HTTP/28080"
        netPolManager -> k8sAPI "Creates NetworkPolicies for pod isolation" "HTTPS/6443 TLS 1.3"

        # Training pod interactions
        trainer -> s3 "Training pods download datasets and models" "HTTPS/443 TLS 1.2+"
        trainer -> huggingface "Training pods download pre-trained models" "HTTPS/443 TLS 1.2+"
        trainer -> serviceMesh "Training pods may use mesh for secure communication" "mTLS"

        # Optional integrations
        trainer -> kueue "Integrates for queue-based job management (optional)" "HTTPS/6443 TLS 1.3"
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

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "RHOAI Extension" {
                background #50e3c2
                color #000000
            }
        }
    }
}
