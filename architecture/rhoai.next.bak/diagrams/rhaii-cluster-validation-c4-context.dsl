workspace {
    model {
        platformEngineer = person "Platform Engineer" "Validates GPU cluster readiness before AI workload deployment"
        ciSystem = person "CI/CD System" "Runs automated cluster validation as a pre-deployment gate"

        rhaiiValidation = softwareSystem "RHAII Cluster Validation" "Preflight validation probe for xKS clusters that verifies GPU availability, RDMA connectivity, network bandwidth, required CRDs, and inference readiness" {
            cli = container "rhaii-validator CLI" "kubectl plugin and standalone CLI for orchestrating cluster validation" "Go (cobra)"
            controller = container "Controller" "Orchestrates validation lifecycle: namespace/RBAC setup, platform detection, GPU node discovery, Job deployment, result collection" "Go Package"
            jobrunner = container "Job Runner" "Manages multi-node test execution: server/client Job lifecycle, ring/star/pairwise topology scheduling" "Go Package"
            checks = container "Check Modules" "Individual validation checks: CRD, operator health, GPU driver/ECC, RDMA devices/topology, TCP bandwidth" "Go Package"
            config = container "Config" "Platform detection (AKS/EKS/CoreWeave/OCP) and embedded YAML configuration with per-platform thresholds" "Go Package"
            validatorImage = container "Validator Agent Image" "Same Go binary deployed as per-node agent inside privileged Job pods via hidden 'run' subcommand" "Container Image (Go)"
            toolsImage = container "Tools Image" "Provides RDMA bandwidth testing (ib_write_bw, ibv_rc_pingpong), TCP bandwidth (iperf3), CUDA runtime for GPUDirect" "Container Image (perftest + iperf3 + CUDA)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for node discovery, Job management, ConfigMap storage, RBAC, CRD queries" "External"
        nvidiaGPUOperator = softwareSystem "NVIDIA GPU Operator" "Provides GPU device plugin and driver management, exposes nvidia.com/gpu.present node labels" "External"
        amdGPUOperator = softwareSystem "AMD GPU Operator" "Provides AMD GPU device plugin, exposes amd.com/gpu.present node labels" "External"
        certManager = softwareSystem "cert-manager" "Certificate management operator (validated for presence)" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh (validated for presence in istio-system namespace)" "Internal RHOAI"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Operator" "LWS operator for multi-node workloads (validated for presence)" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs (validated for presence)" "Internal RHOAI"
        inferencePool = softwareSystem "InferencePool" "Inference pool CRDs (validated for presence)" "Internal RHOAI"

        platformEngineer -> rhaiiValidation "Runs cluster validation via kubectl plugin"
        ciSystem -> rhaiiValidation "Runs automated validation as pre-deployment gate"

        cli -> controller "Delegates validation orchestration"
        controller -> jobrunner "Delegates multi-node test scheduling"
        controller -> checks "Executes individual validation checks"
        controller -> config "Reads platform-specific configuration"
        jobrunner -> validatorImage "Deploys per-node check Jobs"
        jobrunner -> toolsImage "Deploys network/RDMA test Jobs"

        rhaiiValidation -> kubernetesAPI "Node listing, Job CRUD, ConfigMap CRUD, CRD queries" "HTTPS/443 TLS 1.2+"
        rhaiiValidation -> nvidiaGPUOperator "Discovers GPU nodes via node labels" "Kubernetes API"
        rhaiiValidation -> amdGPUOperator "Discovers AMD GPU nodes via node labels" "Kubernetes API"
        rhaiiValidation -> certManager "Validates operator health (pod listing)" "Kubernetes API"
        rhaiiValidation -> istio "Validates service mesh health (pod listing)" "Kubernetes API"
        rhaiiValidation -> leaderWorkerSet "Validates LWS operator health (pod listing)" "Kubernetes API"
        rhaiiValidation -> gatewayAPI "Checks CRD presence" "Kubernetes API"
        rhaiiValidation -> inferencePool "Checks CRD presence" "Kubernetes API"
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
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
