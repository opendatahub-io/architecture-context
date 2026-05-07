workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRs"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for orchestrating distributed ML training jobs across PyTorch, JAX, TensorFlow, and MPI" {
            controller = container "trainer-controller-manager" "Manages TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; creates JobSet, NetworkPolicy, and PodGroup resources" "Go Operator (controller-runtime)"
            webhook = container "Webhook Server" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources on create/update" "Go Service, 9443/TCP HTTPS"
            progressionTracker = container "RHAI Progression Tracker" "Polls training pod HTTP metrics for real-time training progress; updates TrainJob annotations" "Controller Extension (RHOAI)"
            runtimes = container "ClusterTrainingRuntimes" "Pre-configured training templates for PyTorch CUDA/ROCm/CPU with curated container images" "Cluster-scoped CRs (RHOAI)"
        }

        jobset = softwareSystem "JobSet" "Manages replicated batch Jobs for distributed training workloads (sigs.k8s.io/jobset v0.10.1)" "External"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "PodGroup-based gang-scheduling via coscheduling plugin (v0.34.1)" "External Optional"
        volcano = softwareSystem "Volcano" "Alternative PodGroup-based gang-scheduling (v1.13.1)" "External Optional"
        kueue = softwareSystem "Kueue" "Multi-cluster job scheduling via managedBy field" "External Optional"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        certController = softwareSystem "cert-controller" "Generates and rotates TLS certificates for webhook server (open-policy-agent/cert-controller)" "External"

        rhodsOperator = softwareSystem "rhods-operator" "Deploys Kubeflow Trainer via kustomize manifests; manages namespace and image references" "Internal RHOAI"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring; scrapes controller metrics via PodMonitor" "Internal RHOAI"

        trainingPods = softwareSystem "Training Pods" "Distributed ML training workloads (master + workers) running PyTorch/JAX/TF/MPI" "Runtime Workload"

        user -> trainer "Creates TrainJob CRs via kubectl/API" "HTTPS/443"
        trainer -> k8sAPI "CRD CRUD, JobSet management, Pod listing, NetworkPolicy management" "HTTPS/443, SA Token"
        trainer -> jobset "Creates and monitors JobSet CRs for each TrainJob" "HTTPS/443"
        trainer -> schedulerPlugins "Creates PodGroup resources for gang-scheduling" "HTTPS/443"
        trainer -> volcano "Creates Volcano PodGroup resources for gang-scheduling" "HTTPS/443"
        trainer -> kueue "Delegates reconciliation via managedBy field" "N/A"
        trainer -> trainingPods "Polls /metrics endpoint for RHAI progression tracking" "HTTP/28080, plaintext"
        certController -> trainer "Generates and rotates webhook TLS certificates" "Secret mount"
        rhodsOperator -> trainer "Deploys via kustomize manifests" "Kustomize"
        monitoring -> trainer "Scrapes controller metrics via PodMonitor" "HTTPS/8443"
        jobset -> trainingPods "Creates batch Jobs and Pods for training workloads" "K8s API"
        k8sAPI -> trainer "Sends webhook validation requests" "HTTPS/9443, client cert"
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
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Runtime Workload" {
                background #f5a623
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
