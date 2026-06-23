workspace {
    model {
        user = person "Data Scientist / SRE" "Validates GPU cluster readiness before deploying AI/ML workloads"

        rhaiiValidation = softwareSystem "RHAII Cluster Validation" "Preflight validation tool for GPU clusters - verifies GPU hardware, RDMA networking, and cross-node bandwidth readiness" {
            cli = container "CLI Entry Point" "kubectl plugin providing rhaii-validate command with subcommands (all, gpu, rdma, deps, net)" "Go CLI (kubectl plugin)"
            controller = container "Controller" "Orchestrates per-node Jobs, multi-node network tests, and RDMA checks; collects and aggregates results" "Go"
            agent = container "Per-Node Agent" "Executes hardware checks via chroot /host: GPU driver validation, ECC errors, PCIe topology, RDMA device enumeration" "Go (same binary, 'run' subcommand)"
            tcpLatServer = container "TCP Latency Server" "Echo server for round-trip latency measurement between nodes" "Go (embedded in validator binary)" "12865/TCP"
            toolsImage = container "Validator Tools Image" "Pre-compiled network/RDMA testing tools with CUDA GPUDirect support" "C + iperf3 + perftest (CUDA)" "5201/TCP, 18515/TCP"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing Job scheduling, node discovery, and ConfigMap storage" "External"
        nvidiaGPUOperator = softwareSystem "NVIDIA GPU Operator" "Provides nvidia.com/gpu device plugin and node labels for GPU node discovery" "External"
        amdGPUOperator = softwareSystem "AMD GPU Operator" "Provides amd.com/gpu device plugin and node labels for GPU node discovery" "External"
        nvidiaContainerToolkit = softwareSystem "NVIDIA Container Toolkit" "Container runtime hook that injects nvidia-smi and GPU libraries into containers" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs (gateways, httproutes)" "External"
        inferencePool = softwareSystem "InferencePool" "Gateway API Inference Extension CRD" "External"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Operator for managing distributed workloads (CRD + operator)" "External"
        certManager = softwareSystem "cert-manager" "Certificate management operator (CRD + operator)" "External"
        istio = softwareSystem "Istio" "Service mesh - checked for operator health" "External"
        hostOS = softwareSystem "Host Operating System" "Host filesystem accessed via chroot /host for GPU drivers, PCIe topology, RDMA devices" "External"

        # User interactions
        user -> rhaiiValidation "Runs kubectl rhaii-validate to check cluster readiness"

        # Internal flows
        cli -> controller "Parses flags, invokes validation pipeline"
        controller -> agent "Deploys as per-node privileged Job pods via 'run' subcommand"
        controller -> toolsImage "Deploys as multi-node Job pods for network/RDMA tests"
        controller -> tcpLatServer "Deploys as Job pod for TCP latency measurement"

        # External dependencies
        rhaiiValidation -> kubernetes "Job/Pod/ConfigMap CRUD, node discovery, CRD listing" "HTTPS/6443"
        agent -> hostOS "GPU driver queries, PCIe topology, RDMA device enumeration" "chroot /host (privileged)"
        rhaiiValidation -> nvidiaGPUOperator "Discovers GPU nodes via nvidia.com/gpu.present labels" "Node labels"
        rhaiiValidation -> amdGPUOperator "Discovers GPU nodes via amd.com/gpu.present labels" "Node labels"
        rhaiiValidation -> nvidiaContainerToolkit "Injects GPU libraries into Job containers" "Container runtime hook"

        # Dependency checks (Tier 1)
        rhaiiValidation -> gatewayAPI "Validates CRDs are installed" "HTTPS/6443"
        rhaiiValidation -> inferencePool "Validates CRD is installed" "HTTPS/6443"
        rhaiiValidation -> leaderWorkerSet "Validates CRD installed and operator healthy" "HTTPS/6443"
        rhaiiValidation -> certManager "Validates CRD installed and operator healthy" "HTTPS/6443"
        rhaiiValidation -> istio "Validates operator pods are running" "HTTPS/6443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
