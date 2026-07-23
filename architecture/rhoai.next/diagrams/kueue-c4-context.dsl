workspace {
    model {
        user = person "Data Scientist" "Creates and submits ML/batch workloads with queue annotations"

        clusterAdmin = person "Cluster Administrator" "Configures ClusterQueues, ResourceFlavors, quotas, and fair sharing policies"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing admission control, quota allocation, and fair sharing for batch workloads" {
            controllerManager = container "Kueue Controller Manager" "Manages workload lifecycle, quota tracking, job suspension/unsuspension across 14 job framework integrations" "Go Operator (controller-runtime)"
            scheduler = container "Scheduler" "Evaluates pending workloads against ClusterQueue quotas, makes admission decisions with fair sharing and preemption" "In-process Go component"
            webhookServer = container "Webhook Server" "Validates and mutates Kueue CRDs and managed job resources (42 webhooks: 20 mutating, 21 validating, 1 conversion)" "In-process HTTPS server (9443/TCP)"
            inMemoryCache = container "In-Memory Cache" "Holds ClusterQueue state, workload assignments, quota usage for fast scheduling decisions" "Go data structures"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD, watches, admission webhooks" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting via ServiceMonitor" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys and configures Kueue as a managed RHOAI component" "Internal RHOAI"

        batchJob = softwareSystem "batch/Job Controller" "Kubernetes native job controller" "External"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob" "External"
        kuberay = softwareSystem "KubeRay Operator" "Manages RayJob and RayCluster resources" "External"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet resources for multi-job workloads" "External"
        codeflare = softwareSystem "CodeFlare AppWrapper Controller" "Manages AppWrapper resources" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "External certificate management (optional alternative to internal certs)" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Auto-provisions nodes via ProvisioningRequest CRD" "External"

        # Relationships
        user -> kueue "Submits Jobs/PyTorchJobs/RayJobs with queue-name label" "kubectl / HTTPS"
        clusterAdmin -> kueue "Configures ClusterQueues, ResourceFlavors, Cohorts" "kubectl / HTTPS"

        kueue -> k8sAPI "Watches CRDs, patches Jobs, creates Workloads" "HTTPS/443, SA Token"
        k8sAPI -> kueue "Sends admission reviews to webhook" "HTTPS/9443, API server cert"

        prometheus -> kueue "Scrapes metrics" "HTTPS/8443, Bearer Token"
        rhodsOperator -> kueue "Deploys and configures via kustomize" "Deployment management"

        kueue -> batchJob "Suspends/unsuspends batch Jobs" "HTTPS/443 via K8s API"
        kueue -> kubeflowTraining "Manages training job suspension and workload lifecycle" "HTTPS/443 via K8s API"
        kueue -> kuberay "Manages Ray workload suspension and admission" "HTTPS/443 via K8s API"
        kueue -> jobsetController "Manages JobSet suspension and workload creation" "HTTPS/443 via K8s API"
        kueue -> codeflare "Manages AppWrapper suspension and workload lifecycle" "HTTPS/443 via K8s API"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for node provisioning" "HTTPS/443 via K8s API"
        kueue -> certManager "Obtains TLS certificates (optional)" "HTTPS/443 via K8s API"

        # Internal container relationships
        controllerManager -> scheduler "Notifies of pending workloads via Go channels"
        scheduler -> inMemoryCache "Reads quota state, writes admission decisions"
        controllerManager -> inMemoryCache "Updates workload and queue state"
        controllerManager -> k8sAPI "CRUD operations on CRDs, Jobs, Pods" "HTTPS/443"
        k8sAPI -> webhookServer "Admission reviews" "HTTPS/9443"
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
                background #4a90e2
                color #ffffff
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
