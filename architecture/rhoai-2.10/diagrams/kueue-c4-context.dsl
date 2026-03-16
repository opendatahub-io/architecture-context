workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits ML training and inference jobs to the cluster"
        admin = person "Cluster Administrator" "Configures resource quotas, queues, and admission policies"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing job admission and resource allocation based on quotas and priorities" {
            controller = container "Kueue Controller Manager" "Main controller reconciling workloads, queues, and managing job admission" "Go Operator" {
                queueManager = component "Queue Manager" "Manages workload queueing with FIFO/priority strategies" "Go Controller"
                scheduler = component "Scheduler" "Assigns workloads to resource flavors and performs admission decisions" "Go Controller"
                jobFramework = component "Job Framework" "Pluggable framework supporting multiple job types" "Go Integration Layer"
            }
            webhook = container "Webhook Server" "Mutating and validating admission webhooks for jobs and Kueue CRDs" "Go Webhook Server"
            visibilityServer = container "Visibility Server" "Optional aggregated API server for visibility API (v1alpha1)" "Go APIServer Extension"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Optional"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Distributed ML training jobs (TFJob, PyTorchJob, MPIJob)" "Internal ODH"
        rayOperator = softwareSystem "Ray Operator" "Ray job and cluster management" "Internal ODH"
        jobSetController = softwareSystem "JobSet Controller" "JobSet workload management" "External Optional"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Automatic node provisioning based on resource demands" "External Optional"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and artifact storage" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components and workloads" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration and pipeline execution" "Internal ODH"

        // User interactions
        user -> kueue "Creates and submits jobs via kubectl/API" "HTTPS/6443"
        user -> k8s "Submits Jobs, creates Workloads" "HTTPS/6443"
        admin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors" "kubectl/HTTPS"

        // Kueue core interactions
        kueue -> k8s "Watches and manages Jobs, Pods, and CRDs via API Server" "HTTPS/6443"
        k8s -> webhook "Calls mutating/validating webhooks for job admission" "HTTPS/9443"
        controller -> scheduler "Delegates admission decisions"
        controller -> queueManager "Manages workload queue state"
        webhook -> controller "Creates Workload CRs for submitted jobs"

        // External dependencies
        kueue -> certManager "Requests TLS certificates for webhook server" "Kubernetes API"
        kueue -> prometheus "Exposes queue and admission metrics" "HTTP/8080, HTTPS/8443"
        prometheus -> kueue "Scrapes metrics via ServiceMonitor" "HTTP/HTTPS"

        // Internal ODH integrations
        kueue -> kubeflowTraining "Intercepts training job creation for queueing" "Webhook/9443"
        kueue -> rayOperator "Intercepts Ray job/cluster creation for queueing" "Webhook/9443"
        kueue -> jobSetController "Intercepts JobSet creation for queueing" "Webhook/9443"
        dashboard -> kueue "Displays queue status and workload information" "Kubernetes API"
        pipelines -> kueue "Submits jobs with queue annotations for automated workflows" "Kubernetes API"

        // Autoscaler integration
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for guaranteed resources" "HTTPS/6443 (autoscaling.x-k8s.io)"
        clusterAutoscaler -> k8s "Provisions nodes based on ProvisioningRequests" "Kubernetes API"

        // Model Registry integration (indirect)
        user -> modelRegistry "Stores trained models" "gRPC/HTTP"
        pipelines -> modelRegistry "Registers model metadata from pipeline outputs" "gRPC/HTTP"
    }

    views {
        systemContext kueue "KueueSystemContext" {
            include *
            autoLayout
        }

        container kueue "KueueContainers" {
            include *
            autoLayout
        }

        component controller "KueueControllerComponents" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5da5da
                color #ffffff
            }
            element "Component" {
                background #60b5cc
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape Person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
