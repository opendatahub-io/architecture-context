workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via TrainJob CRDs"
        platformAdmin = person "Platform Admin" "Deploys and configures Kubeflow Trainer via rhods-operator"

        trainer = softwareSystem "Kubeflow Trainer v2" "Kubernetes operator managing distributed ML training via TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs" {
            controller = container "trainer-controller-manager" "Reconciles TrainJob/TrainingRuntime/ClusterTrainingRuntime CRDs; creates JobSets; manages NetworkPolicies; tracks training progression (RHAI)" "Go Operator (controller-runtime)" "Component"
            webhook = container "Validating Webhooks" "Validates TrainJob, TrainingRuntime, and ClusterTrainingRuntime resources at admission time" "Go HTTP Server, 9443/TCP" "Component"
            certController = container "cert-controller" "Manages self-signed TLS certificates for webhook server" "open-policy-agent/cert-controller" "Component"
            clusterRuntimes = container "ClusterTrainingRuntimes" "15 pre-configured training runtimes for CUDA/ROCm/CPU with pinned images" "Kubernetes CRs" "Component"
            imageStreams = container "ImageStreams" "Training Hub universal workbench images for CPU, CUDA 13.0, ROCm 6.4" "OpenShift ImageStreams" "Component"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes API Server" "443/TCP HTTPS"
        }

        jobset = softwareSystem "JobSet Controller" "Manages JobSet resources for multi-pod job orchestration (jobset.x-k8s.io)" "External"
        coscheduling = softwareSystem "Coscheduling Scheduler Plugin" "Gang-scheduling via PodGroups (scheduling.x-k8s.io, optional)" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang-scheduling via PodGroups (scheduling.volcano.sh, optional)" "External"
        kueue = softwareSystem "Kueue / MultiKueue" "Job queueing and multi-cluster dispatch (optional)" "External"

        openshift = softwareSystem "OpenShift Platform" "OpenShift container platform with cluster TLS security profiles" "External" {
            ocpAPI = container "OpenShift APIServer" "Provides cluster TLS security profile (config.openshift.io)" "443/TCP HTTPS"
        }

        prometheus = softwareSystem "Prometheus / OCP Monitoring" "Metrics collection via PodMonitor" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys Kubeflow Trainer via kustomize manifests" "Internal RHOAI"

        trainingPods = softwareSystem "Training Pods" "Distributed ML training workloads (PyTorch/MPI/TorchTune/DeepSpeed) managed by JobSet" "Workload"

        # Relationships - User
        user -> trainer "Creates TrainJob CR via kubectl/UI" "HTTPS/443"
        platformAdmin -> rhodsOperator "Configures RHOAI platform"

        # Relationships - Trainer internals
        controller -> webhook "Registers webhooks"
        certController -> webhook "Provisions TLS certificates"

        # Relationships - Trainer → External
        trainer -> kubernetes "CRUD on TrainJob, JobSet, PodGroup, NetworkPolicy, Secret, ConfigMap" "HTTPS/443 TLS, ServiceAccount token"
        trainer -> jobset "Creates/manages JobSet resources for each TrainJob" "HTTPS/443 TLS"
        trainer -> coscheduling "Creates PodGroups for gang-scheduling" "HTTPS/443 TLS"
        trainer -> volcano "Creates PodGroups for Volcano gang-scheduling" "HTTPS/443 TLS"
        trainer -> openshift "Reads cluster TLS security profile" "HTTPS/443 TLS"
        trainer -> trainingPods "Polls training progress metrics (RHAI)" "HTTP/28080 plaintext"

        # Relationships - External → Trainer
        kubernetes -> webhook "Sends admission reviews" "HTTPS/9443 TLS"
        prometheus -> trainer "Scrapes controller metrics via PodMonitor" "HTTPS/8443 TLS"
        rhodsOperator -> trainer "Deploys via kustomize manifests"

        # Relationships - Workload
        trainingPods -> trainingPods "NCCL/MPI/gRPC peer communication" "TCP/29500 plaintext (NetworkPolicy restricted)"

        # Relationships - Optional
        kueue -> trainer "Delegates TrainJob management via managedBy field"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Workload" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
