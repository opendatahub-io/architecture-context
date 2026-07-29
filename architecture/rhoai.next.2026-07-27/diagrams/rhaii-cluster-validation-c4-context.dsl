workspace {
    model {
        operator = person "Cluster Operator/Admin" "Runs cluster validation before deploying AI/ML workloads"

        rhaiiValidation = softwareSystem "rhaii-cluster-validation" "CLI tool that validates GPU cluster readiness for AI/ML workloads on RHOAI" {
            cli = container "kubectl-rhaii_validate" "Cobra CLI controller that orchestrates validation" "Go CLI"
            runCmd = container "run subcommand" "Per-node check execution (GPU, TCP, RDMA)" "Go CLI (in-container)"
            depsCmd = container "deps subcommand" "Validates prerequisite CRDs and operators" "Go CLI"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane API server" "External"
        gpuNodes = softwareSystem "GPU Worker Nodes" "Cluster nodes with NVIDIA/AMD GPUs and RDMA hardware" "External"

        # Validated prerequisites (checked by deps subcommand)
        gatewayApi = softwareSystem "Gateway API CRDs" "Gateway API custom resources" "Prerequisite"
        inferencePool = softwareSystem "InferencePool CRD" "Inference pool custom resource" "Prerequisite"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Operator" "Leader-worker set management" "Prerequisite"
        certManager = softwareSystem "cert-manager Operator" "Certificate management" "Prerequisite"
        istio = softwareSystem "Istio Operator" "Service mesh" "Prerequisite"

        # Platforms
        ocp = softwareSystem "OpenShift Container Platform" "Auto-detected platform" "Platform"
        eks = softwareSystem "Amazon EKS" "Auto-detected platform" "Platform"
        aks = softwareSystem "Azure AKS" "Auto-detected platform" "Platform"
        coreweave = softwareSystem "CoreWeave" "Auto-detected platform" "Platform"

        operator -> rhaiiValidation "Runs validation via kubectl plugin"
        rhaiiValidation -> k8sApi "Creates ephemeral resources, deploys Jobs, reads results" "HTTPS/6443, TLS 1.2+"
        rhaiiValidation -> gpuNodes "Deploys per-node Job pods for hardware validation"

        cli -> runCmd "Deploys as Job pod on each GPU node"
        cli -> depsCmd "Validates prerequisites before checks"

        depsCmd -> gatewayApi "Checks CRD exists"
        depsCmd -> inferencePool "Checks CRD exists"
        depsCmd -> leaderWorkerSet "Checks operator healthy"
        depsCmd -> certManager "Checks operator healthy"
        depsCmd -> istio "Checks operator healthy"

        cli -> ocp "Auto-detects and loads OCP config"
        cli -> eks "Auto-detects and loads EKS config"
        cli -> aks "Auto-detects and loads AKS config"
        cli -> coreweave "Auto-detects and loads CoreWeave config"
    }

    views {
        systemContext rhaiiValidation "SystemContext" {
            include *
            autoLayout
        }

        container rhaiiValidation "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Prerequisite" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
