workspace {
    model {
        admin = person "Cluster Admin" "Validates GPU cluster readiness before deploying AI inference workloads"

        rhaiiValidation = softwareSystem "RHAII Cluster Validation" "kubectl plugin for validating GPU cluster readiness (hardware, RDMA, bandwidth)" {
            validator = container "rhaii-validator" "Orchestrates cluster validation: discovers GPU nodes, deploys Jobs, collects results" "Go CLI (kubectl plugin)"
            validatorTools = container "validator-tools" "Provides iperf3 and perftest with CUDA GPUDirect RDMA support for bandwidth testing" "Container Image (C/CUDA)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        gpuDriver = softwareSystem "NVIDIA/AMD GPU Driver" "GPU hardware driver providing nvidia-smi/rocm-smi" "External"
        gpuPlugin = softwareSystem "GPU Device Plugin" "Exposes nvidia.com/gpu or amd.com/gpu extended resources" "Internal Platform"
        rdmaPlugin = softwareSystem "RDMA Device Plugin" "Exposes RDMA resources (nvidia.com/roce, rdma/*) on nodes" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "CRDs validated as prerequisites (gateways, httproutes)" "Internal Platform"
        inferencePool = softwareSystem "Inference Pool CRD" "Gateway API Inference Extension CRD (inferencepools)" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "CRD and operator for distributed workloads" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Certificate management operator" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh operator" "Internal Platform"
        scc = softwareSystem "OpenShift SCC" "Security Context Constraints for privileged access" "Internal Platform"

        admin -> rhaiiValidation "Runs validation via kubectl rhaii-validate"
        validator -> k8sAPI "Job CRUD, Node list, ConfigMap, RBAC, Pod logs" "HTTPS/6443"
        validator -> validatorTools "Deploys as bandwidth test containers in Jobs"
        validatorTools -> gpuDriver "GPU hardware access via chroot /host" "sysfs"
        validatorTools -> validatorTools "iperf3 TCP bandwidth, ib_write_bw RDMA, ibv_rc_pingpong" "TCP/5201, RDMA/18515+"
        validator -> gatewayAPI "Validates CRD existence" "HTTPS/6443"
        validator -> inferencePool "Validates CRD existence" "HTTPS/6443"
        validator -> lws "Validates CRD and operator health" "HTTPS/6443"
        validator -> certManager "Validates operator pods" "HTTPS/6443"
        validator -> istio "Validates operator pods" "HTTPS/6443"
        gpuPlugin -> k8sAPI "Advertises GPU extended resources"
        rdmaPlugin -> k8sAPI "Advertises RDMA extended resources"
        validator -> scc "Binds privileged SCC on OpenShift" "HTTPS/6443"
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
            element "Internal Platform" {
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
