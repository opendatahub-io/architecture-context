workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Validates GPU cluster readiness before deploying AI/ML inference workloads"

        rhaiiValidation = softwareSystem "RHAII Cluster Validation" "kubectl plugin for preflight validation of GPU cluster readiness for AI/ML inference workloads" {
            cli = container "rhaii-validator CLI" "Orchestrates cluster validation by deploying Jobs, collecting results, and generating reports" "Go kubectl plugin"
            validatorImage = container "odh-rhaii-cluster-validator" "Per-node GPU and RDMA hardware checks via nvidia-smi, ibstat, sysfs" "Container Image (UBI9)"
            toolsImage = container "odh-rhaii-validator-tools" "Network and RDMA bandwidth testing (iperf3, perftest/ib_write_bw) with CUDA GPUDirect support" "Container Image (UBI9 + CUDA)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for node discovery, Job management, ConfigMap storage" "External"
        nvidiaDriver = softwareSystem "NVIDIA GPU Driver" "GPU hardware interface providing nvidia-smi for driver version, ECC, and GPU enumeration" "External"
        amdDriver = softwareSystem "AMD GPU Driver" "GPU hardware interface providing rocm-smi for AMD GPU checks" "External"
        infinibandNICs = softwareSystem "InfiniBand/RoCE NICs" "RDMA network interfaces for kernel-bypass bandwidth testing" "External"

        certManager = softwareSystem "cert-manager" "Certificate management operator" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management" "Internal RHOAI"
        lws = softwareSystem "LeaderWorkerSet Operator" "Manages leader-worker set deployments for distributed workloads" "Internal RHOAI"

        gatewayAPICRDs = softwareSystem "Gateway API CRDs" "Kubernetes Gateway API custom resource definitions" "External"
        inferencePoolCRD = softwareSystem "InferencePool CRD" "Custom resource definition for inference pool configuration" "External"

        clusterAdmin -> rhaiiValidation "Runs preflight validation via kubectl rhaii-validate"
        cli -> k8sAPI "Node listing, Job CRUD, ConfigMap CRUD, CRD discovery, pod log streaming" "HTTPS/443"
        cli -> validatorImage "Creates ephemeral Jobs on each GPU node" "Kubernetes Job API"
        cli -> toolsImage "Creates bandwidth/RDMA test Jobs" "Kubernetes Job API"

        validatorImage -> nvidiaDriver "Checks GPU health via nvidia-smi" "chroot /host exec"
        validatorImage -> amdDriver "Checks AMD GPU health via rocm-smi" "chroot /host exec"
        validatorImage -> infinibandNICs "Discovers RDMA devices via ibstat/ibv_devices" "sysfs read"

        toolsImage -> infinibandNICs "RDMA bandwidth testing (ib_write_bw, ibv_rc_pingpong)" "RDMA kernel bypass"
        toolsImage -> toolsImage "Cross-node TCP bandwidth (iperf3) and latency" "TCP/5201, TCP/12865"

        cli -> certManager "Validates operator health (pod readiness)" "HTTPS/443 via K8s API"
        cli -> istio "Validates operator health (pod readiness)" "HTTPS/443 via K8s API"
        cli -> lws "Validates operator health (pod readiness)" "HTTPS/443 via K8s API"
        cli -> gatewayAPICRDs "Validates CRD existence and version" "HTTPS/443 via K8s API"
        cli -> inferencePoolCRD "Validates CRD existence with fallback API group" "HTTPS/443 via K8s API"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
