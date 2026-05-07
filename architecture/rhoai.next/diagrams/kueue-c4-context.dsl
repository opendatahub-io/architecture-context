workspace {
    model {
        user = person "Data Scientist" "Creates and submits ML training jobs and batch workloads"
        clusterAdmin = person "Cluster Admin" "Configures ClusterQueues, ResourceFlavors, quotas"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing admission, scheduling, preemption, and fair sharing" {
            controllerManager = container "Kueue Controller Manager" "controller-runtime based operator managing job queueing, admission, scheduling, preemption, and workload lifecycle" "Go Operator"
            webhookServer = container "Webhook Server" "Validates and mutates job and Kueue resource specs" "Go (port 9443/TCP HTTPS)"
            scheduler = container "Scheduler" "Continuous scheduling loop evaluating pending workloads against quotas, priorities, flavors, and fair sharing" "Go (in-process)"
            jobFramework = container "Job Framework" "Plugin architecture integrating batch/v1, JobSet, Kubeflow, Ray, AppWrapper, Pod, Deployment, StatefulSet job types" "Go"
            multiKueueCtrl = container "MultiKueue Controller" "Federates workloads to remote clusters via kubeconfig" "Go (optional)"
            provisioningCtrl = container "Provisioning Controller" "Creates ProvisioningRequests for cluster autoscaler node provisioning" "Go (optional)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for all CRD CRUD, job management, and webhook registration" "External"
        trainingOperator = softwareSystem "Training Operator (Kubeflow)" "Manages PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob CRDs" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator (KubeRay)" "Manages RayJob and RayCluster CRDs" "Internal RHOAI"
        jobSetController = softwareSystem "JobSet Controller" "Manages JobSet CRDs for multi-job coordination" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare (AppWrapper)" "Manages AppWrapper batch workloads" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator deploying Kueue via kustomize manifests" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        certManager = softwareSystem "cert-manager" "External certificate management (optional alternative)" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Processes ProvisioningRequests to provision nodes" "External"
        remoteCluster = softwareSystem "Remote Kubernetes Cluster" "Worker cluster for MultiKueue federation" "External"

        # User relationships
        user -> kueue "Submits jobs to LocalQueues via kubectl/API"
        clusterAdmin -> kueue "Configures ClusterQueues, ResourceFlavors, quotas"

        # Kueue internal relationships
        controllerManager -> webhookServer "Hosts webhook endpoints"
        controllerManager -> scheduler "Runs scheduler loop"
        controllerManager -> jobFramework "Manages job integrations"
        controllerManager -> multiKueueCtrl "Federates workloads (optional)"
        controllerManager -> provisioningCtrl "Requests node provisioning (optional)"

        # External integrations
        kueue -> k8sAPI "CRD CRUD, job lifecycle, webhook registration" "HTTPS/6443 TLS 1.2+ SA token"
        kueue -> trainingOperator "Watches/manages Kubeflow training job CRDs" "CRD Watch"
        kueue -> rayOperator "Watches/manages Ray job and cluster CRDs" "CRD Watch"
        kueue -> jobSetController "Watches/manages JobSet CRDs" "CRD Watch"
        kueue -> codeflare "Watches/manages AppWrapper CRDs" "CRD Watch"
        rhoaiOperator -> kueue "Deploys and configures Kueue" "Kustomize manifests"
        prometheus -> kueue "Scrapes metrics" "HTTPS/8443 Bearer Token"
        certManager -> kueue "Provides TLS certificates (optional)" "Certificate CRD"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests" "CRD/6443"
        kueue -> remoteCluster "Federates workloads (MultiKueue)" "HTTPS/6443 Kubeconfig"

        # K8s API webhook flow
        k8sAPI -> webhookServer "Webhook calls for admission" "HTTPS/9443 TLS"
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
                shape Person
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
