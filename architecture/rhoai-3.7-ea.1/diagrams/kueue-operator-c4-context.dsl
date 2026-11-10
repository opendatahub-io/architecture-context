workspace {
    model {
        admin = person "Cluster Admin" "Installs operator via OLM and creates the Kueue CR"
        dataScientist = person "Data Scientist" "Submits batch and AI/ML jobs to LocalQueues"

        kueueOperator = softwareSystem "Red Hat build of Kueue Operator" "Installs and lifecycle-manages the upstream Kueue job-queueing controller on OpenShift" {
            operator = container "openshift-kueue-operator" "Reconciles the singleton Kueue CR into operand resources (library-go TargetConfigReconciler)" "Go Operator, 2 replicas"
            controllerManager = container "kueue-controller-manager" "Quota-based admission, fair sharing, preemption, gang scheduling; serves admission webhooks 9443 and metrics 8443" "Go (upstream Kueue), 2 replicas"
            mustGather = container "kueue-must-gather" "Collects Kueue diagnostics via oc adm must-gather" "Bash image"
            bundle = container "kueue-operator-bundle" "CSV, Kueue CRD, batch admin/user ClusterRoles" "OLM bundle"
        }

        kubeApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        certManager = softwareSystem "cert-manager" "Issues webhook and metrics serving certs, injects CA (hard dependency)" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        monitoring = softwareSystem "OpenShift Monitoring" "prometheus-k8s scrapes operand metrics" "External"
        clusterAutoscaler = softwareSystem "Cluster Autoscaler" "ProvisioningRequest admission checks (optional)" "External"
        multiKueue = softwareSystem "MultiKueue Remote Clusters" "Remote worker clusters (optional)" "External"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform Kueue integration; consumes kueue.x-k8s.io APIs" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "PyTorchJob/TFJob/XGBoostJob/PaddleJob/MPIJob" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "RayJob/RayCluster" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "AppWrapper" "Internal RHOAI"
        jobsetLws = softwareSystem "JobSet / LeaderWorkerSet" "Multi-pod job APIs" "Internal RHOAI"

        admin -> olm "Installs operator subscription"
        olm -> bundle "Unpacks"
        admin -> kubeApi "Creates Kueue CR 'cluster'" "HTTPS/6443"
        dataScientist -> kubeApi "Creates jobs with kueue.x-k8s.io/queue-name" "HTTPS/6443"

        operator -> kubeApi "Watches Kueue CR, applies operand resources" "HTTPS/6443, SA token"
        operator -> certManager "Creates Issuer and Certificates (requires cert-manager.io/v1)" "CRD via API"
        operator -> controllerManager "Deploys and configures"
        controllerManager -> kubeApi "Creates Workloads, unsuspends admitted jobs" "HTTPS/6443, SA token"
        kubeApi -> controllerManager "Admission webhook callouts" "HTTPS/443->9443, TLS"
        monitoring -> controllerManager "Scrapes /metrics" "HTTPS/8443, Bearer + client cert"
        controllerManager -> clusterAutoscaler "Creates ProvisioningRequests" "CRD via API"
        controllerManager -> multiKueue "Dispatches workloads" "HTTPS/6443, kubeconfig"
        certManager -> kubeApi "Writes TLS Secrets, injects CA" "HTTPS/6443"

        controllerManager -> trainingOperator "Gates job start on quota admission" "Webhook + CRD patch"
        controllerManager -> kuberay "Gates RayJob/RayCluster" "Webhook + CRD patch"
        controllerManager -> codeflare "Gates AppWrappers" "Webhook + CRD patch"
        controllerManager -> jobsetLws "Gates JobSets / LWS" "Webhook + CRD patch"
        rhodsOperator -> kueueOperator "Depends on Kueue APIs installed by this operator" "CRD consumer"
    }

    views {
        systemContext kueueOperator "SystemContext" {
            include *
            autoLayout
        }

        container kueueOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
