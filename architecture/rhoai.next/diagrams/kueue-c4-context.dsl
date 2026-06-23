workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits ML training/inference workloads"
        clusterAdmin = person "Cluster Admin" "Configures quotas, queues, and resource flavors"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system that manages workload admission based on quota, priority, and fair sharing" {
            controllerManager = container "kueue-controller-manager" "Core controller managing ClusterQueues, LocalQueues, Workloads, ResourceFlavors, AdmissionChecks, and job integrations" "Go Operator (controller-runtime)"
            scheduler = container "Scheduler" "Evaluates pending workloads against ClusterQueue quotas, priority, fair sharing, and preemption policies" "In-process component"
            webhookServer = container "Webhook Server" "Validates and mutates Kueue CRDs and 13+ supported job types (36 webhooks total)" "In-process, 9443/TCP HTTPS"
            visibilityAPI = container "Visibility API Server" "Exposes pending workload information via Kubernetes aggregated API" "In-process, feature-gated"

            controllerManager -> scheduler "Triggers scheduling cycles"
            controllerManager -> webhookServer "Serves admission requests"
            controllerManager -> visibilityAPI "Serves visibility queries"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        certManager = softwareSystem "cert-manager" "Optional external certificate management" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Optional node provisioning via ProvisioningRequest API" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages distributed training jobs (PyTorchJob, TFJob, XGBoostJob, PaddleJob)" "External"
        mpiOperator = softwareSystem "Kubeflow MPI Operator" "Manages MPIJob workloads" "External"
        kuberay = softwareSystem "KubeRay" "Manages RayJob and RayCluster workloads" "External"
        jobset = softwareSystem "JobSet Controller" "Manages JobSet workloads" "External"
        codeflare = softwareSystem "CodeFlare / AppWrapper" "Manages AppWrapper workloads" "External"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys Kueue" "Internal RHOAI"

        remoteK8s = softwareSystem "Remote Kubernetes Clusters" "Worker clusters for MultiKueue workload distribution" "External"

        # Relationships
        dataScientist -> kueue "Submits jobs via kubectl" "HTTPS/443"
        clusterAdmin -> kueue "Configures ClusterQueues, ResourceFlavors, quotas" "HTTPS/443"

        kueue -> kubernetes "CRUD on CRDs, Jobs, Pods, Secrets" "HTTPS/443, SA token"
        kueue -> remoteK8s "MultiKueue workload dispatch" "HTTPS/443, kubeconfig"
        kueue -> clusterAutoscaler "ProvisioningRequest for node scaling" "HTTPS/443"

        kubernetes -> kueue "Admission webhook calls" "HTTPS/9443"
        prometheus -> kueue "Scrapes /metrics" "HTTPS/8443"
        rhodsOperator -> kueue "Deploys via Kustomize overlay" "Kustomize"

        kueue -> kubeflowTraining "Watches/manages training jobs" "HTTPS/443"
        kueue -> mpiOperator "Watches/manages MPIJobs" "HTTPS/443"
        kueue -> kuberay "Watches/manages Ray workloads" "HTTPS/443"
        kueue -> jobset "Watches/manages JobSets" "HTTPS/443"
        kueue -> codeflare "Watches/manages AppWrappers" "HTTPS/443"
        certManager -> kueue "Provisions webhook TLS certs" "Kubernetes API"
    }

    views {
        systemContext kueue "SystemContext" {
            include *
            autoLayout
        }

        container kueue "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
