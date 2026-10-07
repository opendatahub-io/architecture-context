workspace {
    model {
        platformAdmin = person "Platform Administrator" "Configures ClusterQueues, ResourceFlavors, and quota policies"
        dataScientist = person "Data Scientist" "Submits ML training jobs and batch workloads via LocalQueues"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing workload admission based on quotas, priorities, and fair sharing" {
            controllerManager = container "Controller Manager" "Runs scheduler, webhook server, and all reconciliation loops" "Go Deployment"
            scheduler = container "Scheduler" "Evaluates pending Workloads against ClusterQueue quotas and admits workloads" "Go Component"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for all supported workload types" "Go Server (9443/TCP)"
            jobFramework = container "Job Framework" "Pluggable integration layer for batch/ML workload types" "Go Framework"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management and admission control" "External"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages distributed ML training jobs (PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob)" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Manages Ray clusters and jobs" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare AppWrapper Controller" "Manages AppWrapper batch workloads" "Internal RHOAI"
        jobsetController = softwareSystem "JobSet Controller" "Manages coordinated groups of Jobs" "Internal RHOAI"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Dynamically provisions cluster capacity via ProvisioningRequests" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        platformAdmin -> kueue "Configures ClusterQueues, ResourceFlavors, Cohorts via kubectl"
        dataScientist -> kueue "Submits workloads to LocalQueues via kubectl"

        kueue -> k8sAPI "Watches and manages CRDs, pods, events" "HTTPS/6443 TLS 1.2+"
        kueue -> kubeflowTraining "Intercepts and manages training jobs via webhooks" "HTTPS/9443 TLS"
        kueue -> kuberay "Intercepts and manages Ray workloads via webhooks" "HTTPS/9443 TLS"
        kueue -> codeflare "Intercepts and manages AppWrappers via webhooks" "HTTPS/9443 TLS"
        kueue -> jobsetController "Intercepts and manages JobSets via webhooks" "HTTPS/9443 TLS"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for dynamic capacity" "HTTPS/6443"

        prometheus -> kueue "Scrapes metrics" "HTTPS/8443 TLS Bearer"

        k8sAPI -> kueue "Sends admission webhook requests" "HTTPS/443→9443 TLS"
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
                background #5ba3f5
                color #ffffff
            }
        }
    }
}
