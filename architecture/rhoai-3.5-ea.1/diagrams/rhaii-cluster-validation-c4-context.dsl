workspace {
    model {
        user = person "Platform Engineer / SRE" "Validates GPU cluster readiness before deploying AI workloads"

        rhaiiValidator = softwareSystem "RHAII Cluster Validation" "Preflight validation probe for GPU clusters — verifies GPU availability, RDMA connectivity, network bandwidth, CRDs, and operator health" {
            cli = container "rhaii-validator CLI" "kubectl plugin and standalone CLI that orchestrates validation" "Go Binary"
            controller = container "Controller" "Manages Job lifecycle, RBAC setup, platform detection, report aggregation" "Go (client-go)"
            runner = container "Runner" "Executes per-node GPU and RDMA checks inside Job pods" "Go"
            jobRunner = container "JobRunner" "Orchestrates multi-node server/client Job pairs for bandwidth and connectivity tests" "Go"
            platformConfig = container "Platform Config" "Embedded YAML configs with per-platform defaults for OCP, AKS, EKS, CoreWeave" "YAML"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for Job CRUD, RBAC, node discovery, ConfigMap storage" "External"
        nvidiaDriver = softwareSystem "NVIDIA GPU Driver" "GPU driver providing nvidia-smi for driver version and ECC checks" "External"
        amdDriver = softwareSystem "AMD ROCm Driver" "GPU driver providing rocm-smi / amd-smi for AMD GPU checks" "External"
        nvidiaToolkit = softwareSystem "NVIDIA Container Toolkit" "Device injection for GPU access in containers" "External"
        rdmaFabric = softwareSystem "InfiniBand / RoCE Fabric" "RDMA data plane for perftest bandwidth and pingmesh connectivity" "External"

        gatewayApi = softwareSystem "Gateway API CRDs" "Validated CRDs: gateways, httproutes" "Internal RHOAI"
        inferencePool = softwareSystem "InferencePool CRD" "Validated CRD: inferencepools" "Internal RHOAI"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Operator" "Validated CRD and operator health" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Validated CRD and operator health" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Validated operator health in istio-system" "Internal RHOAI"

        user -> rhaiiValidator "Runs kubectl rhaii-validate" "kubectl CLI"
        rhaiiValidator -> k8sApi "Creates Jobs, RBAC, ConfigMaps; lists nodes and CRDs" "HTTPS/6443, Bearer Token"
        rhaiiValidator -> nvidiaDriver "Queries nvidia-smi for driver version, ECC, GPU count" "Local exec"
        rhaiiValidator -> amdDriver "Queries rocm-smi for AMD GPU info" "Local exec"
        rhaiiValidator -> nvidiaToolkit "Uses for GPU device injection into containers" "Device mount"
        rhaiiValidator -> rdmaFabric "Runs ib_write_bw, ibv_rc_pingpong for RDMA tests" "RDMA verbs"
        rhaiiValidator -> gatewayApi "Validates CRD existence and version" "HTTPS/6443"
        rhaiiValidator -> inferencePool "Validates CRD existence" "HTTPS/6443"
        rhaiiValidator -> leaderWorkerSet "Validates CRD and operator pods" "HTTPS/6443"
        rhaiiValidator -> certManager "Validates CRD and operator pods" "HTTPS/6443"
        rhaiiValidator -> istio "Validates operator pods in istio-system" "HTTPS/6443"

        cli -> controller "Initiates validation"
        controller -> runner "Deploys per-node check Jobs"
        controller -> jobRunner "Deploys multi-node bandwidth Jobs"
        controller -> platformConfig "Loads platform defaults"
    }

    views {
        systemContext rhaiiValidator "SystemContext" {
            include *
            autoLayout
        }

        container rhaiiValidator "Containers" {
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
