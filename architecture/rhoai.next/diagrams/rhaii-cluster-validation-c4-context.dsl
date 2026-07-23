workspace {
    model {
        admin = person "Cluster Admin" "Validates GPU cluster readiness before deploying AI workloads"

        rhaiiValidation = softwareSystem "RHAII Cluster Validation" "kubectl plugin for validating GPU cluster readiness — checks GPU hardware, RDMA connectivity, and cross-node bandwidth" {
            validatorCLI = container "rhaii-validator CLI" "Orchestrates cluster validation: discovers GPU nodes, deploys check/bandwidth Jobs, collects results, generates reports" "Go 1.25 kubectl plugin"
            validatorTools = container "validator-tools" "Provides iperf3 and perftest (ib_write_bw, ibv_rc_pingpong) with CUDA GPUDirect RDMA support for bandwidth testing" "Container Image (C/CUDA binaries)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for Job orchestration, node discovery, and resource management" "External"
        gpuDriver = softwareSystem "NVIDIA/AMD GPU Driver" "GPU hardware interface (nvidia-smi, rocm-smi) for driver version, ECC, topology checks" "External"
        gpuPlugin = softwareSystem "GPU Device Plugin" "Exposes nvidia.com/gpu or amd.com/gpu extended resources on worker nodes" "External"
        rdmaPlugin = softwareSystem "RDMA Device Plugin" "Exposes RDMA resources (nvidia.com/roce, rdma/*) on worker nodes" "External"

        gatewayAPI = softwareSystem "Gateway API" "Gateway and HTTPRoute CRDs — validated as prerequisites" "Internal Platform"
        inferenceExt = softwareSystem "Inference Extension" "InferencePool CRDs — validated as prerequisites" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "LWS CRDs and operator — validated as prerequisites" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Certificate management operator — validated as prerequisite" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh — validated as prerequisite" "Internal Platform"

        admin -> rhaiiValidation "Runs kubectl rhaii-validate to check cluster readiness"
        rhaiiValidation -> k8sAPI "Creates Jobs, reads Nodes, manages ConfigMaps" "HTTPS/6443 TLS 1.2+ Bearer Token"
        rhaiiValidation -> gpuDriver "Queries GPU hardware via chroot /host" "nvidia-smi/rocm-smi (privileged)"
        rhaiiValidation -> gpuPlugin "Requests GPU resources for test Jobs" "Kubernetes extended resources"
        rhaiiValidation -> rdmaPlugin "Requests RDMA resources for bandwidth Jobs" "Kubernetes extended resources"

        rhaiiValidation -> gatewayAPI "Validates CRDs installed" "apiextensions.k8s.io GET"
        rhaiiValidation -> inferenceExt "Validates CRDs installed" "apiextensions.k8s.io GET"
        rhaiiValidation -> lws "Validates CRDs and operator health" "apiextensions.k8s.io GET + Pod list"
        rhaiiValidation -> certManager "Validates operator health" "Pod list in cert-manager ns"
        rhaiiValidation -> istio "Validates operator health" "Pod list in istio-system ns"
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
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
