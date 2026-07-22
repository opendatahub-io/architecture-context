workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Validates GPU/RDMA cluster readiness before AI workload deployment"

        rhaiiValidation = softwareSystem "RHAII Cluster Validation" "Preflight validation tool for GPU/RDMA-capable Kubernetes clusters" {
            controller = container "Validator Controller" "Orchestrates validation pipeline: platform detection, CRD checks, GPU/RDMA topology discovery, bandwidth/connectivity tests" "Go CLI (kubectl plugin)"
            gpuCheckAgent = container "GPU Check Agent" "Per-node hardware validation: GPU driver, ECC, RDMA NIC status, PCIe/NUMA topology" "Go binary in privileged container"
            validatorTools = container "Validator Tools" "RDMA bandwidth and connectivity testing: iperf3, ib_write_bw, ibv_rc_pingpong with CUDA support" "C/bash in privileged container"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for Job scheduling, RBAC, ConfigMap storage" "External"
        nvidiaDriver = softwareSystem "NVIDIA GPU Driver" "GPU hardware abstraction (nvidia-smi)" "External"
        amdDriver = softwareSystem "AMD ROCm Driver" "GPU hardware abstraction (rocm-smi, amd-smi)" "External"
        rdmaSubsystem = softwareSystem "RDMA Subsystem" "InfiniBand/RoCE hardware (ibstat, ibv_devices, rdma-core)" "External"
        containerRegistry = softwareSystem "Container Registry" "Image storage (quay.io, registry.redhat.io)" "External"

        gatewayAPICRDs = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs (gateways, httproutes)" "Internal RHOAI"
        inferencePool = softwareSystem "InferencePool CRD" "Gateway API Inference Extension" "Internal RHOAI"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Operator" "Distributed training operator (LWS)" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate management operator" "Internal RHOAI"
        istio = softwareSystem "Istio Control Plane" "Service mesh (istio-system)" "Internal RHOAI"

        clusterAdmin -> rhaiiValidation "Runs kubectl rhaii-validate"
        controller -> k8sAPI "Job CRUD, Node list, ConfigMap, RBAC" "HTTPS/6443, kubeconfig"
        controller -> gpuCheckAgent "Creates per-node check Jobs" "K8s Job scheduling"
        controller -> validatorTools "Creates bandwidth/connectivity Jobs" "K8s Job scheduling"
        gpuCheckAgent -> nvidiaDriver "Queries GPU status" "CLI exec (nvidia-smi)"
        gpuCheckAgent -> amdDriver "Queries GPU status" "CLI exec (rocm-smi)"
        gpuCheckAgent -> rdmaSubsystem "Queries RDMA topology" "CLI exec (ibstat, ibv_devices), sysfs"
        validatorTools -> rdmaSubsystem "RDMA bandwidth/connectivity tests" "RDMA verbs (ib_write_bw, ibv_rc_pingpong)"
        k8sAPI -> containerRegistry "Pulls validator and tools images" "HTTPS/443"

        controller -> gatewayAPICRDs "Validates CRD presence" "HTTPS/6443"
        controller -> inferencePool "Validates CRD presence" "HTTPS/6443"
        controller -> leaderWorkerSet "Validates CRD + pod health" "HTTPS/6443"
        controller -> certManager "Validates CRD + pod health" "HTTPS/6443"
        controller -> istio "Validates pod health" "HTTPS/6443"
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
            element "Person" {
                shape Person
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
