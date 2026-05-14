workspace {
    model {
        user = person "Data Scientist" "Creates ML training jobs and inference workloads requiring resource quotas and fair scheduling"
        admin = person "Cluster Admin" "Configures ClusterQueues, ResourceFlavors, quotas, and cohorts"

        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system managing admission, scheduling, quotas, priorities, and fair sharing" {
            controllerManager = container "Kueue Controller Manager" "controller-runtime based operator managing job queueing, admission, scheduling, preemption, and workload lifecycle" "Go Operator" {
                coreControllers = component "Core Controllers" "ClusterQueue, LocalQueue, Workload, ResourceFlavor, AdmissionCheck, Cohort reconcilers" "Go"
                scheduler = component "Scheduler" "Continuous scheduling loop evaluating pending workloads against quotas, priorities, fair sharing, and flavor assignment" "Go (manager.Runnable)"
                webhookServer = component "Webhook Server" "17 mutating + 18 validating + 1 conversion webhook for all managed job types" "Go"
                provisioningCtrl = component "Provisioning Controller" "Creates ProvisioningRequests for cluster autoscaler integration" "Go"
                multiKueueCtrl = component "MultiKueue Controllers" "Clusters, Workload, and AdmissionCheck reconcilers for multi-cluster federation (disabled in RHOAI)" "Go"
                tasControllers = component "TAS Controllers" "Topology, Ungater, and ResourceFlavor controllers for topology-aware scheduling" "Go"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API serving CRD operations, webhook calls, and watch streams" "External"
        certManager = softwareSystem "cert-manager" "Optional external certificate lifecycle management" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "Provisions nodes via ProvisioningRequest CRDs (optional, feature-gated)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting via ServiceMonitor and PrometheusRule" "Monitoring"

        trainingOperator = softwareSystem "Training Operator (Kubeflow)" "Manages PyTorchJob, TFJob, PaddleJob, XGBoostJob, MPIJob CRDs" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator (KubeRay)" "Manages RayJob and RayCluster CRDs" "Internal RHOAI"
        jobSetController = softwareSystem "JobSet Controller" "Manages JobSet CRDs for multi-job coordination" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages AppWrapper CRDs for batch workloads" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator deploying Kueue via kustomize manifests" "Internal RHOAI"

        remoteCluster = softwareSystem "Remote Kubernetes Cluster" "Worker cluster for MultiKueue federation (disabled in RHOAI)" "External"

        # Relationships
        user -> kueue "Submits Jobs, PyTorchJobs, RayJobs, JobSets via kubectl/kueuectl"
        admin -> kueue "Configures ClusterQueues, ResourceFlavors, LocalQueues, Cohorts"
        rhoaiOperator -> kueue "Deploys and configures via kustomize manifests"

        kueue -> k8sAPI "Watches CRDs, creates/updates Workloads, suspends/resumes Jobs" "HTTPS/6443"
        k8sAPI -> kueue "Webhook calls for mutating/validating admission" "HTTPS/443→9443"
        kueue -> clusterAutoscaler "Creates ProvisioningRequest CRDs" "HTTPS/6443 (indirect via API)"
        kueue -> remoteCluster "Federates workloads to remote clusters (disabled)" "HTTPS/6443"
        prometheus -> kueue "Scrapes metrics" "HTTPS/8443"

        kueue -> trainingOperator "Watches and manages Kubeflow training job CRDs" "via k8s API"
        kueue -> rayOperator "Watches and manages RayJob/RayCluster CRDs" "via k8s API"
        kueue -> jobSetController "Watches and manages JobSet CRDs" "via k8s API"
        kueue -> codeflareOperator "Watches and manages AppWrapper CRDs" "via k8s API"
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

        component controllerManager "Components" {
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
            element "Monitoring" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
        }
    }
}
